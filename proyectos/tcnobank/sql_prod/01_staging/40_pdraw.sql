-- ============================================================================
-- 40. PD CRUDA DEL MODELO VCNBANK
--   scan: scr_vcnbank_rsk en codmes
--   ancla: p_codmes del score = codmes_mrm. La q22 verifico cod_mes = p_codmes
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_40_pdraw AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
)
SELECT p.tip_doc,
       p.id_value,
       TRY_CAST(s.prob_model         AS DOUBLE)                                        AS pd_raw,
       TRY_CAST(s.puntuacion         AS INTEGER)                                       AS puntuacion,
       TRY_CAST(s.prob_modelo_cal    AS DOUBLE)                                        AS pd_cal_vigente,
       TRY_CAST(s.puntuacion_cal     AS INTEGER)                                       AS puntuacion_cal_vigente,
       s.grupo_calibracion                                                             AS grupo_cal_vigente,
       s.tip_situacion_laboral                                                         AS sitlab_score,
       TRY_CAST(s.rat_expect_inflacion AS DOUBLE)                                      AS macro_inflacion,
       TRY_CAST(s.rat_tasa_desempleo   AS DOUBLE)                                      AS macro_desempleo,
       TRY_CAST(s.rat_tasa_desempleo_6 AS DOUBLE)                                      AS macro_desempleo_6,
       CAST(CASE WHEN s.key_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_score,
       p.codmes_mrm
FROM po p
LEFT JOIN e_perm_aws.scr_vcnbank_rsk s
       ON s.cod_tip_doc = p.tip_doc
      AND s.key_value   = p.id_value
      AND s.p_codmes    = p.codmes_mrm
