-- v16_ancla_dm1_contrafactual.sql | contrafactual del ancla, SIN construir nada
-- Read-only sobre ds_stk_ree_pp_cal, que ya trae las 90 cohortes: la fila de la
-- cohorte D-1 YA existe con su pd_raw, target, drivers y filtros. Solo cambia
-- cual fila lleva la marca. Devuelve la LRA nueva, la cobertura del join PD y el
-- volteo de segmento. 6 filas.
WITH mar AS (
  SELECT DISTINCT id_value, codmes_mrm AS d
  FROM disc_model_owner.ds_stk_ree_pp_11_marca
  WHERE codmes_mrm BETWEEN '202401' AND '202506'
),
u AS (
  SELECT '1_actual_D' AS version, c.tipo_ingreso_dep, c.flg_clean, c.flg_calib,
         c.falla_madurez_12, c.falla_cruce_pd, c.flg_ree_v4, c.pd_raw, c.target_12m_60
  FROM mar m
  INNER JOIN disc_model_owner.ds_stk_ree_pp_cal c
          ON c.id_value = m.id_value AND c.codmes_mrm = m.d
  UNION ALL
  SELECT '2_alineado_Dm1', c.tipo_ingreso_dep, c.flg_clean, c.flg_calib,
         c.falla_madurez_12, c.falla_cruce_pd, c.flg_ree_v4, c.pd_raw, c.target_12m_60
  FROM mar m
  INNER JOIN disc_model_owner.ds_stk_ree_pp_cal c
          ON c.id_value = m.id_value
         AND c.codmes_mrm = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
)
SELECT
  version,
  COALESCE(tipo_ingreso_dep, 'TOTAL')                                       AS segmento,
  COUNT(*)                                                                  AS n_scope,
  ROUND(AVG(CASE WHEN falla_cruce_pd = 1 THEN 1.0 ELSE 0 END), 4)           AS pct_sin_pd_raw,
  ROUND(AVG(CASE WHEN flg_ree_v4 = 1 THEN 1.0 ELSE 0 END), 4)               AS pct_flgree_v4,
  COUNT_IF(flg_calib = 1)                                                   AS n_calib,
  COUNT_IF(flg_calib = 1 AND flg_clean = 1)                                 AS n_fit,
  COUNT_IF(flg_calib = 1 AND flg_clean = 1 AND falla_madurez_12 = 0)        AS n_fit_maduro,
  SUM(CASE WHEN flg_calib = 1 AND flg_clean = 1 AND falla_madurez_12 = 0
           THEN CAST(target_12m_60 AS DOUBLE) END)                          AS malos_12m,
  ROUND(AVG(CASE WHEN flg_calib = 1 AND flg_clean = 1 AND falla_madurez_12 = 0
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)                AS lra_nueva,
  ROUND(AVG(CASE WHEN flg_calib = 1 AND flg_clean = 1 AND falla_madurez_12 = 0
                 THEN pd_raw END), 6)                                       AS pd_raw_media
FROM u
GROUP BY GROUPING SETS ((version, tipo_ingreso_dep), (version))
ORDER BY 1, 2
