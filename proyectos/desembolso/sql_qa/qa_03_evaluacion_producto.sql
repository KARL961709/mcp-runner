-- qa_03_evaluacion_producto.sql | EVALUACION de la tabla creada b46029_desemb_cal_202609 por producto: volumen, cobertura de pd_raw, cohortes maduras a 12m, RD12 (maduras) y pd_raw medio. Sirve para ver que productos entran limpios a la calibracion y cuales quedan cojos (ej DIGITAL con poco score). READ-ONLY
SELECT desc_producto,
  count(*) AS n,
  round(100.0 * sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END) / count(*), 1) AS pct_pdraw,
  sum(CASE WHEN meses_madurez = 12 THEN 1 ELSE 0 END) AS maduras_12m,
  round(100.0 * avg(CASE WHEN meses_madurez = 12 THEN cast(target_12m AS double) END), 3) AS rd12_pct,
  round(100.0 * avg(CASE WHEN sin_pd = 0 THEN pd_raw END), 3) AS pd_raw_medio_pct
FROM disc_model_owner.b46029_desemb_cal_202609
GROUP BY desc_producto
ORDER BY n DESC
