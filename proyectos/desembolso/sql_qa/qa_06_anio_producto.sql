-- qa_06_anio_producto.sql | LA PREGUNTA: la RD cae de 14.2 a 5.0 entre 2023 y 2025. Es que el
-- libro mejoro, o es que cambio la MEZCLA de productos. IMPULSO y DIGITAL tienen RD muy distintas,
-- asi que un cambio de peso entre ellos mueve el agregado sin que ningun producto cambie. Este
-- corte separa las dos cosas. Poblacion calibrable (madura Y con score). READ-ONLY
SELECT cast(cod_mes / 100 AS int)                                                       AS anio,
  desc_producto,
  count(*)                                                                              AS n,
  round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY cast(cod_mes / 100 AS int)), 1) AS pct_del_anio,
  round(100.0 * avg(cast(target_12m AS double)), 3)                                     AS rd12_pct,
  round(100.0 * avg(pd_raw), 3)                                                         AS pd_raw_pct,
  round(avg(cast(target_12m AS double)) / nullif(avg(pd_raw), 0), 3)                    AS factor_rd_pd
FROM disc_model_owner.b46029_desemb_cal_202609
WHERE meses_madurez = 12
  AND sin_pd = 0
GROUP BY cast(cod_mes / 100 AS int), desc_producto
ORDER BY anio, n DESC
