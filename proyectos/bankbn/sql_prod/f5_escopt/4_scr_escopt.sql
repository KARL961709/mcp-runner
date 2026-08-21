-- 4_scr_escopt.sql | tabla NUEVA = scr_admbankbpe_calibrado_202607 tal cual + columna prob_modelo_esc_opt (escenario optimista = prob_modelo_cal x factor por personeria, PJJ 0.6814 / PNN 0.9697, tip_doc=2 es PJJ). Lee la tabla existente, NO la reemplaza. Sale sin particion (copia de escenario)
CREATE TABLE disc_model_owner.scr_admbankbpe_calibrado_202607_escopt
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
SELECT s.*,
       greatest(1e-6, least(1 - 1e-6,
         s.prob_modelo_cal * CASE WHEN s.tip_doc = '2' THEN 0.68140 ELSE 0.96970 END)) AS prob_modelo_esc_opt
FROM disc_model_owner.scr_admbankbpe_calibrado_202607 s
