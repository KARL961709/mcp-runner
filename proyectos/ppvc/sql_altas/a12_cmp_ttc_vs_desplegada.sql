-- ============================================================================
-- a12. Compara altas_adm_pp_cdpp_cal_ttc (nueva) vs altas_adm_pp_cdpp_cal (desplegada).
--      Verifica que las columnas CAL reproducen 1:1 (la nueva solo agrega TTC).
--      FULL OUTER JOIN por (tip_doc, key_value, codmes). Solo agregados, sin key_value.
--      OK esperado: solo_* = 0, n_dif_* = 0, maxdif_* ~ 0 (identidad por construccion).
-- ============================================================================
SELECT
    COUNT(*) AS n_total,
    SUM(CASE WHEN t.key_value IS NULL THEN 1 ELSE 0 END) AS solo_desplegada,
    SUM(CASE WHEN d.key_value IS NULL THEN 1 ELSE 0 END) AS solo_ttc,
    SUM(CASE
          WHEN t.prob_modelo_cal_ppfacil IS NULL AND d.prob_modelo_cal_ppfacil IS NULL THEN 0
          WHEN t.prob_modelo_cal_ppfacil IS NULL OR d.prob_modelo_cal_ppfacil IS NULL THEN 1
          WHEN abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil) > 1e-12 THEN 1
          ELSE 0 END) AS n_dif_facil,
    SUM(CASE
          WHEN t.prob_modelo_cal_ppcd IS NULL AND d.prob_modelo_cal_ppcd IS NULL THEN 0
          WHEN t.prob_modelo_cal_ppcd IS NULL OR d.prob_modelo_cal_ppcd IS NULL THEN 1
          WHEN abs(t.prob_modelo_cal_ppcd - d.prob_modelo_cal_ppcd) > 1e-12 THEN 1
          ELSE 0 END) AS n_dif_cd,
    max(abs(t.prob_modelo_cal_ppfacil - d.prob_modelo_cal_ppfacil)) AS maxdif_facil,
    max(abs(t.prob_modelo_cal_ppcd - d.prob_modelo_cal_ppcd)) AS maxdif_cd,
    SUM(CASE WHEN t.puntuacion_modelo_cal_ppfacil IS DISTINCT FROM d.puntuacion_modelo_cal_ppfacil THEN 1 ELSE 0 END) AS n_dif_punt_facil,
    SUM(CASE WHEN t.puntuacion_modelo_cal_ppcd IS DISTINCT FROM d.puntuacion_modelo_cal_ppcd THEN 1 ELSE 0 END) AS n_dif_punt_cd
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc t
FULL OUTER JOIN disc_model_owner.altas_adm_pp_cdpp_cal d
  ON t.tip_doc = d.tip_doc AND t.key_value = d.key_value AND t.codmes = d.codmes
