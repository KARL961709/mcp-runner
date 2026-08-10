-- 5z_reset_scr_calibrado.sql | borra la tabla calibrada desde la fuente del score. Corre ANTES de 6a. Es tabla gestionada por Athena, asi que el DROP tambien limpia el S3
DROP TABLE IF EXISTS disc_model_owner.scr_admbankbpe_calibrado_202607
