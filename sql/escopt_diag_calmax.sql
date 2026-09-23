-- escopt_diag_calmax.sql | max p_codmes y cobertura reciente del calibrado _202607 (para saber hasta donde llega la vintage vigente). Agregado.
SELECT p_codmes, COUNT(*) AS n FROM disc_model_owner.scr_admbankbpe_calibrado_202607
WHERE p_codmes >= '202606' GROUP BY p_codmes ORDER BY p_codmes
