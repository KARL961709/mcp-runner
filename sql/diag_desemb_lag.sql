-- diag_desemb_lag.sql | desfase REAL del cruce: cod_mes (mes desembolso) vs pd_codmes (periodo del score cruzado) y lag_meses, en b46029_desemb_cal_202609. Si lag_meses=0 => pd_codmes=cod_mes (score del mismo mes). Si lag_meses>=1 => el score va adelantado. Read-only, agregado.
SELECT cod_mes, pd_codmes, lag_meses,
  COUNT(*) AS n,
  SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_conpd
FROM disc_model_owner.b46029_desemb_cal_202609
WHERE cod_mes BETWEEN 202603 AND 202608
GROUP BY cod_mes, pd_codmes, lag_meses
ORDER BY cod_mes, pd_codmes
