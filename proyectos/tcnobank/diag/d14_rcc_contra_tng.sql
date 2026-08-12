-- ============================================================================
-- D14. QUE PIERDE Y QUE GANA LA POBLACION DEL RCC CONTRA TNG_ALTAS
--   scan: ds_adm_vcnbank_tc_cal U tng_altas_ssff_rsk U tng_altas_ibk_rsk [202201,202506]
--   ancla: solo las 5 entidades de alcance. Si las altas que solo ve el RCC tienen la
--          misma rd que las confirmadas, el RCC no esta inventando poblacion y conviene
--          quedarse con una sola fuente para no quebrar la serie en 202201
-- ============================================================================
WITH derivada AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(target_12m)        AS target_12m,
           max(ctrl_malo_ori_m0)  AS malo_ori,
           max(flg_clean)         AS flg_clean
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE codmes_mrm BETWEEN '202201' AND '202506'
      AND entidad IN ('00001','00002','00004','00006','00142')
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
),
oficial AS (
    SELECT p_codmes AS codmes_mrm, tipdoc AS tip_doc, key_value AS id_value,
           ltrim(rtrim(codempresa)) AS entidad
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes BETWEEN '202201' AND '202506'
      AND ltrim(rtrim(codempresa)) IN ('00001','00004','00006','00142')
    UNION
    SELECT p_codmes, ca_tip_doc, key_value, '00002'
    FROM e_perm_aws.tng_altas_ibk_rsk
    WHERE p_codmes BETWEEN '202201' AND '202506'
)
SELECT coalesce(d.entidad, o.entidad)                                                   AS entidad,
       CASE WHEN d.id_value IS NOT NULL AND o.id_value IS NOT NULL THEN '1.en ambas'
            WHEN d.id_value IS NOT NULL                            THEN '2.solo rcc'
            ELSE                                                        '3.solo tng' END AS origen,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY coalesce(d.entidad, o.entidad)), 3) AS pct_de_la_entidad,
       sum(CASE WHEN d.flg_clean = 1  THEN 1 ELSE 0 END)                                AS n_clean,
       sum(CASE WHEN d.flg_clean = 99 THEN 1 ELSE 0 END)                                AS n_scope,
       round(100.0 * avg(CAST(d.target_12m AS DOUBLE)), 4)                              AS rd_12m,
       round(100.0 * avg(CAST(d.malo_ori   AS DOUBLE)), 4)                              AS pct_malo_ori
FROM derivada d
FULL OUTER JOIN oficial o
     ON o.codmes_mrm = d.codmes_mrm AND o.tip_doc = d.tip_doc
    AND o.id_value = d.id_value AND o.entidad = d.entidad
GROUP BY coalesce(d.entidad, o.entidad),
         CASE WHEN d.id_value IS NOT NULL AND o.id_value IS NOT NULL THEN '1.en ambas'
              WHEN d.id_value IS NOT NULL                            THEN '2.solo rcc'
              ELSE                                                        '3.solo tng' END
ORDER BY entidad, origen
