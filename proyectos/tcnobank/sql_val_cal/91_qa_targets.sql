-- ============================================================================
-- 91. CONTROLES DEL TARGET POR CODMES - RANGO MADUREZ MONOTONIA Y CROSS-CHECK
-- ============================================================================
SELECT codmes_mrm,
       count(*)                                                                        AS n_magnitud,
       sum(CASE WHEN target_01m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_02m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_03m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_04m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_05m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_06m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_07m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_08m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_09m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_10m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_11m NOT IN (0,1) THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_12m NOT IN (0,1) THEN 1 ELSE 0 END) +
       0                                                                               AS falla_rango,
       sum(CASE WHEN date_format(date_add('month', 1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_01m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_01m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_02m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_02m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 3, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_03m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 3, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_03m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 4, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_04m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 4, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_04m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 5, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_05m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 5, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_05m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 6, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_06m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 6, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_06m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 7, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_07m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 7, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_07m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 8, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_08m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 8, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_08m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 9, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_09m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 9, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_09m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 10, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_10m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 10, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_10m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 11, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_11m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 11, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_11m IS NULL     THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' AND target_12m IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') <= '202606' AND target_12m IS NULL     THEN 1 ELSE 0 END) +
       0                                                                               AS falla_madurez,
       sum(CASE WHEN target_01m > target_02m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_02m > target_03m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_03m > target_04m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_04m > target_05m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_05m > target_06m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_06m > target_07m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_07m > target_08m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_08m > target_09m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_09m > target_10m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_10m > target_11m THEN 1 ELSE 0 END) +
       sum(CASE WHEN target_11m > target_12m THEN 1 ELSE 0 END) +
       0                                                                               AS falla_monotonia,
       sum(CASE WHEN max_dm_fut > 60 AND target_12m = 0 THEN 1 ELSE 0 END)             AS falla_mora_no_marcada,
       sum(CASE WHEN f_evento_fut = 1 AND target_12m = 0 THEN 1 ELSE 0 END)            AS falla_evento_no_marcado
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
GROUP BY codmes_mrm
ORDER BY codmes_mrm
