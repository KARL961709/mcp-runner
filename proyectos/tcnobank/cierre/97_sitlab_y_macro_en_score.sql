-- 97_sitlab_y_macro_en_score.sql | mapea el segmento y el driver tal como los LEE la calibracion vigente. tip_situacion_laboral define cual de los dos arboles aplica: 1.DEP_VAL contra el resto. Y las tres variables macro son las entradas de esos arboles, asi que hay que ver su cobertura y si el valor viaja igual en todos los registros del mes
SELECT p_codmes,
       coalesce(tip_situacion_laboral, 'NULL')                                             AS tip_situacion_laboral,
       CASE WHEN tip_situacion_laboral = '1.DEP_VAL' THEN 'arbol dep_val'
            ELSE 'arbol no_dep_val' END                                                    AS arbol_que_aplica,
       count(*)                                                                            AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY p_codmes), 3)             AS pct_mes,
       count(DISTINCT rat_expect_inflacion)                                                AS n_val_inflacion,
       count(DISTINCT rat_tasa_desempleo)                                                  AS n_val_desempleo,
       count(DISTINCT rat_tasa_desempleo_6)                                                AS n_val_desempleo6,
       round(avg(TRY_CAST(rat_expect_inflacion AS DOUBLE)), 5)                             AS inflacion,
       round(avg(TRY_CAST(rat_tasa_desempleo AS DOUBLE)), 5)                               AS desempleo,
       round(avg(TRY_CAST(rat_tasa_desempleo_6 AS DOUBLE)), 5)                             AS desempleo_6,
       sum(CASE WHEN rat_expect_inflacion IS NULL THEN 1 ELSE 0 END)                        AS sin_inflacion,
       round(100.0 * avg(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)                          AS pd_calibrada_vig,
       round(100.0 * avg(TRY_CAST(prob_model AS DOUBLE)), 4)                               AS pd_cruda
FROM e_perm_aws.scr_vcnbank_rsk
WHERE p_codmes IN ('202312', '202406', '202412', '202506')
GROUP BY p_codmes, tip_situacion_laboral
ORDER BY p_codmes, n DESC
