-- cmp_escopt_cov.sql | cobertura de la ENVIADA por p_codmes + avg v2_esc_opt (confirmar 202607/202608). Agregado.
SELECT p_codmes, COUNT(*) AS n, ROUND(100*AVG(TRY_CAST(v2_esc_opt AS DOUBLE)),4) AS pd_v2esc_pct
FROM d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 WHERE p_codmes >= '202606' GROUP BY p_codmes ORDER BY p_codmes
