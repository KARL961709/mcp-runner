-- diag_desemb_lagdist.sql | distribucion global de lag_meses (desfase cod_mes vs score) en b46029_desemb_cal_202609, solo cruzados. Muestra si el desfase es consistente (1 valor dominante) o mezclado. Read-only, agregado.
SELECT lag_meses,
  COUNT(*) AS n,
  ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (), 1) AS pct
FROM disc_model_owner.b46029_desemb_cal_202609
WHERE pd_raw IS NOT NULL
GROUP BY lag_meses
ORDER BY lag_meses
