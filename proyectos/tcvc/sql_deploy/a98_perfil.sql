-- a98. Perfil por codmes: nulls pd_raw vs pd_cal deben coincidir; media pd_cal.
SELECT codmes, COUNT(*) AS n,
  SUM(CASE WHEN pd_raw IS NULL THEN 1 ELSE 0 END) AS pd_raw_null,
  SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END) AS pd_cal_null,
  ROUND(AVG(prob_modelo_cal), 5) AS pd_cal
FROM disc_model_owner.altas_adm_tcbank_cal
GROUP BY codmes ORDER BY codmes