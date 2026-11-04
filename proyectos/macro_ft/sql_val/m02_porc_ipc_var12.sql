-- m02. porc_ipc (mensual PN01271PM) y la var-12m COMPUESTA (producto movil 12m) para contrastar
--   var12m[t] = (prod 12m (1+porc_ipc/100) - 1)*100. n=12 -> ventana completa. Compara con var-12m del indice.
WITH m AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cm, MAX(CAST(porc_ipc AS DOUBLE)) AS ipc_m
  FROM e_perm_aws.t_mst_bcrp_rsk
  GROUP BY CAST(cod_mes AS VARCHAR)
),
w AS (
  SELECT cm, ipc_m,
    100.0 * (exp(sum(ln(1.0 + ipc_m/100.0)) OVER (ORDER BY cm ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)) - 1.0) AS var12m_compuesto,
    count(ipc_m) OVER (ORDER BY cm ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS n_vent
  FROM m
)
SELECT cm,
       round(ipc_m, 4) AS porc_ipc_mensual,
       round(var12m_compuesto, 4) AS var12m_compuesto,
       n_vent
FROM w
WHERE cm >= '202406'
ORDER BY cm
