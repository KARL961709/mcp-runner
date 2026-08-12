-- 06_rcc_agg_t06.sql | capa agregada del RCC al grano cliente x entidad x mes, tramo 6 de 10 (202201-202212). Colapsa el RCC a las medidas que los 20 filtros y el target necesitan, para que ningun paso siguiente vuelva a escanearlo. Fuente por R9: e_perm_aws.t_fact_report_rcc_rsk
INSERT INTO disc_model_owner.ds_tcnobank_rcc_agg_v1
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
         OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923') ) THEN a.condicion END)                                       AS dm_tc,
       sum(CASE WHEN (    (    substr(a.cod_cuenta_rcc,1,2) = '14'
              AND a.tipo_credito IN ('11','12')
              AND (   substr(a.cod_cuenta_rcc,4,7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                       '6030202','1030209','5030209','6030209','5031902',
                                                       '1030203','5030203','6030203','1030613','4030613',
                                                       '5030613','6030613','5031908','6031908','5031998','6031998')
                   OR substr(a.cod_cuenta_rcc,4,5) IN ('10304','40304','50304','60304','40302',
                                                       '10308','40308','50308','60308') ) )
         OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923') ) THEN a.saldo END)                                           AS saldo_tc,
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
WHERE a.p_codmes BETWEEN '202201' AND '202212'
GROUP BY a.p_codmes, a.tip_doc, a.key_value, ltrim(rtrim(a.cod_instit_financiera))
