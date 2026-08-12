-- ============================================================================
-- 88. EQUIVALENCIA DEL TARGET CONTRA LA CASCADA VIGENTE
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal U e_perm_aws.ds_flg_admtcnobk1_rsk, solape [202303,202606]
--   ancla: matriz de target_12m contra dsc_flg_malo_12m. La celda MALO nuevo sobre no-BUENO/MALO
--          vigente es la fuga de 2,576 defaults que la cascada pierde por evaluar la zona gris
--          antes del evento duro
-- ============================================================================
WITH nuevo AS (
    SELECT codmes_mrm, tip_doc, id_value, target_12m, max_dm_fut, f_evento_fut
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE prelacion_cod = 1
      AND codmes_mrm BETWEEN '202303' AND '202606'
),
vigente AS (
    SELECT codmes_mrm, tip_doc, id_value, dsc_flg_malo_12m
    FROM e_perm_aws.ds_flg_admtcnobk1_rsk
    WHERE prelacion_00m = 1
      AND codmes_mrm BETWEEN '202303' AND '202606'
)
SELECT CASE WHEN n.target_12m = 1    THEN '1.MALO nuevo'
            WHEN n.target_12m = 0    THEN '2.BUENO nuevo'
            WHEN n.id_value IS NULL  THEN '4.no esta en el nuevo'
            ELSE                          '3.NULL nuevo' END                           AS lado_nuevo,
       CASE WHEN v.dsc_flg_malo_12m = 'MALO'  THEN '1.MALO vigente'
            WHEN v.dsc_flg_malo_12m = 'BUENO' THEN '2.BUENO vigente'
            WHEN v.id_value IS NULL           THEN '4.no esta en el vigente'
            ELSE                                   '3.excluido vigente: ' || v.dsc_flg_malo_12m END AS lado_vigente,
       count(*)                                                                        AS n,
       sum(CASE WHEN n.max_dm_fut > 60 THEN 1 ELSE 0 END)                              AS con_mora_mayor_60,
       sum(CASE WHEN n.f_evento_fut = 1 THEN 1 ELSE 0 END)                             AS con_evento_duro
FROM nuevo n
FULL OUTER JOIN vigente v
     ON v.codmes_mrm = n.codmes_mrm AND v.tip_doc = n.tip_doc AND v.id_value = n.id_value
GROUP BY 1, 2
ORDER BY n DESC
LIMIT 60
