-- 3_reset_scr_escopt.sql | dropea SOLO la tabla nueva del escenario optimista de la scr (no toca la original scr_admbankbpe_calibrado_202607). Corre ANTES de 4. Tabla gestionada: el DROP limpia S3
DROP TABLE IF EXISTS disc_model_owner.scr_admbankbpe_calibrado_202607_escopt
