-- 28_grano_scr_codmes.sql | verifica el grano de e_perm_aws.scr_admbankbpe_rsk por (tip_doc, key_value, codmes) para saber si el cruce codmes = cod_mes es 1 a 1 o si modelo/segmento generan varias filas por cliente-mes (lo que duplicaria el join). Reporta filas de grano, cuantas con duplicado, maximo de filas por grano, maximo de modelos y de probabilidades distintas por grano. Ventana de meses de los desembolsos. Solo conteos. READ-ONLY
WITH s AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(codmes AS int) AS cmes,
         count(*) AS filas,
         count(DISTINCT modelo) AS n_modelos,
         count(DISTINCT segmento) AS n_segmentos,
         count(DISTINCT probabilidad) AS n_prob
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND codmes BETWEEN '202301' AND '202608'
  GROUP BY cast(tip_doc AS varchar), key_value, cast(codmes AS int)
)
SELECT count(*) AS grano_filas,
  sum(CASE WHEN filas > 1 THEN 1 ELSE 0 END) AS grano_con_duplicado,
  max(filas) AS max_filas_por_grano,
  max(n_modelos) AS max_modelos_por_grano,
  max(n_segmentos) AS max_segmentos_por_grano,
  sum(CASE WHEN n_prob > 1 THEN 1 ELSE 0 END) AS grano_con_prob_distinta
FROM s
