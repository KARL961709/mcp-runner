# Copia este archivo como  config.ps1  y pon tus valores.
# config.ps1 NO se versiona: lleva nombres de workgroup y base de datos.

$AwsProfile = "ibk"
$WorkGroup  = "<nombre-del-workgroup>"
$Database   = "<nombre-de-la-base>"

# Opcionales: por defecto .\sql y .\output junto al script.
# $SqlDir = "C:\ruta\a\mis\queries"
# $OutDir = "C:\ruta\a\resultados"

# Export de parquets (solo si usas -Bajar). El path S3 y la carpeta local NO se
# versionan: el .sql lleva el placeholder <S3_DATOS> y el runner lo sustituye.
# $S3Datos    = "s3://<bucket>/proyectos/bankbn/datos"
# $LocalDatos = "C:\ruta\local\del\banco\bankbn_datos"
