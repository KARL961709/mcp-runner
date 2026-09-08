-- qa_02_evaluacion.sql | EVALUACION de la tabla creada b46029_desemb_cal_202609 por anio de cohorte: volumen, cobertura de pd_raw, cohortes maduras a 12m (meses_madurez=12, con la frontera RCC real), RD12 observada SOLO en maduras, pd_raw medio, y el factor implicito rd12/pd_raw (sanity de calibracion). READ-ONLY
SELECT cast(cod_mes / 100 AS int) AS anio,
  count(*) AS n,
  round(100.0 * sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END) / count(*), 1) AS pct_pdraw,
  sum(CASE WHEN meses_madurez = 12 THEN 1 ELSE 0 END) AS maduras_12m,
  round(100.0 * avg(CASE WHEN meses_madurez = 12 THEN cast(target_12m AS double) END), 3) AS rd12_pct,
  round(100.0 * avg(CASE WHEN sin_pd = 0 THEN pd_raw END), 3) AS pd_raw_medio_pct,
  round(sum(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN cast(target_12m AS double) END)
      / nullif(sum(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN pd_raw END), 0), 3) AS factor_rd_pd
FROM disc_model_owner.b46029_desemb_cal_202609
GROUP BY cast(cod_mes / 100 AS int)
ORDER BY anio
