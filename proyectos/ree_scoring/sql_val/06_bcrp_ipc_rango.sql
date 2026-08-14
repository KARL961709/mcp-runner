-- 06. ALCANCE DE LA SERIE MACRO GOBERNADA
--   el factor del mes T se arma con la serie de T-10 a T-5: el arranque acota
--   hasta donde se puede reconstruir el historico dentro de Athena.
--   n distinto de n_meses indica mas de una fila por mes.
SELECT COUNT(*)                                                                   AS n,
       COUNT(DISTINCT CAST(cod_mes AS VARCHAR))                                   AS n_meses,
       MIN(CAST(cod_mes AS VARCHAR))                                              AS cod_mes_min,
       MAX(CAST(cod_mes AS VARCHAR))                                              AS cod_mes_max,
       SUM(CASE WHEN porc_ipc IS NULL THEN 1 ELSE 0 END)                          AS n_nulos
  FROM e_perm_aws.t_mst_bcrp_rsk
