-- c3 | hasta que codmes_mrm alcanza el IPC gobernado para producir f_t
--      Es la misma expresion del paso 80. Un mes con x_t nulo sale sin PD cal
SELECT cod_mes                                    AS codmes_mrm,
       ROUND(porc_ipc, 8)                         AS ipc_mes,
       ROUND(x_t, 8)                              AS x_t,
       CASE WHEN x_t IS NULL THEN 'SIN f_t' ELSE 'OK' END AS estado,
       ROUND(GREATEST(-1.130850, LEAST(0.765684,
         (-1.7250030205 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * x_t))
         / sqrt(0.0380301160) + 0.19111262)), 6)  AS f_t
FROM (
  SELECT cod_mes, porc_ipc,
         AVG(porc_ipc) OVER (ORDER BY cod_mes ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING) AS x_t
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE cod_mes >= '201801'
) m
WHERE cod_mes >= '202512'
ORDER BY 1 DESC
LIMIT 20
