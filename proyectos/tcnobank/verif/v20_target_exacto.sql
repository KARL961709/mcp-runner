-- ============================================================================
-- V20. MATRIZ EXACTA DEL TARGET CONTRA LA CASCADA VIGENTE
--   scan: __T___cal U e_perm_aws.ds_flg_admtcnobk1_rsk, solape [202303,202606]
--   ancla: 88_qa ordena por n y corta en 60 filas, asi que las celdas de desacuerdo
--          quedan fuera del ranking y su ausencia se INFIERE. Aca se recorta el lado
--          vigente a BUENO y MALO, que es su poblacion modelable, y se reportan las
--          seis celdas sin LIMIT: no hay nada que se pueda esconder por truncamiento
--   dsc_flg_malo_12m es la cascada TC No Bank a nivel ENTIDAD. No es TARGET60_12_VC,
--          que es Vision Cliente a nivel cliente y mide otra cosa
-- ============================================================================
WITH vigente AS (
    SELECT codmes_mrm, tip_doc, id_value, dsc_flg_malo_12m
    FROM e_perm_aws.ds_flg_admtcnobk1_rsk
    WHERE prelacion_00m = 1
      AND dsc_flg_malo_12m IN ('BUENO','MALO')
      AND codmes_mrm BETWEEN '202303' AND '202606'
),
nuevo AS (
    SELECT codmes_mrm, tip_doc, id_value, target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE prelacion_cod = 1
      AND codmes_mrm BETWEEN '202303' AND '202606'
)
SELECT substr(v.codmes_mrm, 1, 4)                                                       AS anio,
       v.dsc_flg_malo_12m                                                               AS vigente,
       CASE WHEN n.id_value  IS NULL THEN '3.no esta en el nuevo'
            WHEN n.target_12m IS NULL THEN '2.NULL'
            WHEN n.target_12m = 1     THEN '1.MALO'
            ELSE                           '0.BUENO' END                                AS nuestro,
       count(*)                                                                         AS n
FROM vigente v
LEFT JOIN nuevo n
       ON n.codmes_mrm = v.codmes_mrm AND n.tip_doc = v.tip_doc AND n.id_value = v.id_value
GROUP BY substr(v.codmes_mrm, 1, 4), v.dsc_flg_malo_12m,
         CASE WHEN n.id_value  IS NULL THEN '3.no esta en el nuevo'
              WHEN n.target_12m IS NULL THEN '2.NULL'
              WHEN n.target_12m = 1     THEN '1.MALO'
              ELSE                           '0.BUENO' END
ORDER BY anio, vigente, nuestro
