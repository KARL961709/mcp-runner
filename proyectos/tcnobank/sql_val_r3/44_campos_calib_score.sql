-- 44_campos_calib_score.sql | inspecciona que hay realmente en grupo_calibracion, prob_modelo_cal y puntuacion_cal del score nuevo, porque salieron sin nulos y hay que saber si ya llevan una calibracion aplicada antes de proponer otra
SELECT grupo_calibracion,
       segmento,
       modelo,
       count(*)                                                      AS n,
       round(100.0 * min(TRY_CAST(prob_model AS DOUBLE)), 4)         AS praw_min,
       round(100.0 * avg(TRY_CAST(prob_model AS DOUBLE)), 4)         AS praw_media,
       round(100.0 * max(TRY_CAST(prob_model AS DOUBLE)), 4)         AS praw_max,
       round(100.0 * min(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)    AS pcal_min,
       round(100.0 * avg(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)    AS pcal_media,
       round(100.0 * max(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)    AS pcal_max,
       min(TRY_CAST(puntuacion AS INTEGER))                          AS pt_min,
       max(TRY_CAST(puntuacion AS INTEGER))                          AS pt_max,
       min(TRY_CAST(puntuacion_cal AS INTEGER))                      AS ptcal_min,
       max(TRY_CAST(puntuacion_cal AS INTEGER))                      AS ptcal_max
FROM e_perm_aws.scr_vcnbank_rsk
WHERE p_codmes = '202504'
GROUP BY grupo_calibracion, segmento, modelo
ORDER BY n DESC
LIMIT 40
