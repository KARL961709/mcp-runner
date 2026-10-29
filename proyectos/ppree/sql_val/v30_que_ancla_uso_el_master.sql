-- ============================================================================
-- v30. QUE ANCLA uso el master: codmes_scr o codmes_mrm? Prueba las DOS.
--   12_equiv dio n_pd_raw_identica = 0 en los 34 meses con el join
--   c.codmes_scr = s.codmes, y n_segmento_distinto = 0. Clientes correctos,
--   pd de otro mes. Aca se cruza pd_raw del maestro contra prob_modelo de la
--   fuente bajo los dos anclas sobre la MISMA poblacion del fit.
--   Gana el que devuelva n_identica > 0. Si ninguno, la fuente es otra tabla.
-- ============================================================================
WITH c AS (
  SELECT codmes_mrm, codmes_scr, tip_doc, id_value, pd_raw
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_calib = 1
    AND flg_clean = 1
    AND flg_scope_ree = 1
    AND codmes_mrm BETWEEN '202212' AND '202509'
    AND pd_raw IS NOT NULL
),
v AS (
  SELECT CAST(cod_mes AS VARCHAR)     AS mes,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR)   AS id_value,
         CAST(prob_modelo AS DOUBLE)  AS pd_n
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
),
w AS (
  SELECT CAST(codmes AS VARCHAR)            AS mes,
         CAST(cod_tip_doc AS VARCHAR)       AS tip_doc,
         CAST(key_value AS VARCHAR)         AS id_value,
         CAST(pd_comppp_reen_itc AS DOUBLE) AS pd_v
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE pd_comppp_reen_itc IS NOT NULL
)
SELECT 'cal_2023 por codmes_scr' AS prueba,
       COUNT(*) AS n_cal, COUNT(v.id_value) AS n_cruce,
       SUM(CASE WHEN abs(c.pd_raw - v.pd_n) < 1e-12 THEN 1 ELSE 0 END) AS n_identica,
       ROUND(100.0 * AVG(c.pd_raw), 4) AS pd_maestro_pct,
       ROUND(100.0 * AVG(v.pd_n), 4)   AS pd_fuente_pct
  FROM c LEFT JOIN v ON v.mes = c.codmes_scr AND v.tip_doc = c.tip_doc AND v.id_value = c.id_value
UNION ALL
SELECT 'cal_2023 por codmes_mrm',
       COUNT(*), COUNT(v.id_value),
       SUM(CASE WHEN abs(c.pd_raw - v.pd_n) < 1e-12 THEN 1 ELSE 0 END),
       ROUND(100.0 * AVG(c.pd_raw), 4), ROUND(100.0 * AVG(v.pd_n), 4)
  FROM c LEFT JOIN v ON v.mes = c.codmes_mrm AND v.tip_doc = c.tip_doc AND v.id_value = c.id_value
UNION ALL
SELECT 'reen_v4 por codmes_scr',
       COUNT(*), COUNT(w.id_value),
       SUM(CASE WHEN abs(c.pd_raw - w.pd_v) < 1e-12 THEN 1 ELSE 0 END),
       ROUND(100.0 * AVG(c.pd_raw), 4), ROUND(100.0 * AVG(w.pd_v), 4)
  FROM c LEFT JOIN w ON w.mes = c.codmes_scr AND w.tip_doc = c.tip_doc AND w.id_value = c.id_value
UNION ALL
SELECT 'reen_v4 por codmes_mrm',
       COUNT(*), COUNT(w.id_value),
       SUM(CASE WHEN abs(c.pd_raw - w.pd_v) < 1e-12 THEN 1 ELSE 0 END),
       ROUND(100.0 * AVG(c.pd_raw), 4), ROUND(100.0 * AVG(w.pd_v), 4)
  FROM c LEFT JOIN w ON w.mes = c.codmes_mrm AND w.tip_doc = c.tip_doc AND w.id_value = c.id_value
ORDER BY 1
