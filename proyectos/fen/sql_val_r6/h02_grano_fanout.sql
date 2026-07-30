-- h02 GRANO REAL -- cuantas direcciones tiene una persona en un mes
--     define si hay que dedupear y por que criterio (prioridad / flgvalidado / fecactualizacion)
SELECT n_dir_por_persona,
       count(*)                                     AS n_personas_mes,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pct
FROM (SELECT codmes, tipdoc, key_value, count(*) AS n_dir_por_persona
      FROM d_perm_aws.t_dmdireccion_apicliente
      GROUP BY codmes, tipdoc, key_value)
GROUP BY n_dir_por_persona
ORDER BY n_dir_por_persona
LIMIT 30
