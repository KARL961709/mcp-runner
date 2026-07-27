-- ============================================================================
-- G4. R11 - CONTRAFACTUAL DEL CAMBIO DE FUENTE DE PD: v4 al lado de v2.
--     Solape de llaves, concordancia del flg_reenganche y delta de pd.
-- ============================================================================
WITH v4 AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR) AS key_value,
         CAST(flg_reenganche AS INTEGER) AS flg_ree,
         CAST(pd_comppp_reen_itc AS DOUBLE) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
),
v2 AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR) AS key_value,
         CAST(flg_reenganche AS INTEGER) AS flg_ree,
         CAST(pd_comppp_reen_itc AS DOUBLE) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov2_desencriptado
)
SELECT
  SUBSTR(COALESCE(a.codmes, b.codmes), 1, 4)                                      AS anio,
  COUNT(*)                                                                        AS n_union,
  SUM(CASE WHEN a.key_value IS NOT NULL AND b.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_ambas,
  SUM(CASE WHEN a.key_value IS NOT NULL AND b.key_value IS NULL THEN 1 ELSE 0 END)     AS n_solo_v4,
  SUM(CASE WHEN a.key_value IS NULL AND b.key_value IS NOT NULL THEN 1 ELSE 0 END)     AS n_solo_v2,
  SUM(CASE WHEN a.flg_ree = 1 AND b.flg_ree = 1 THEN 1 ELSE 0 END)                AS n_ree_ambas,
  SUM(CASE WHEN a.flg_ree = 1 AND COALESCE(b.flg_ree, 0) = 0 THEN 1 ELSE 0 END)   AS n_ree_solo_v4,
  SUM(CASE WHEN COALESCE(a.flg_ree, 0) = 0 AND b.flg_ree = 1 THEN 1 ELSE 0 END)   AS n_ree_solo_v2,
  ROUND(CORR(a.pd, b.pd), 6)                                                      AS corr_pd,
  ROUND(AVG(ABS(a.pd - b.pd)), 8)                                                 AS mae_pd,
  ROUND(AVG(a.pd), 6)                                                             AS pd_prom_v4,
  ROUND(AVG(b.pd), 6)                                                             AS pd_prom_v2
FROM v4 a
FULL OUTER JOIN v2 b
  ON a.codmes = b.codmes AND a.tip_doc = b.tip_doc AND a.key_value = b.key_value
GROUP BY 1
ORDER BY 1
