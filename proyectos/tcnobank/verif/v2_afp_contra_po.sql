-- ============================================================================
-- V2. AFP - ESTADOS Y CUANTO TOCA A NUESTRA POBLACION
--   scan: t_fact_edc_solicitud_retiro_afp_ibk U ds_adm_vcnbank_tc_cal
--   ancla: 721,533 de los que retiraron estan en la po segun d25. Si la mayoria tiene
--          abono, excluirlos mueve mucho. Si la mayoria solo solicito, el create
--          original esta excluyendo gente que nunca recibio un sol
-- ============================================================================
SELECT a.desc_estado_solicitud                                                          AS estado,
       CAST(a.flg_abono AS VARCHAR)                                                     AS flg_abono,
       count(*)                                                                         AS n,
       count(DISTINCT a.key_value)                                                      AS n_personas,
       count(DISTINCT c.id_value)                                                       AS n_en_la_po,
       round(100.0 * count(DISTINCT c.id_value)
             / nullif(count(DISTINCT a.key_value), 0), 3)                               AS pct_en_la_po
FROM e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk a
LEFT JOIN (SELECT DISTINCT tip_doc, id_value FROM disc_model_owner.ds_adm_vcnbank_tc_cal) c
       ON c.id_value = a.key_value AND c.tip_doc = CAST(a.cod_tip_doc AS VARCHAR)
GROUP BY a.desc_estado_solicitud, CAST(a.flg_abono AS VARCHAR)
ORDER BY n DESC
LIMIT 30
