-- m1_00 DROP de la tabla de marcado -- correr con -Only m1_00_drop
-- OJO: m1_10 escribe en external_location. Un DROP no borra S3: hay que vaciar el prefijo
-- <S3_DATOS>/fen/fen_geo_marca_202607/ antes de re-crear, o Athena falla por location no vacia.
DROP TABLE IF EXISTS disc_model_owner.fen_geo_marca_202607
