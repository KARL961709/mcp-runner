-- ============================================================================
-- V4. Los defaults silenciosos, hechos visibles por anio.
--     U6: ds_rtd_rskvol_cas_ingr_ir no tiene filas antes de 202201, asi que
--         pct_sin_tipo_ingreso debe ser ~100 en 2019-2021 y ~0 desde 2022.
--     A42: flg_cs_estado separa CS / NO_CS / SIN_DATO. La suma de los tres
--         debe dar n, y n_sin_dato debe igualar a falla_sin_cta_sueldo: si no,
--         el eje nuevo no reproduce el control que dice reemplazar.
--     pct_sin_pd: la v4 cubre codmes_mrm 202312-202604 (H34).
-- ============================================================================
SELECT
  SUBSTR(d.codmes_mrm, 1, 4)                                                      AS anio,
  COUNT(*)                                                                        AS n,
  ROUND(100.0 * AVG(CAST(d.falla_sin_tipo_ingreso AS DOUBLE)), 2)                 AS pct_sin_tipo_ingreso,
  ROUND(100.0 * AVG(CAST(p.falla_cruce_pd AS DOUBLE)), 2)                         AS pct_sin_pd,
  SUM(CASE WHEN d.flg_cs_estado = 'CS'       THEN 1 ELSE 0 END)                   AS n_cs,
  SUM(CASE WHEN d.flg_cs_estado = 'NO_CS'    THEN 1 ELSE 0 END)                   AS n_no_cs,
  SUM(CASE WHEN d.flg_cs_estado = 'SIN_DATO' THEN 1 ELSE 0 END)                   AS n_sin_dato,
  COUNT(*) - SUM(CASE WHEN d.flg_cs_estado IN ('CS','NO_CS','SIN_DATO') THEN 1 ELSE 0 END) AS falla_estado_fuera_dominio,
  SUM(CASE WHEN d.flg_cs_estado = 'SIN_DATO' THEN 1 ELSE 0 END) - SUM(d.falla_sin_cta_sueldo) AS falla_estado_vs_control,
  SUM(CASE WHEN d.flg_cs_estado = 'CS' AND d.flg_cs <> 1 THEN 1 ELSE 0 END)       AS falla_cs_incoherente,
  SUM(CASE WHEN d.tipo_ingreso_dep = 'DEP' THEN 1 ELSE 0 END)                     AS n_dep,
  SUM(CASE WHEN d.sit_lab_cs_5v = 'MIX_CS' THEN 1 ELSE 0 END)                     AS n_mix_cs,
  SUM(CASE WHEN d.sit_lab_cs_5v = 'MIX_NO_CS' THEN 1 ELSE 0 END)                  AS n_mix_no_cs,
  SUM(d.ctrl_fuente_nueva)                                                        AS n_fuente_nueva,
  SUM(p.falla_pd_rango)                                                           AS falla_pd_rango
FROM disc_model_owner.ds_stk_ree_pp_40_drivers d
LEFT JOIN disc_model_owner.ds_stk_ree_pp_50_pd p
       ON p.codmes_mrm = d.codmes_mrm AND p.tip_doc = d.tip_doc AND p.id_value = d.id_value
GROUP BY 1
ORDER BY 1
