-- escopt_diag_rsk.sql | cobertura de la fuente madre scr_admbankbpe_rsk por p_codmes (202606+): ver si 202609 ya cargo. Agregado.
SELECT p_codmes, COUNT(*) AS n, COUNT(DISTINCT key_value) AS n_cli
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE modelo='ADMBANKBPE' AND probabilidad IS NOT NULL AND p_codmes >= '202606'
GROUP BY p_codmes ORDER BY p_codmes
