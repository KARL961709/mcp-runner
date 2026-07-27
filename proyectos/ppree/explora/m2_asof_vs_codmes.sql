-- ============================================================================
-- M2. D2 - as_of_mes vs codmes en el cierre mensual.
--     El Recibido pinnea flg_mto_pend y flg_baja con as_of_date (#L237-238) y
--     flg_malo_orig con codmes (#L234). Si las dos columnas coinciden siempre,
--     60_filtros es equivalente al Recibido; si no, hay que joinear por llave
--     y elegir la fila por as_of_date, como hace el original.
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                                          AS anio,
  COUNT(*)                                                                       AS n_filas,
  SUM(CASE WHEN as_of_date IS NULL THEN 1 ELSE 0 END)                            AS n_asof_null,
  SUM(CASE WHEN DATE_FORMAT(DATE_PARSE(as_of_date, '%Y-%m-%d'), '%Y%m') = CAST(codmes AS VARCHAR)
           THEN 1 ELSE 0 END)                                                    AS n_igual,
  SUM(CASE WHEN as_of_date IS NOT NULL
             AND DATE_FORMAT(DATE_PARSE(as_of_date, '%Y-%m-%d'), '%Y%m') <> CAST(codmes AS VARCHAR)
           THEN 1 ELSE 0 END)                                                    AS n_distinto,
  COUNT(DISTINCT CASE WHEN as_of_date IS NOT NULL
             AND DATE_FORMAT(DATE_PARSE(as_of_date, '%Y-%m-%d'), '%Y%m') <> CAST(codmes AS VARCHAR)
           THEN CAST(codmes AS VARCHAR) END)                                     AS n_meses_con_desvio
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
  AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
GROUP BY 1
ORDER BY 1
