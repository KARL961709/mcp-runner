-- q03 ANTIGUEDAD -- si las direcciones son viejas, la tabla acumula -- si son todas de este mes, reemplaza
SELECT year(fecregistro)        AS anio_registro,
       count(*)                 AS n_filas,
       count(DISTINCT key_value) AS n_personas,
       min(year(fecactualizacion)) AS min_anio_actualiz,
       max(year(fecactualizacion)) AS max_anio_actualiz,
       min(year(fecfuente))     AS min_anio_fuente,
       max(year(fecfuente))     AS max_anio_fuente
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY year(fecregistro)
ORDER BY 1 DESC
LIMIT 40
