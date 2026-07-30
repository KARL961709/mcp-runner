-- v4_00 DROP de la tabla v4 -- correr SOLO con -Only v4_00_drop
-- OJO: el CTAS de v4_10 escribe en external_location. Athena FALLA si el prefijo S3 no esta
-- vacio, asi que despues de este DROP hay que vaciar el prefijo <S3_DATOS>/fen/grado_elnino_ubigeo_v4/
-- antes de re-crear. Un DROP no borra los datos.
DROP TABLE IF EXISTS disc_model_owner.grado_elnino_ubigeo_v4
