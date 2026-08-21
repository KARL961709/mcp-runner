-- 2_ds_escopt.sql | tabla NUEVA = ds_adm_bpe_bankbn_cal_202607 tal cual + columna prob_modelo_esc_opt (escenario optimista = prob_modelo_cal x factor anti-conservador por personeria, PJJ 0.6814 / PNN 0.9697). Lee la tabla existente, NO la reemplaza
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal_202607_escopt
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
SELECT c.*,
       greatest(1e-6, least(1 - 1e-6,
         c.prob_modelo_cal * CASE WHEN c.personeria = 'PJJ' THEN 0.68140 ELSE 0.96970 END)) AS prob_modelo_esc_opt
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607 c
