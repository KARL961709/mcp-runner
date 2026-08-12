-- ============================================================================
-- 89. VALIDA LA POBLACION DERIVADA CONTRA TNG_ALTAS
--   scan: __T___10_po U tng_altas_ssff_rsk U tng_altas_ibk_rsk [202201,202605]
--   ancla: tng_altas solo existe desde 202201, asi que el contraste cubre 52 de los 88 meses
-- ============================================================================
WITH derivada AS (
    SELECT codmes_mrm AS codmes, tip_doc, id_value, entidad
    FROM disc_model_owner.ds_adm_vcnbank_tc_10_po
    WHERE codmes_mrm >= '202201'
),
oficial AS (
    SELECT p_codmes AS codmes, tipdoc AS tip_doc, key_value AS id_value,
           ltrim(rtrim(codempresa)) AS entidad
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes BETWEEN '202201' AND '202605' AND ltrim(rtrim(codempresa)) <> '00002'
    UNION
    SELECT p_codmes, ca_tip_doc, key_value, '00002'
    FROM e_perm_aws.tng_altas_ibk_rsk
    WHERE p_codmes BETWEEN '202201' AND '202605'
),
cruce AS (
    SELECT coalesce(d.entidad, o.entidad)                                              AS entidad,
           CASE WHEN d.id_value IS NOT NULL AND o.id_value IS NOT NULL THEN 1 ELSE 0 END AS en_ambas,
           CASE WHEN d.id_value IS NOT NULL AND o.id_value IS NULL     THEN 1 ELSE 0 END AS solo_rcc,
           CASE WHEN d.id_value IS NULL     AND o.id_value IS NOT NULL THEN 1 ELSE 0 END AS solo_tng
    FROM derivada d
    FULL OUTER JOIN oficial o
         ON d.codmes = o.codmes AND d.tip_doc = o.tip_doc
        AND d.id_value = o.id_value AND d.entidad = o.entidad
)
SELECT c.entidad,
       e.nombre_instit_financiera,
       CAST(CASE WHEN c.entidad IN ('00001','00002','00004','00006','00142')
                 THEN 1 ELSE 0 END AS INTEGER)                                         AS es_entidad_po,
       sum(c.en_ambas)                                                                 AS en_ambas,
       sum(c.solo_rcc)                                                                 AS solo_rcc,
       sum(c.solo_tng)                                                                 AS solo_tng,
       round(100.0 * sum(c.en_ambas) / nullif(sum(c.en_ambas) + sum(c.solo_tng), 0), 3) AS recall_pct,
       round(100.0 * sum(c.en_ambas) / nullif(sum(c.en_ambas) + sum(c.solo_rcc), 0), 3) AS precision_pct
FROM cruce c
LEFT JOIN e_perm_aws.t_dim_inst_fin_rsk e
       ON ltrim(rtrim(e.cod_instit_financiera)) = c.entidad
GROUP BY c.entidad, e.nombre_instit_financiera
ORDER BY en_ambas DESC
LIMIT 40
