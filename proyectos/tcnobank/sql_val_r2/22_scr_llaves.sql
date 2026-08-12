-- 22_scr_llaves.sql | verifica si cod_mes y p_codmes coinciden en el score nuevo, antes de usar p_codmes como mes de score en los cruces
SELECT p_codmes,
       cod_mes,
       count(*)                                                     AS n,
       count(DISTINCT modelo)                                       AS n_modelos,
       count(DISTINCT segmento)                                     AS n_segmentos,
       sum(CASE WHEN prob_model IS NULL THEN 1 ELSE 0 END)          AS sin_prob,
       sum(CASE WHEN puntuacion_cal IS NULL THEN 1 ELSE 0 END)      AS sin_punt_cal,
       sum(CASE WHEN grupo_calibracion IS NULL THEN 1 ELSE 0 END)   AS sin_grupo_cal
FROM e_perm_aws.scr_vcnbank_rsk
WHERE p_codmes IN ('202404', '202504')
GROUP BY p_codmes, cod_mes
ORDER BY p_codmes, cod_mes
