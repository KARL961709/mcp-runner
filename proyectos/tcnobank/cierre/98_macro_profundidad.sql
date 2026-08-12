-- 98_macro_profundidad.sql | profundidad y nivel de la tabla macro que alimenta los dos arboles de la calibracion vigente. Si no llega tan atras como el target largo, el modelo macro no se puede reestimar sobre la ventana ampliada y el driver queda atado a la serie corta. Los cortes de los arboles vigentes son inflacion 3.79531 y 4.23125, desempleo 6.59460 y desempleo 6m 7.11899: interesa ver cuantos anios caen a cada lado
SELECT substr(CAST(cod_mes AS VARCHAR), 1, 4)                                    AS anio,
       count(*)                                                                  AS meses,
       min(CAST(cod_mes AS VARCHAR))                                             AS codmes_min,
       max(CAST(cod_mes AS VARCHAR))                                             AS codmes_max,
       round(avg(TRY_CAST(rat_expect_inflacion AS DOUBLE)), 4)                   AS inflacion_prom,
       round(min(TRY_CAST(rat_expect_inflacion AS DOUBLE)), 4)                   AS inflacion_min,
       round(max(TRY_CAST(rat_expect_inflacion AS DOUBLE)), 4)                   AS inflacion_max,
       round(avg(TRY_CAST(rat_tasa_desempleo AS DOUBLE)), 4)                     AS desempleo_prom,
       round(min(TRY_CAST(rat_tasa_desempleo AS DOUBLE)), 4)                     AS desempleo_min,
       round(max(TRY_CAST(rat_tasa_desempleo AS DOUBLE)), 4)                     AS desempleo_max,
       sum(CASE WHEN TRY_CAST(rat_expect_inflacion AS DOUBLE) > 4.23125 THEN 1 ELSE 0 END)  AS meses_infl_sobre_423,
       sum(CASE WHEN TRY_CAST(rat_tasa_desempleo AS DOUBLE) > 6.59460 THEN 1 ELSE 0 END)    AS meses_desemp_sobre_659,
       sum(CASE WHEN rat_expect_inflacion IS NULL OR rat_tasa_desempleo IS NULL THEN 1 ELSE 0 END) AS meses_incompletos
FROM e_perm_aws.t_fact_bpe_vars_macro
GROUP BY substr(CAST(cod_mes AS VARCHAR), 1, 4)
ORDER BY anio
