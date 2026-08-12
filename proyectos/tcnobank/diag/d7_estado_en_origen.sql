-- ============================================================================
-- D7. EN QUE ESTADO APARECE LA CUENTA EL MES DEL ALTA
--   scan: ds_adm_vcnbank_tc_cal U e_perm_aws.t_fact_report_rcc_rsk [202401,202412]
--   ancla: flg_tc acepta vencido judicial refinanciado y reestructurado, asi que una
--          primera aparicion no es una originacion. Si malo_ori se concentra en 4 y 5
--          no son altas sino compras de cartera o reanudaciones de reporte
-- ============================================================================
WITH g AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, f_malo_ori, target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean_prod = 1
      AND codmes_mrm BETWEEN '202401' AND '202412'
),
r AS (
    SELECT g.f_malo_ori,
           g.target_12m,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '1' THEN 1 ELSE 0 END)          AS vigente,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) IN ('3','4') THEN 1 ELSE 0 END)   AS ref_ree,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '5' THEN 1 ELSE 0 END)          AS vencido,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '6' THEN 1 ELSE 0 END)          AS judicial,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                     AND substr(a.cod_cuenta_rcc,4,3) = '923' THEN 1 ELSE 0 END)        AS linea_no_util,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                     AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925') THEN 1 ELSE 0 END) AS castigo
    FROM g
    INNER JOIN e_perm_aws.t_fact_report_rcc_rsk a
           ON a.tip_doc = g.tip_doc AND a.key_value = g.id_value
          AND ltrim(rtrim(a.cod_instit_financiera)) = g.entidad
          AND a.p_codmes = g.codmes_mrm
    WHERE a.p_codmes BETWEEN '202401' AND '202412'
    GROUP BY g.codmes_mrm, g.tip_doc, g.id_value, g.entidad, g.f_malo_ori, g.target_12m
)
SELECT CASE WHEN f_malo_ori = 1 THEN '2.malo en el origen' ELSE '1.clean vigente' END   AS grupo,
       CASE WHEN judicial      = 1 THEN '6.judicial'
            WHEN castigo       = 1 THEN '5.castigado'
            WHEN vencido       = 1 THEN '4.vencido'
            WHEN ref_ree       = 1 THEN '3.refinanciado o reestructurado'
            WHEN vigente       = 1 THEN '2.vigente'
            WHEN linea_no_util = 1 THEN '1.solo linea no utilizada'
            ELSE                        '7.otro' END                                    AS estado_en_origen,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY f_malo_ori), 3)         AS pct_del_grupo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                 AS rd_12m
FROM r
GROUP BY 1, 2
ORDER BY 1, 2
