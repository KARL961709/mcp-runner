-- ============================================================================
-- 87. EQUIVALENCIA DE POBLACION CONTRA LA PO VIGENTE
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal U e_perm_aws.ds_flg_admtcnobk1_rsk, solape [202303,202606]
--   ancla: la vigente lleva codmes_mrm propio. Grano cliente-mes con prelacion 1 en ambos lados
-- ============================================================================
WITH nuevo AS (
    SELECT codmes_mrm, tip_doc, id_value
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE prelacion_cod = 1
      AND codmes_mrm BETWEEN '202303' AND '202606'
),
vigente AS (
    SELECT codmes_mrm, tip_doc, id_value
    FROM e_perm_aws.ds_flg_admtcnobk1_rsk
    WHERE prelacion_00m = 1
      AND codmes_mrm BETWEEN '202303' AND '202606'
)
SELECT coalesce(n.codmes_mrm, v.codmes_mrm)                                            AS codmes_mrm,
       sum(CASE WHEN n.id_value IS NOT NULL AND v.id_value IS NOT NULL THEN 1 ELSE 0 END) AS en_ambas,
       sum(CASE WHEN n.id_value IS NOT NULL AND v.id_value IS NULL     THEN 1 ELSE 0 END) AS solo_nuevo,
       sum(CASE WHEN n.id_value IS NULL     AND v.id_value IS NOT NULL THEN 1 ELSE 0 END) AS solo_vigente,
       round(100.0 * sum(CASE WHEN n.id_value IS NOT NULL AND v.id_value IS NOT NULL THEN 1 ELSE 0 END)
             / nullif(sum(CASE WHEN v.id_value IS NOT NULL THEN 1 ELSE 0 END), 0), 3)   AS recall_vs_vigente,
       round(100.0 * sum(CASE WHEN n.id_value IS NOT NULL AND v.id_value IS NOT NULL THEN 1 ELSE 0 END)
             / nullif(sum(CASE WHEN n.id_value IS NOT NULL THEN 1 ELSE 0 END), 0), 3)   AS precision_vs_vigente
FROM nuevo n
FULL OUTER JOIN vigente v
     ON v.codmes_mrm = n.codmes_mrm AND v.tip_doc = n.tip_doc AND v.id_value = n.id_value
GROUP BY coalesce(n.codmes_mrm, v.codmes_mrm)
ORDER BY codmes_mrm
