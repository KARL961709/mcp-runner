-- h04 LAS BANDERAS DE CALIDAD -- flgestandarizado x prioridad x score: definen la cascada y el MoC
SELECT flgestandarizado,
       prioridad,
       count(*)                                                                            AS n,
       round(100.0 * avg(CASE WHEN ylatitud BETWEEN -18.5 AND 0
                              AND xlongitud BETWEEN -81.5 AND -68.5 THEN 1 ELSE 0 END), 2) AS pct_coord_peru,
       round(min(probabilidad), 4)                                                         AS prob_min,
       round(max(probabilidad), 4)                                                         AS prob_max,
       count(DISTINCT score)                                                               AS n_valores_score
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY flgestandarizado, prioridad
ORDER BY 3 DESC
LIMIT 40
