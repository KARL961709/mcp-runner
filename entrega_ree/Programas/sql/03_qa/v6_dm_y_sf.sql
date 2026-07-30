-- ============================================================================
-- V6. Las dos fuentes que mas decidieron el diseno.
--     20_dm: ctrl_saldo_nulo cuantifica el caso que antes tapaba el COALESCE.
--            flg_asof_igual_codmes debe ser 1 en el 100% (H63).
--            El hueco 202107 debe aparecer como mes AUSENTE, no como cero filas.
--     25_sf: el re-estampado +1 debe ser exacto en todas las filas.
--            n_centinela = 9999 debe ser 0 en el perimetro (J2).
-- ============================================================================
SELECT 'dm' AS tabla,
  SUBSTR(codmes, 1, 4)                                                            AS anio,
  COUNT(DISTINCT codmes)                                                          AS n_meses,
  COUNT(*)                                                                        AS n,
  SUM(ctrl_saldo_nulo)                                                            AS n_saldo_nulo,
  SUM(CASE WHEN flg_asof_igual_codmes = 0 THEN 1 ELSE 0 END)                      AS falla_asof,
  SUM(flg_alguna_cta_saldo_cero)                                                  AS n_saldo_cero,
  SUM(flg_alguna_cta_cuc_nulo)                                                    AS n_cuc_nulo,
  0                                                                               AS falla_reestampado,
  0                                                                               AS n_centinela
FROM disc_model_owner.ds_stk_ree_pp_20_dm
GROUP BY 1, 2
UNION ALL
SELECT 'sf',
  SUBSTR(codmes, 1, 4),
  COUNT(DISTINCT codmes),
  COUNT(*),
  0,
  0,
  0,
  0,
  SUM(CASE WHEN codmes <> DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(rcc_codmes, '%Y%m')), '%Y%m')
           THEN 1 ELSE 0 END),
  SUM(CASE WHEN cond_max = 9999 THEN 1 ELSE 0 END)
FROM disc_model_owner.ds_stk_ree_pp_25_sf
GROUP BY 1, 2
ORDER BY 1, 2
