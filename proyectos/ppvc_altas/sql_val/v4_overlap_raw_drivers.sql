-- =====================================================================================
-- v4 | OVERLAP raw <-> drivers por mes. READ-ONLY.  << LA PRUEBA DE VIABILIDAD 202605 >>
--   Objetivo: por cada mes, cuantos key_value del raw matchean con los drivers.
--   v7 (202606) unia SOLO por key_value; si drivers es de un unico mes, 202605
--   tendra match_cli ~0 -> confirmaria que hay que construir drivers 202605.
--   Si match_cli/raw_cli ~1 en ambos meses, se puede scorear 202605 y 202606 igual.
-- =====================================================================================
SELECT cast(v.p_codmes AS varchar)                 AS p_codmes,
       count(DISTINCT v.key_value)                 AS raw_cli,
       count(DISTINCT dr.key_value)                AS match_cli,
       round(100.0 * count(DISTINCT dr.key_value)
             / nullif(count(DISTINCT v.key_value), 0), 1) AS cob_pct
FROM d_perm_aws.scr_vcadmbnk_hist_rsk v
LEFT JOIN disc_model_owner.pp_vc_drivers_admbnk2 dr ON dr.key_value = v.key_value
WHERE cast(v.p_codmes AS varchar) IN ('202605', '202606')
GROUP BY cast(v.p_codmes AS varchar)
ORDER BY 1
