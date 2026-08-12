-- 05_rcc_agg_t03.sql | colapsa el RCC al grano cliente x entidad x mes con las medidas que los 20 filtros
-- y el target necesitan, para que ningun paso posterior vuelva a escanear 114 particiones de 60M filas.
-- Tramo 3 de 10 (201901 a 201912). Fuente por el mapa R9 medido con la q62, que probo que las dos copias del RCC
-- coinciden al decimal en el solape: d_perm [201701,201812] y e_perm [201901,202606]. Ningun tramo cruza
-- esa frontera, asi la fuente sale del mapa y no de una asignacion a mano.
INSERT INTO disc_model_owner.ds_adm_tcnb_05_rcc_agg
SELECT a.tip_doc,
       a.key_value,
       ltrim(rtrim(a.cod_instit_financiera))                                          AS entidad,
       max(CASE WHEN (    (    substr(a.cod_cuenta_rcc,1,2) = '14'
              AND a.tipo_credito IN ('11','12')
              AND (   substr(a.cod_cuenta_rcc,4,7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                       '6030202','1030209','5030209','6030209','5031902',
                                                       '1030203','5030203','6030203','1030613','4030613',
                                                       '5030613','6030613','5031908','6031908','5031998','6031998')
                   OR substr(a.cod_cuenta_rcc,4,5) IN ('10304','40304','50304','60304','40302',
                                                       '10308','40308','50308','60308') ) )
         OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923') ) THEN 1 ELSE 0 END)                                        AS flg_tc,
       max(CASE WHEN (    (    substr(a.cod_cuenta_rcc,1,2) = '14'
              AND a.tipo_credito IN ('11','12')
              AND (   substr(a.cod_cuenta_rcc,4,7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                       '6030202','1030209','5030209','6030209','5031902',
                                                       '1030203','5030203','6030203','1030613','4030613',
                                                       '5030613','6030613','5031908','6031908','5031998','6031998')
                   OR substr(a.cod_cuenta_rcc,4,5) IN ('10304','40304','50304','60304','40302',
                                                       '10308','40308','50308','60308') ) )
         OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923') ) THEN a.condicion END)                                     AS dm_tc,
       sum(CASE WHEN (    (    substr(a.cod_cuenta_rcc,1,2) = '14'
              AND a.tipo_credito IN ('11','12')
              AND (   substr(a.cod_cuenta_rcc,4,7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                       '6030202','1030209','5030209','6030209','5031902',
                                                       '1030203','5030203','6030203','1030613','4030613',
                                                       '5030613','6030613','5031908','6031908','5031998','6031998')
                   OR substr(a.cod_cuenta_rcc,4,5) IN ('10304','40304','50304','60304','40302',
                                                       '10308','40308','50308','60308') ) )
         OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923') ) THEN a.saldo END)                                         AS saldo_tc,
       sum(CASE WHEN ( (   (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923')
                        OR (substr(a.cod_cuenta_rcc,1,2) || '0' || substr(a.cod_cuenta_rcc,4,3) = '720506')
                        OR (substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                        OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925')) )
                       AND a.tipo_credito IN ('11','12','13') )
                    OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925')
                        AND a.tipo_credito = '99')
                THEN a.saldo END)                                                     AS sld_bank,
       sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                 AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925') THEN a.saldo END)  AS monto_cast,
       sum(CASE WHEN ( (substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) = '4')
                     OR (substr(a.cod_cuenta_rcc,1,2) || '0' || substr(a.cod_cuenta_rcc,4,1) IN ('1405','1406')
                         AND substr(a.cod_cuenta_rcc,7,2) = '19') )
                 AND a.cod_clasificacion_deudor <> '8' THEN a.saldo END)              AS sld_ref,
       sum(CASE WHEN ( (substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) = '3')
                     OR (substr(a.cod_cuenta_rcc,1,2) || '0' || substr(a.cod_cuenta_rcc,4,1) IN ('1405','1406')
                         AND substr(a.cod_cuenta_rcc,7,2) = '22') )
                 AND a.cod_clasificacion_deudor <> '8' THEN a.saldo END)              AS sld_ree,
       sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) = '6'
                 AND a.cod_clasificacion_deudor <> '8' THEN a.saldo END)              AS sld_jud,
       max(a.cod_clasificacion_deudor)                                                AS clasif_max,
       max(CASE WHEN a.tipo_credito NOT IN ('11','12','13','99') THEN 1 ELSE 0 END)   AS flg_no_consumo,
       a.p_codmes                                                                     AS codmes
FROM e_perm_aws.t_fact_report_rcc_rsk a
WHERE a.p_codmes BETWEEN '201901' AND '201912'
GROUP BY a.tip_doc, a.key_value, ltrim(rtrim(a.cod_instit_financiera)), a.p_codmes
