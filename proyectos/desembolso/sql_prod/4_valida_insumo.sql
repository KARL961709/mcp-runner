-- 4_valida_insumo.sql | valida el insumo final b46029_desemb_cal_202609 por anio: total filas, cuantas con pd_raw (sin_pd=0), cuantas cohortes maduras a 12m, la RD12 observada en las maduras y el pd_raw medio. Sanity antes de calibrar. READ-ONLY
SELECT cast(cod_mes / 100 AS int) AS anio,
  count(*) AS n,
  sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END) AS con_pdraw,
  round(100.0 * sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END) / count(*), 1) AS pct_pdraw,
  sum(CASE WHEN meses_madurez = 12 THEN 1 ELSE 0 END) AS maduras_12m,
  round(100.0 * avg(CASE WHEN meses_madurez = 12 THEN cast(target_12m AS double) END), 3) AS rd12_pct,
  round(100.0 * avg(CASE WHEN sin_pd = 0 THEN pd_raw END), 3) AS pd_raw_medio_pct
FROM disc_model_owner.b46029_desemb_cal_202609
GROUP BY cast(cod_mes / 100 AS int)
ORDER BY anio
