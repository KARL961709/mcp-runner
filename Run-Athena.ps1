<#
.SYNOPSIS
  Corre todos los .sql de una carpeta contra Athena y deja los resultados
  organizados, en una sola invocacion.

.DESCRIPTION
  Por cada .sql: lanza la query, espera a que termine, baja el CSV completo y
  registra el resultado. Existe porque el ciclo manual (start-query-execution ->
  anotar el QueryExecutionId -> consultar estado -> bajar) cuesta varios pasos
  por query, y aqui el transporte de vuelta es una persona copiando y pegando.

  El diseno minimiza viajes humanos: valida todo antes de empezar, no corta el
  lote cuando una query falla, y escribe un resumen compacto pensado para
  pegarse en un chat sin sacar datos del entorno.

.EXAMPLE
  .\Run-Athena.ps1
  .\Run-Athena.ps1 -Only CHECK_riesgo_grupos
  .\Run-Athena.ps1 -SqlDir .\sql -OutDir .\output -TimeoutSec 1800
#>
# PositionalBinding=$false: ver la nota en Go.ps1. Todos los parametros van
# siempre por nombre; un argumento suelto es un error, no un -SqlDir accidental.
[CmdletBinding(PositionalBinding = $false)]
param(
  [string]   $SqlDir,
  [string]   $OutDir,
  [string]   $AwsProfile,
  [string]   $WorkGroup,
  [string]   $Database,
  [int]      $TimeoutSec = 900,
  [string[]] $Only = @(),
  [switch]   $Clip
)

$ErrorActionPreference = "Stop"

# --- Configuracion -----------------------------------------------------------
# Los valores del entorno viven en config.ps1, que NO se versiona (lleva nombres
# de workgroup y base). Un parametro explicito siempre gana sobre el archivo.
$provided = @{}
foreach ($k in $PSBoundParameters.Keys) { $provided[$k] = $PSBoundParameters[$k] }

$cfgPath = Join-Path $PSScriptRoot "config.ps1"
if (Test-Path $cfgPath) { . $cfgPath }

foreach ($k in $provided.Keys) { Set-Variable -Name $k -Value $provided[$k] }

if (-not $SqlDir) { $SqlDir = Join-Path $PSScriptRoot "sql" }
if (-not $OutDir) { $OutDir = Join-Path $PSScriptRoot "output" }

# --- Validacion temprana -----------------------------------------------------
# Todo lo que pueda fallar, que falle AQUI con un mensaje accionable: un error a
# mitad del lote cuesta un viaje humano completo.
function Abortar($mensaje, $comoArreglar) {
  Write-Host ""
  Write-Host "ABORTADO: $mensaje" -ForegroundColor Red
  if ($comoArreglar) { Write-Host "  -> $comoArreglar" -ForegroundColor Yellow }
  exit 2
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  Abortar "No encuentro el AWS CLI en el PATH." "Instala AWS CLI v2, o abre una terminal nueva si acabas de instalarlo."
}
foreach ($par in @(@("AwsProfile", $AwsProfile), @("WorkGroup", $WorkGroup), @("Database", $Database))) {
  if (-not $par[1]) {
    Abortar "Falta el parametro -$($par[0])." "Definelo en config.ps1 (copia config.ejemplo.ps1) o pasalo por linea de comandos."
  }
}
if (-not (Test-Path $SqlDir)) {
  Abortar "No existe la carpeta de queries: $SqlDir" "Creala y pon ahi tus .sql, o indica otra con -SqlDir."
}

$archivos = @(Get-ChildItem -Path $SqlDir -Filter "*.sql" -File | Sort-Object Name)
if ($Only.Count -gt 0) {
  $archivos = @($archivos | Where-Object { $Only -contains $_.BaseName })
}
if ($archivos.Count -eq 0) {
  Abortar "No hay .sql que correr en $SqlDir" "Revisa el filtro -Only, o que los archivos terminen en .sql"
}

# La sesion SSO se verifica ANTES de lanzar nada: es el fallo mas comun y el
# mas barato de detectar.
aws sts get-caller-identity --profile $AwsProfile --output text | Out-Null
if ($LASTEXITCODE -ne 0) {
  Abortar "La sesion SSO del perfil '$AwsProfile' no es valida o expiro." "Corre:  aws sso login --profile $AwsProfile"
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

Write-Host ""
Write-Host "Queries : $($archivos.Count)   Perfil: $AwsProfile   Base: $Database"
Write-Host "Salida  : $OutDir"
Write-Host ""

# --- Ejecucion ---------------------------------------------------------------
$manifiesto = @()

foreach ($archivo in $archivos) {
  $nombre = $archivo.BaseName
  Write-Host ("  {0,-40} " -f $nombre) -NoNewline

  $reloj = [Diagnostics.Stopwatch]::StartNew()
  $estado = "?"; $motivo = $null; $qid = $null; $lineas = $null; $csv = $null

  try {
    # Athena rechaza el BOM: llega como 'ï' y da MALFORMED_QUERY en la columna 1.
    # Lo escriben Notepad y Set-Content -Encoding utf8 (PS 5.1) sin avisar, asi
    # que normalizamos siempre a UTF-8 sin BOM en un temporal, en vez de confiar
    # en como se guardo el .sql original.
    # ReadAllText ya detecta y quita el BOM; el replace es cinturon y tirantes
    # por si el archivo llega con doble BOM o codificado de forma rara.
    $sql = [System.IO.File]::ReadAllText($archivo.FullName)
    $sql = $sql -replace "^﻿", ""
    if (-not $sql.Trim()) { throw "El archivo .sql esta vacio" }

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("athena_" + $nombre + ".sql")
    [System.IO.File]::WriteAllText($tmp, $sql, (New-Object System.Text.UTF8Encoding($false)))

    # file:// con barras normales: evita el infierno de comillas y espacios al
    # pasar SQL multilinea como argumento (las rutas de OneDrive los tienen).
    $uri = "file://" + ($tmp -replace '\\', '/')

    $raw = aws athena start-query-execution `
      --profile $AwsProfile `
      --work-group $WorkGroup `
      --query-execution-context "Database=$Database" `
      --query-string $uri `
      --output json

    if ($LASTEXITCODE -ne 0) { throw "start-query-execution fallo (exit $LASTEXITCODE)" }
    $qid = ($raw | ConvertFrom-Json).QueryExecutionId

    # Polling hasta estado terminal o timeout.
    $exec = $null
    while ($reloj.Elapsed.TotalSeconds -lt $TimeoutSec) {
      Start-Sleep -Seconds 3
      $rawExec = aws athena get-query-execution --profile $AwsProfile --query-execution-id $qid --output json
      if ($LASTEXITCODE -ne 0) { throw "get-query-execution fallo (exit $LASTEXITCODE)" }
      $exec = ($rawExec | ConvertFrom-Json).QueryExecution
      $estado = $exec.Status.State
      if (@("SUCCEEDED", "FAILED", "CANCELLED") -contains $estado) { break }
    }
    if (@("SUCCEEDED", "FAILED", "CANCELLED") -notcontains $estado) {
      $estado = "TIMEOUT"
      throw "La query sigue corriendo tras $TimeoutSec s (QID $qid)"
    }
    if ($estado -ne "SUCCEEDED") {
      $motivo = $exec.Status.StateChangeReason
      throw "Athena devolvio $estado"
    }

    # DDL/DML (CREATE TABLE AS, DROP, INSERT INTO, ALTER) no devuelve filas. Para un
    # CTAS, OutputLocation apunta a `tables/<uuid>`, que es el PREFIJO con los datos de
    # la tabla, no un CSV: el `aws s3 cp` responde 404 HeadObject aunque la query haya
    # ido perfecta. Visto en PO_1_flags_rcc: SUCCEEDED en 232s y 404 al descargar.
    # Se detecta por la primera palabra del SQL, ignorando comentarios y lineas vacias.
    $primeraLinea = ($sql -split "`n" |
                     Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("--") } |
                     Select-Object -First 1)
    $esDDL = $primeraLinea -match '^\s*(CREATE|DROP|ALTER|INSERT|MSCK)\b'

    if ($esDDL) {
      $csv = $null
      $lineas = 0
    }
    else {
      # Descarga del CSV completo desde el OutputLocation del workgroup.
      $origen = $exec.ResultConfiguration.OutputLocation
      $csv = Join-Path $OutDir "$nombre.csv"
      aws s3 cp $origen $csv --profile $AwsProfile --only-show-errors
      if ($LASTEXITCODE -ne 0) { throw "No pude bajar el resultado desde $origen (exit $LASTEXITCODE)" }

      # Conteo por streaming: no carga el archivo entero en memoria.
      # Es conteo de LINEAS: si algun campo trae saltos de linea, sobreestima.
      $n = 0
      foreach ($l in [System.IO.File]::ReadLines($csv)) { $n++ }
      $lineas = [Math]::Max(0, $n - 1)
    }
  }
  catch {
    if (-not $motivo) { $motivo = $_.Exception.Message }
    if ($estado -eq "?") { $estado = "ERROR" }
  }

  $reloj.Stop()
  $seg = [Math]::Round($reloj.Elapsed.TotalSeconds, 1)

  $manifiesto += [PSCustomObject]@{
    query    = $nombre
    estado   = $estado
    filas    = $lineas
    segundos = $seg
    qid      = $qid
    motivo   = $motivo
    csv      = if ($csv -and (Test-Path $csv)) { Split-Path $csv -Leaf } else { $null }
  }

  if ($estado -eq "SUCCEEDED") {
    Write-Host ("OK    {0,9} filas  {1,6}s" -f $lineas, $seg) -ForegroundColor Green
  } else {
    Write-Host ("{0,-6}              {1,6}s" -f $estado, $seg) -ForegroundColor Red
  }
}

# --- Canal de vuelta ---------------------------------------------------------
# _resumen.txt es lo unico pensado para salir de esta maquina: estado, volumen y
# errores. Nada del contenido de los resultados. De vuelta viaja el diagnostico,
# no el dato. ASCII puro para que sobreviva cualquier copy-paste.
$ok = @($manifiesto | Where-Object { $_.estado -eq "SUCCEEDED" }).Count
$ancho = ($manifiesto | ForEach-Object { $_.query.Length } | Measure-Object -Maximum).Maximum

$lineasRes = @()
$lineasRes += "LOTE ATHENA   $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$lineasRes += "$ok/$($manifiesto.Count) ok   base=$Database"
$lineasRes += ""
foreach ($m in $manifiesto) {
  if ($m.estado -eq "SUCCEEDED") {
    $lineasRes += ("{0}  ok      {1,9} filas  {2,6}s" -f $m.query.PadRight($ancho), $m.filas, $m.segundos)
  } else {
    $lineasRes += ("{0}  {1,-9}                {2,6}s" -f $m.query.PadRight($ancho), $m.estado, $m.segundos)
    if ($m.motivo) {
      $corto = $m.motivo -replace '\s+', ' '
      if ($corto.Length -gt 300) { $corto = $corto.Substring(0, 300) + "..." }
      $lineasRes += "    > $corto"
    }
  }
}
$lineasRes += ""
$lineasRes += "(los CSV quedaron en $OutDir - no se incluyen aqui a proposito)"

$resumen = ($lineasRes -join "`r`n") + "`r`n"
Set-Content -Path (Join-Path $OutDir "_resumen.txt") -Value $resumen -Encoding ascii
$manifiesto | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutDir "_manifest.json") -Encoding utf8

Write-Host ""
Write-Host $resumen

# -Clip deja el resumen listo para pegar en el chat: es el ultimo tramo del
# canal de vuelta y no tiene sentido que cueste un Get-Content mas.
if ($Clip) {
  try {
    Set-Clipboard -Value $resumen
    Write-Host "Resumen copiado al portapapeles - pegalo en el chat con Ctrl+V" -ForegroundColor Cyan
  } catch {
    Write-Host "(no pude usar el portapapeles: $($_.Exception.Message))" -ForegroundColor Yellow
  }
}

if ($ok -lt $manifiesto.Count) { exit 1 }
exit 0
