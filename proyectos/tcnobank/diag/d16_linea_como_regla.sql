-- ============================================================================
-- D16. LA LINEA DE CREDITO COMO REGLA ESTRUCTURAL DE ORIGINACION
--   scan: cal U tng_altas [202201,202506] U t_fact_report_rcc_rsk en codmes
--   ancla: un alta real trae linea 81-923. Las que tng no reconoce llegan con saldo 32
--          contra 10,004, o sea resto en 14-x sin linea. 81-923 existe en los 88 meses
--          asi que la regla no depende de tng. Se mide precision y recall contra en_tng
-- ============================================================================
WITH d AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(ctrl_malo_ori_m0) AS malo_ori,
           max(target_12m)       AS target_12m,
           max(flg_clean)        AS flg_clean
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE codmes_mrm BETWEEN '202201' AND '202506'
      AND entidad IN ('00001','00006')
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
),
o AS (
    SELECT p_codmes AS codmes_mrm, tipdoc AS tip_doc, key_value AS id_value,
           ltrim(rtrim(codempresa)) AS entidad
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes BETWEEN '202201' AND '202506'
      AND ltrim(rtrim(codempresa)) IN ('00001','00006')
),
x AS (
    SELECT d.entidad,
           d.malo_ori,
           d.target_12m,
           d.flg_clean,
           CASE WHEN o.id_value IS NOT NULL THEN 1 ELSE 0 END                           AS en_tng,
           sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                     AND substr(a.cod_cuenta_rcc,4,3) = '923' THEN a.saldo ELSE 0 END)  AS sld_linea,
           sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14' THEN a.saldo ELSE 0 END)   AS sld_usado
    FROM d
    LEFT JOIN o
           ON o.codmes_mrm = d.codmes_mrm AND o.tip_doc = d.tip_doc
          AND o.id_value = d.id_value AND o.entidad = d.entidad
    INNER JOIN e_perm_aws.t_fact_report_rcc_rsk a
           ON a.tip_doc = d.tip_doc AND a.key_value = d.id_value
          AND ltrim(rtrim(a.cod_instit_financiera)) = d.entidad
          AND a.p_codmes = d.codmes_mrm
    WHERE a.p_codmes BETWEEN '202201' AND '202506'
    GROUP BY d.codmes_mrm, d.tip_doc, d.id_value, d.entidad, d.malo_ori,
             d.target_12m, d.flg_clean, CASE WHEN o.id_value IS NOT NULL THEN 1 ELSE 0 END
)
SELECT entidad,
       en_tng,
       CASE WHEN sld_linea > 0 THEN '1.con linea' ELSE '2.sin linea' END                AS regla_linea,
       malo_ori,
       count(*)                                                                         AS n,
       sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                                   AS n_clean,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(avg(sld_linea), 0)                                                          AS linea_media,
       round(avg(sld_usado), 0)                                                          AS usado_medio
FROM x
GROUP BY entidad, en_tng,
         CASE WHEN sld_linea > 0 THEN '1.con linea' ELSE '2.sin linea' END,
         malo_ori
ORDER BY entidad, en_tng, regla_linea, malo_ori
