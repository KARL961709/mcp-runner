-- q01 SE ACUMULA O SE REEMPLAZA -- si hay muchas fecproceso con volumen parejo, acumula historia
--     si hay una sola (o la ultima concentra todo), es snapshot diario y perdemos lo anterior
SELECT fecproceso,
       count(*)                  AS n_filas,
       count(DISTINCT key_value) AS n_personas
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY fecproceso
ORDER BY 1 DESC
LIMIT 45
