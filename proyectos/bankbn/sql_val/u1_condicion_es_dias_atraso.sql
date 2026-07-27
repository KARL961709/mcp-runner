-- u1_condicion_es_dias_atraso.sql | falsa manifest_N1:70. Si condicion son dias de atraso debe escalonar con la clasificacion SBS; si no escalona, el target esta mal
SELECT cod_clasificacion_deudor                                       AS clasif_sbs,
       count(1)                                                       AS filas,
       count(DISTINCT condicion)                                      AS valores_distintos,
       sum(CASE WHEN TRY_CAST(condicion AS INT) IS NULL THEN 1 ELSE 0 END) AS no_castea,
       min(TRY_CAST(condicion AS INT))                                AS cond_min,
       approx_percentile(TRY_CAST(condicion AS INT), 0.5)             AS cond_p50,
       approx_percentile(TRY_CAST(condicion AS INT), 0.9)             AS cond_p90,
       max(TRY_CAST(condicion AS INT))                                AS cond_max,
       sum(CASE WHEN TRY_CAST(condicion AS INT) > 90 THEN 1 ELSE 0 END) AS n_mayor_90,
       round(100.0 * sum(CASE WHEN TRY_CAST(condicion AS INT) > 90 THEN 1 ELSE 0 END) / count(1), 3) AS pct_mayor_90
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes = '202506'
GROUP BY cod_clasificacion_deudor
ORDER BY clasif_sbs
