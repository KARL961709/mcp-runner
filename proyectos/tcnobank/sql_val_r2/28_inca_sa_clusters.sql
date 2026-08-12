-- 28_inca_sa_clusters.sql | reparto de las variables categoricas de t_inca_sa en el mes mas reciente cargado, para ver si los clusters tienen masa suficiente antes de probarlos como driver
SELECT c.variable,
       c.valor,
       count(*)                                                                  AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY c.variable), 3) AS pct_en_variable
FROM e_perm_aws.t_inca_sa t
CROSS JOIN UNNEST(ARRAY['1.seg_arq_salud', '2.region_12m_prio', '3.var_cuali_far_rubrofrec_9m_v3',
                        '4.flg_hospitales_12m'],
                  ARRAY[CAST(t.seg_arq_salud AS VARCHAR), CAST(t.region_12m_prio AS VARCHAR),
                        CAST(t.var_cuali_far_rubrofrec_9m_v3 AS VARCHAR),
                        CAST(t.flg_cant_trx_rubro_hospitales_clinicas_pos_ult_12m_1 AS VARCHAR)])
     AS c (variable, valor)
WHERE t.cod_mes = (SELECT max(cod_mes) FROM e_perm_aws.t_inca_sa)
GROUP BY c.variable, c.valor
ORDER BY c.variable, n DESC
LIMIT 80
