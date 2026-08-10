-- v13_alcance_macro.sql | el segundo techo: hasta que mes hay f_t
-- Read-only. El score no es la unica restriccion. El f_t del scoring usa
-- x_t = media de porc_ipc sobre t-10 a t-5, con HAVING COUNT = 6: si falta uno
-- de esos seis meses el mes sale SIN f_t y no se puede publicar, aunque tenga
-- score. Por eso el techo real es el minimo entre los dos alcances.
-- La ventaja del rezago: para scorear el mes t basta el IPC hasta t-5, asi que
-- el macro suele ir por delante y no ser el que ata.
SELECT c.codmes_drv                                                     AS codmes_drv,
       DATE_FORMAT(DATE_ADD('month',  1, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m') AS codmes_score_necesario,
       DATE_FORMAT(DATE_ADD('month',-10, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m') AS ipc_desde,
       DATE_FORMAT(DATE_ADD('month', -5, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m') AS ipc_hasta,
       COUNT(m.porc_ipc)                                                AS n_meses_ipc,
       CASE WHEN COUNT(m.porc_ipc) = 6 THEN 'SI' ELSE 'NO' END          AS tiene_ft,
       ROUND(AVG(m.porc_ipc), 4)                                        AS x_t
FROM (
  SELECT DATE_FORMAT(DATE_ADD('month', s.n, DATE_PARSE('202601', '%Y%m')), '%Y%m') AS codmes_drv
  FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11) s
) c
LEFT JOIN e_perm_aws.t_mst_bcrp_rsk m
  ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month',-10, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                   AND DATE_FORMAT(DATE_ADD('month', -5, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
 AND m.porc_ipc IS NOT NULL
GROUP BY c.codmes_drv
ORDER BY 1 DESC
