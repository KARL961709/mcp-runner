-- a98. Perfil por codmes: n, nulls de pd_raw vs pd_cal (deben coincidir), medias de la PD calibrada.
SELECT codmes, COUNT(*) AS n,
  SUM(CASE WHEN pd_raw IS NULL THEN 1 ELSE 0 END) AS pd_raw_null,
  SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS pd_cal_null,
  ROUND(AVG(prob_modelo_cal_ppfacil), 5) AS pd_facil,
  ROUND(AVG(prob_modelo_cal_ppcd), 5) AS pd_cd
FROM disc_model_owner.altas_adm_pp_cdpp_cal
GROUP BY codmes
ORDER BY codmes