-- e1b COBERTURA SCORE
SELECT 'score' AS fuente, MIN(p_codmes) AS mn, MAX(p_codmes) AS mx,
       COUNT(DISTINCT p_codmes) AS meses, COUNT(*) AS filas
FROM e_perm_aws.scr_admbankbpe_rsk
