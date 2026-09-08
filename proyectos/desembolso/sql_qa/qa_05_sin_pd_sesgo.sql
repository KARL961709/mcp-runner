-- qa_05_sin_pd_sesgo.sql | LA PREGUNTA: tener score, es aleatorio. Si los que no tienen pd_raw
-- son mas riesgosos, calibrar solo sobre los que si lo tienen subestima el libro, y el sesgo NO
-- lo arregla ningun calibrador. Se mide sobre cohortes maduras, que es donde hay target, partido
-- por anio porque de qa_02 se deduce que el signo cambia entre 2023 y 2024. READ-ONLY
SELECT cast(cod_mes / 100 AS int)                                                       AS anio,
  sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END)                                           AS n_con_pd,
  sum(CASE WHEN sin_pd = 1 THEN 1 ELSE 0 END)                                           AS n_sin_pd,
  round(100.0 * avg(CASE WHEN sin_pd = 0 THEN cast(target_12m AS double) END), 3)       AS rd_con_pd,
  round(100.0 * avg(CASE WHEN sin_pd = 1 THEN cast(target_12m AS double) END), 3)       AS rd_sin_pd,
  round(100.0 * (avg(CASE WHEN sin_pd = 1 THEN cast(target_12m AS double) END)
               - avg(CASE WHEN sin_pd = 0 THEN cast(target_12m AS double) END)), 3)     AS dif_pp,
  round(avg(CASE WHEN sin_pd = 0 THEN cast(lag_meses AS double) END), 2)                AS lag_medio,
  count(DISTINCT CASE WHEN sin_pd = 1 THEN desc_producto END)                           AS productos_sin_pd
FROM disc_model_owner.b46029_desemb_cal_202609
WHERE meses_madurez = 12
GROUP BY cast(cod_mes / 100 AS int)
ORDER BY anio
