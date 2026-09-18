-- QA[3] cruce grupos_cal (nuevo) vs grupos_ant (V2 banco), con PD promedio de cada uno
SELECT grupos_cal, grupos_ant, COUNT(*) AS n, ROUND(100*AVG(prob_modelo_cal),2) AS pd_cal, ROUND(100*AVG(pd_v2_esc_opt),2) AS pd_v2
FROM disc_model_owner.admbank_prosp_202608 GROUP BY grupos_cal, grupos_ant ORDER BY grupos_cal, grupos_ant
