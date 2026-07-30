-- q02 misma pregunta por la otra marca de tiempo -- fecdescarga es varchar, no date
SELECT fecdescarga,
       count(*)                  AS n_filas,
       count(DISTINCT key_value) AS n_personas
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY fecdescarga
ORDER BY 1 DESC
LIMIT 45
