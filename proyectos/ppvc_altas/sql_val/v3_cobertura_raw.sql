-- =====================================================================================
-- v3 | COBERTURA de la fuente RAW por mes (202604-202606). READ-ONLY.
--   Objetivo: confirmar que 202605 y 202606 existen con volumen y probabilidad
--   valida (no todo null / no dominado por un valor). Si 202605 sale flaco o
--   vacio, el CSV de control ya avisaba (source distinto, cobertura 82.7%).
--   NOTA: si 'probabilidad' o 'p_codmes' no son los nombres exactos, este query
--   falla y v1 (esquema) nos da los nombres reales para la vuelta siguiente.
-- =====================================================================================
SELECT cast(p_codmes AS varchar)        AS p_codmes,
       count(*)                         AS filas,
       count(DISTINCT key_value)        AS n_cli,
       round(avg(probabilidad), 4)      AS pd_raw_prom,
       round(min(probabilidad), 4)      AS p_min,
       round(max(probabilidad), 4)      AS p_max
FROM d_perm_aws.scr_vcadmbnk_hist_rsk
WHERE cast(p_codmes AS varchar) IN ('202604', '202605', '202606')
GROUP BY cast(p_codmes AS varchar)
ORDER BY 1
