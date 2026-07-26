<#
.SYNOPSIS
  Un solo comando: trae lo ultimo del repo y corre el lote.

.DESCRIPTION
  Es el flujo completo del lado de ejecucion:
    git pull  ->  Run-Athena.ps1  ->  resumen al portapapeles

  Acepta los mismos parametros que Run-Athena.ps1 y los reenvia por nombre.

.EXAMPLE
  .\Go.ps1
  .\Go.ps1 -Only CHECK_riesgo_grupos
  .\Go.ps1 -Database disc_riesgos -TimeoutSec 1800
#>
# PositionalBinding=$false: un argumento suelto (p.ej. escribir ".\Go ps1" con
# espacio en vez de punto) se bindeaba silenciosamente a -SqlDir y abortaba con
# un mensaje que no senalaba la causa real. Asi falla diciendo que el parametro
# no existe.
[CmdletBinding(PositionalBinding = $false)]
param(
  [string]   $SqlDir,
  [string]   $OutDir,
  [string]   $AwsProfile,
  [string]   $WorkGroup,
  [string]   $Database,
  [int]      $TimeoutSec,
  [string[]] $Only
)

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "[1/2] Actualizando desde el repo..." -ForegroundColor Cyan

# --ff-only: si el historial divergio prefiero fallar y avisar, antes que hacer
# un merge silencioso en la maquina de ejecucion.
git pull --ff-only
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "El pull fallo. Causas tipicas:" -ForegroundColor Red
  Write-Host "  - Un .sql local con el mismo nombre que uno del repo:" -ForegroundColor Yellow
  Write-Host "      renombra el tuyo, o borralo si ya es el mismo, y reintenta" -ForegroundColor Yellow
  Write-Host "  - Commits locales que divergieron:" -ForegroundColor Yellow
  Write-Host "      git fetch origin; git reset --hard origin/master   (descarta cambios locales)" -ForegroundColor Yellow
  Write-Host "  - Sin red o sin credencial: revisa que 'git ls-remote origin' funcione" -ForegroundColor Yellow
  exit 2
}

Write-Host ""
Write-Host "[2/2] Corriendo el lote..." -ForegroundColor Cyan

# Reenvio por HASHTABLE, no por array: el splatting de arrays pasa los elementos
# como posicionales y "-Clip" terminaria bindeado a -SqlDir. Con hashtable el
# binding es por nombre y no hay ambiguedad.
$reenvio = @{}
foreach ($k in $PSBoundParameters.Keys) { $reenvio[$k] = $PSBoundParameters[$k] }
$reenvio["Clip"] = $true

& (Join-Path $PSScriptRoot "Run-Athena.ps1") @reenvio

# El codigo de salida se propaga tal cual: 0 todo ok, 1 alguna query fallo,
# 2 aborto antes de empezar.
exit $LASTEXITCODE
