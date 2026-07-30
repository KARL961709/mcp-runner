-- i02 QUE TAN GEOCODIFICABLE es la direccion -- una via sin numero no se resuelve a punto
SELECT tipdireccion,
       count(*)                                                                          AS n,
       round(100.0 * avg(CASE WHEN nomvia IS NOT NULL AND trim(nomvia) <> ''
                              THEN 1 ELSE 0 END), 2)                                     AS pct_con_via,
       round(100.0 * avg(CASE WHEN numero IS NOT NULL AND trim(numero) <> ''
                              THEN 1 ELSE 0 END), 2)                                     AS pct_con_numero,
       round(100.0 * avg(CASE WHEN nomvia IS NOT NULL AND trim(nomvia) <> ''
                              AND numero IS NOT NULL AND trim(numero) <> ''
                              THEN 1 ELSE 0 END), 2)                                     AS pct_via_y_numero,
       round(100.0 * avg(CASE WHEN urbanizacion IS NOT NULL AND trim(urbanizacion) <> ''
                              THEN 1 ELSE 0 END), 2)                                     AS pct_con_urbanizacion,
       round(100.0 * avg(CASE WHEN referencia IS NOT NULL AND trim(referencia) <> ''
                              THEN 1 ELSE 0 END), 2)                                     AS pct_con_referencia,
       round(avg(length(coalesce(direccion, ''))), 1)                                    AS largo_prom_direccion
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY tipdireccion
ORDER BY 2 DESC
LIMIT 20
