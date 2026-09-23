-- escf_02_build.sql | ENTREGABLE v2_esc_opt 202501-202609 = enviada TAL CUAL (202501-208) UNION mi 202609 (v2native clean/dirty x factor). Solo columnas del esc opt (dropea _v21). codmes = p_codmes+1. Particionada por p_codmes.
CREATE TABLE disc_model_owner.scr_admbankbpe_rsk_cal_202501_202609
WITH (format='PARQUET', parquet_compression='SNAPPY', partitioned_by=ARRAY['p_codmes']) AS
SELECT codmes, tip_doc, key_value, personeria,
       prob_modelo_cal_v2, puntuacion_cal_v2,
       prob_modelo_cal_v2_opt, puntuacion_cal_v2_opt,
       p_codmes
FROM disc_model_owner.scr_admbankbpe_rsk_cal_202501_202608
UNION ALL
SELECT CAST(CASE WHEN n.p_codmes % 100 = 12 THEN n.p_codmes + 89 ELSE n.p_codmes + 1 END AS INTEGER) AS codmes,
       n.tip_doc, n.key_value, n.personeria,
       n.prob_modelo_cal_v2, n.puntuacion_cal_v2,
       n.prob_modelo_cal_v2_opt, n.puntuacion_cal_v2_opt,
       CAST(n.p_codmes AS INTEGER) AS p_codmes
FROM disc_model_owner.b46029_v2n_escopt_202609 n
WHERE n.p_codmes = 202609
