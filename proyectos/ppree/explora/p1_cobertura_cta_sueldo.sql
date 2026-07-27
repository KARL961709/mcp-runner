-- ============================================================================
-- P1. La pregunta que decide si el 69-100% de pct_sin_cta_sueldo (v4) es un
--     hueco o un dato.
--     Si la tabla lista SOLO clientes CON cuenta sueldo (todas las filas con
--     flg_cs_riesgos = 1), la ausencia significa 'no tiene' y el COALESCE a 0
--     es correcto. Si lista a TODOS con un flag 0/1, la ausencia es un hueco y
--     flg_cs esta mal para ~3 de cada 4 registros del universo.
--     flg_cs alimenta sit_lab_cs, que es el driver del delta probit.
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                                      AS anio,
  COUNT(*)                                                                   AS n,
  COUNT(DISTINCT CAST(codmes AS VARCHAR))                                    AS n_meses,
  MIN(CAST(codmes AS VARCHAR))                                               AS mes_min,
  MAX(CAST(codmes AS VARCHAR))                                               AS mes_max,
  SUM(CASE WHEN CAST(flg_cs_riesgos AS INTEGER) = 1 THEN 1 ELSE 0 END)       AS n_flag_1,
  SUM(CASE WHEN CAST(flg_cs_riesgos AS INTEGER) = 0 THEN 1 ELSE 0 END)       AS n_flag_0,
  SUM(CASE WHEN flg_cs_riesgos IS NULL THEN 1 ELSE 0 END)                    AS n_flag_null,
  COUNT(DISTINCT CAST(tipdoc AS VARCHAR))                                    AS n_dom_tipdoc,
  MIN(LENGTH(CAST(key_value AS VARCHAR)))                                    AS len_min_key,
  MAX(LENGTH(CAST(key_value AS VARCHAR)))                                    AS len_max_key
FROM e_perm_aws.t_rsk_cta_sueldo
GROUP BY 1
ORDER BY 1
