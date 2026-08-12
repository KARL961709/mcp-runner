-- 27_inca_sa_dimension.sql | dimensiona el driver t_inca_sa: ventana, volumen y cardinalidad de sus clusters, para saber si sirve como eje de segmentacion con rezago -2
SELECT cod_mes,
       count(*)                                                                     AS n,
       count(DISTINCT party_id)                                                     AS parties,
       count(DISTINCT seg_arq_salud)                                                AS n_seg_arq,
       count(DISTINCT region_12m_prio)                                              AS n_region,
       count(DISTINCT var_cuali_far_rubrofrec_9m_v3)                                AS n_rubrofrec,
       sum(CASE WHEN seg_arq_salud IS NULL THEN 1 ELSE 0 END)                       AS sin_seg,
       sum(CASE WHEN flg_cant_trx_rubro_hospitales_clinicas_pos_ult_12m_1 IS NULL
                THEN 1 ELSE 0 END)                                                  AS sin_flg_hosp
FROM e_perm_aws.t_inca_sa
GROUP BY cod_mes
ORDER BY cod_mes
