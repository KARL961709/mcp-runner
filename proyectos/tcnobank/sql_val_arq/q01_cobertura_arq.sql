-- ============================================================================
-- Q01. COBERTURA DEL ARQUETIPO DE SALUD POR ENTIDAD
--   scan: ds_adm_vcnbank_tc_cal
--   pregunta: existe el arquetipo fuera de Interbank
--   seg_arq_salud sale de e_perm_aws.t_inca_sa y entra por el mapa
--   t_mst_inter_ibk_base_cliente, que es la base de clientes de INTERBANK. Un
--   cliente que no es cliente de IBK no tiene inter_party_id, y sin party_id no
--   hay arquetipo. Esta consulta mide de cuanto estamos hablando por entidad
--   antes de intentar cualquier lectura de riesgo.
-- ============================================================================
SELECT entidad,
       count(*)                                                                     AS n,
       sum(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END)                          AS n_con_pdraw,
       sum(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END)                      AS n_maduro,
       sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                               AS n_clean,
       sum(CASE WHEN flg_calib = 1 THEN 1 ELSE 0 END)                               AS n_calib,
       sum(CASE WHEN ctrl_inca_sin_dato = 1 THEN 1 ELSE 0 END)                      AS n_sin_inca,
       round(100.0 * sum(CASE WHEN ctrl_inca_sin_dato = 1 THEN 1 ELSE 0 END)
             / count(*), 2)                                                         AS pct_sin_inca,
       sum(CASE WHEN seg_arq_salud IS NULL THEN 1 ELSE 0 END)                       AS n_arq_nulo,
       round(100.0 * sum(CASE WHEN seg_arq_salud IS NULL THEN 1 ELSE 0 END)
             / count(*), 2)                                                         AS pct_arq_nulo,
       sum(CASE WHEN seg_arq_salud = 'C' THEN 1 ELSE 0 END)                         AS n_c,
       round(100.0 * sum(CASE WHEN seg_arq_salud = 'C' THEN 1 ELSE 0 END)
             / nullif(sum(CASE WHEN seg_arq_salud IS NOT NULL THEN 1 ELSE 0 END), 0), 2) AS pct_c_de_no_nulo,
       count(DISTINCT seg_arq_salud)                                                AS n_celdas,
       min(codmes_mrm)                                                              AS mes_min,
       max(codmes_mrm)                                                              AS mes_max
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal
 GROUP BY entidad
 ORDER BY n DESC
