-- ============================================================================
-- D18. QUE ES CADA DIGITO DE LA SUBCUENTA 14 EN EL RCC
--   scan: e_perm_aws.t_fact_report_rcc_rsk en 202412, cuenta 14
--   ancla: 05_rcc_agg asigna sld_ref al digito 4 y sld_ree al digito 3 sin que el mapeo
--          se haya medido nunca. f_ree_ori dispara 1 vez en 13.5M filas. La clasificacion
--          del deudor es la columna independiente que dice si el digito es lo que se cree
-- ============================================================================
SELECT substr(a.cod_cuenta_rcc, 1, 6)                                                   AS subcuenta,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 4)                                AS pct,
       count(DISTINCT ltrim(rtrim(a.cod_instit_financiera)))                             AS n_entidades,
       round(100.0 * avg(CASE WHEN TRY_CAST(a.condicion AS INTEGER) > 60
                              THEN 1.0 ELSE 0.0 END), 3)                                 AS pct_mora_mayor_60,
       round(100.0 * avg(CASE WHEN a.cod_clasificacion_deudor = '0'
                              THEN 1.0 ELSE 0.0 END), 3)                                 AS pct_normal,
       round(100.0 * avg(CASE WHEN a.cod_clasificacion_deudor IN ('3','4')
                              THEN 1.0 ELSE 0.0 END), 3)                                 AS pct_dudoso_perdida
FROM e_perm_aws.t_fact_report_rcc_rsk a
WHERE a.p_codmes = '202412'
  AND substr(a.cod_cuenta_rcc, 1, 2) = '14'
  AND a.tipo_credito IN ('11','12')
GROUP BY substr(a.cod_cuenta_rcc, 1, 6)
ORDER BY n DESC
LIMIT 40
