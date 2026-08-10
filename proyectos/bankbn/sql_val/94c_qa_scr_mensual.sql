-- 94c_qa_scr_mensual.sql | el mismo QA pero MES A MES. Un periodo con hueco de fhat o con PD corrida se esconde dentro del agregado. fhat es constante dentro del trimestre por diseno
SELECT p_codmes,
       count(1)                                                                    AS n,
       sum(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)                    AS sin_pd,
       sum(CASE WHEN fhat IS NULL THEN 1 ELSE 0 END)                               AS sin_fhat,
       sum(CASE WHEN prob_modelo_cal <= 0 OR prob_modelo_cal >= 1
                  OR pd_cal <= 0 OR pd_cal >= 1
                  OR rho_i < 0.001 OR rho_i > 0.999
                  OR puntuacion_modelo < 0 OR puntuacion_modelo > 1000 THEN 1 ELSE 0 END) AS fuera_rango,
       sum(CASE WHEN prob_modelo_cal IS NOT NULL
                 AND puntuacion_modelo <> CAST(round((1.0 - prob_modelo_cal) * 1000) AS INTEGER)
                THEN 1 ELSE 0 END)                                                 AS punt_mal,
       round(100.0 * sum(CASE WHEN personeria = 'PJJ' THEN 1 ELSE 0 END) / count(1), 2) AS pjj_pct,
       round(100.0 * avg(prob_modelo), 3)                                          AS raw_pct,
       round(100.0 * avg(prob_modelo_cal), 3)                                      AS cal_pct,
       round(avg(CAST(puntuacion_modelo AS DOUBLE)), 1)                            AS punt_media,
       round(max(fhat), 6)                                                         AS fhat,
       count(DISTINCT fhat)                                                        AS fhat_distintos
FROM disc_model_owner.scr_admbankbpe_calibrado_202607
GROUP BY p_codmes
ORDER BY p_codmes
