-- ============================================================================
-- D11. LA COLA DE CONDICION ES MORA REAL O UN CENTINELA
--   scan: e_perm_aws.t_fact_report_rcc_rsk en 202412, filas de TC con condicion > 360
--   ancla: d9 da v_max 9999. El target marca malo con condicion > 60, asi que un
--          centinela de sin dato entraria como default
-- ============================================================================
SELECT a.condicion,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 4)                                AS pct_de_la_cola,
       count(DISTINCT ltrim(rtrim(a.cod_instit_financiera)))                             AS n_entidades,
       sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81' THEN 1 ELSE 0 END)              AS n_contingente,
       sum(CASE WHEN a.cod_clasificacion_deudor = '4' THEN 1 ELSE 0 END)                 AS n_perdida
FROM e_perm_aws.t_fact_report_rcc_rsk a
WHERE a.p_codmes = '202412'
  AND substr(a.cod_cuenta_rcc,1,2) = '14'
  AND a.tipo_credito IN ('11','12')
  AND TRY_CAST(a.condicion AS INTEGER) > 360
GROUP BY a.condicion
ORDER BY n DESC
LIMIT 30
