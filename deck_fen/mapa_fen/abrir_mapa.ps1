# Sirve esta carpeta y abre el mapa FEN 2026 en el navegador.
# El mapa carga los puntos por distrito con fetch() -> NO funciona con doble clic directo; por eso se sirve local.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here
$port = 8799
Write-Host ("Sirviendo el mapa FEN en http://localhost:{0}" -f $port)
Write-Host "Se abrira el navegador. Deja esta ventana abierta; cierrala para detener el servidor."
Start-Process ("http://localhost:{0}/mapa_fen2026_cuencas.html" -f $port)
python -m http.server $port
