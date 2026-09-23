-- escopt_diag_escopt.sql | que es scr_admbankbpe_calibrado_202607_escopt: max p_codmes, columnas clave, cobertura reciente. Agregado.
SELECT p_codmes, COUNT(*) AS n, ROUND(AVG(TRY_CAST(prob_modelo_cal AS DOUBLE)),6) AS avg_pmcal
FROM disc_model_owner.scr_admbankbpe_calibrado_202607_escopt
WHERE p_codmes >= '202605' GROUP BY p_codmes ORDER BY p_codmes
