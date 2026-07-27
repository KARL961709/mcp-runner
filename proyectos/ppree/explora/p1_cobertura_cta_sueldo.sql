-- ============================================================================
-- P1. La UNICA fuente del build cuya cobertura mensual nunca se midio.
--     Si t_rsk_cta_sueldo no llega a 2019, flg_cs queda en 0 por COALESCE en
--     todo ese tramo: mismo defecto que U6, y flg_cs entra a sit_lab_cs, que
--     es el driver del delta probit. Se mide ANTES de construir 40_drivers.
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                        AS anio,
  COUNT(*)                                                     AS n,
  COUNT(DISTINCT CAST(codmes AS VARCHAR))                      AS n_meses_con_filas,
  MIN(CAST(codmes AS VARCHAR))                                 AS mes_min,
  MAX(CAST(codmes AS VARCHAR))                                 AS mes_max,
  SUM(CASE WHEN CAST(flg_cs_riesgos AS INTEGER) = 1 THEN 1 ELSE 0 END) AS n_cs_1,
  COUNT(DISTINCT CAST(tipdoc AS VARCHAR))                      AS n_dom_tipdoc
FROM e_perm_aws.t_rsk_cta_sueldo
GROUP BY 1
ORDER BY 1
