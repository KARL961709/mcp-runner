/* ¿En que base de datos y ruta de S3 debo crear la tabla 'disc_<placeholder>.scr_<placeholder>'?

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

SELECT cod_mes,
       key_value,
	   cod_tip_doc,
	   cod_cli,
       prob_modelo,
	   puntuacion,
       modelo,
       ts_carga,
	   grupo_ejec,
       segmento,
	   orden,
       -- Start: Add Calibration
       grupo_calibracion,
       prob_modelo_cal,
       puntuacion_cal,
       trf_macro01,
       trf_macro02,
       -- End: Add Calibration
       extra_01,
	   extra_02,
	   extra_03,
	   extra_04,
	   extra_05
FROM disc_model_owner.scr_cppibkren_rsk -- scr que crea el scoring job (nuestras tablas van a disc_model_owner)
WHERE cod_mes = '202606'
