-- k02 VENTANA de admision contando filas -- confirma que 202607 tiene dato y con que volumen
SELECT p_codmes,
       count(*)                  AS n_filas,
       count(DISTINCT key_value) AS n_personas
FROM d_perm_aws.scr_vcadmbnk_hist_rsk
WHERE p_codmes >= '202601'
GROUP BY p_codmes
ORDER BY p_codmes
