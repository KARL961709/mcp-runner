/* ¿En que base de datos y ruta de S3 debo crear la tabla 'disc_<placeholder>.ds_<placeholder>_mdl'?

| Base de Datos   | Ruta de S3                                                                    |
|-----------------|-------------------------------------------------------------------------------|
| disc_comercial  | s3://ibk-discovery-comercial-us-east-1-654654352211-data/discovery/comercial/ |
| disc_rtd        | s3://ibk-discovery-comercial-us-east-1-654654352211-data/discovery/rtd/       |
| disc_riesgos    | s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/riesgos/     |
| disc_validator  | s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/validator/   |
| disc_monitorian |	s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/monitorian/  |
| disc_ba         | s3://ibk-discovery-ba-us-east-1-992382582498-data/discovery/ba/               |
| disc_pa         | s3://ibk-discovery-ba-us-east-1-992382582498-data/discovery/pa/               |
*/

SELECT *
FROM disc_model_owner.ds_cppibkren_cal -- ds que crea el CTAS del notebook (build del ds con inference.sql)
WHERE cod_mes = '202606' -- TODO: Reemplazar por el periodo a validar
