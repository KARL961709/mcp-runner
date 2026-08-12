-- ============================================================================
-- D13. PERFIL DEL ALTA POR ENTIDAD - SALDO USADO CONTRA LINEA NO UTILIZADA
--   scan: ds_adm_vcnbank_tc_cal U e_perm_aws.t_fact_report_rcc_rsk [202401,202412]
--   ancla: d7 muestra que 48 por ciento de las altas aparecen solo como linea
--          contingente y su rd es un tercio. saldo_tc de 05_rcc_agg suma 14-x junto con
--          81-923, asi que prelacion_sld ordena mezclando deuda con linea disponible
-- ============================================================================
WITH b AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(ctrl_malo_ori_m0) AS malo_ori,
           max(target_12m)       AS target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
      AND codmes_mrm BETWEEN '202401' AND '202412'
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
),
r AS (
    SELECT b.entidad,
           b.malo_ori,
           b.target_12m,
           sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14' THEN a.saldo ELSE 0 END)   AS sld_usado,
           sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                     AND substr(a.cod_cuenta_rcc,4,3) = '923' THEN a.saldo ELSE 0 END)  AS sld_linea
    FROM b
    INNER JOIN e_perm_aws.t_fact_report_rcc_rsk a
           ON a.tip_doc = b.tip_doc AND a.key_value = b.id_value
          AND ltrim(rtrim(a.cod_instit_financiera)) = b.entidad
          AND a.p_codmes = b.codmes_mrm
    WHERE a.p_codmes BETWEEN '202401' AND '202412'
    GROUP BY b.codmes_mrm, b.tip_doc, b.id_value, b.entidad, b.malo_ori, b.target_12m
)
SELECT entidad,
       CASE WHEN sld_usado > 0 THEN '2.con saldo usado' ELSE '1.solo linea no utilizada' END AS perfil,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY entidad), 3)           AS pct_de_la_entidad,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(CAST(malo_ori AS DOUBLE)), 4)                                  AS pct_malo_ori,
       round(avg(sld_usado), 0)                                                          AS sld_usado_medio,
       round(avg(sld_linea), 0)                                                          AS sld_linea_medio
FROM r
GROUP BY entidad,
         CASE WHEN sld_usado > 0 THEN '2.con saldo usado' ELSE '1.solo linea no utilizada' END
ORDER BY entidad, perfil
