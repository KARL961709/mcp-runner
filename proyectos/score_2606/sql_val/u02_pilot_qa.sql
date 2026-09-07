-- u02 pilot QA: perfil del scoreado (PD en [0,1], puntuacion 0-1000, medias por modelo, nulls).
SELECT COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_ppfacil), 4) AS pd_ppf,
  ROUND(AVG(prob_modelo_cal_ppcd), 4)    AS pd_ppcd,
  ROUND(AVG(prob_modelo_cal_ec), 4)      AS pd_ec,
  ROUND(AVG(prob_modelo_cal_tcbnk), 4)   AS pd_tc,
  ROUND(MIN(prob_modelo_cal_ec), 4) AS min_pd_ec, ROUND(MAX(prob_modelo_cal_ec), 4) AS max_pd_ec,
  MIN(puntuacion_modelo_cal_ec) AS min_punt_ec, MAX(puntuacion_modelo_cal_ec) AS max_punt_ec,
  SUM(CASE WHEN prob_modelo_cal_ec IS NULL THEN 1 ELSE 0 END) AS ec_null,
  SUM(CASE WHEN prob_modelo_cal_tcbnk IS NULL THEN 1 ELSE 0 END) AS tc_null
FROM disc_model_owner.univ_vc_scored_pilot
