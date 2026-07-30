-- h03 LA PREGUNTA CENTRAL -- cuanta coordenada USABLE hay, y no solo no-nula
--     bbox Peru: lat -18.5..0 , lon -81.5..-68.5. Fuera de eso la coordenada es basura
SELECT tipdireccion,
       flgvalidado,
       count(*)                                                                          AS n,
       round(100.0 * avg(CASE WHEN ylatitud IS NOT NULL AND xlongitud IS NOT NULL
                              THEN 1 ELSE 0 END), 2)                                     AS pct_no_nula,
       round(100.0 * avg(CASE WHEN ylatitud BETWEEN -18.5 AND 0
                              AND xlongitud BETWEEN -81.5 AND -68.5 THEN 1 ELSE 0 END), 2) AS pct_en_peru,
       round(100.0 * avg(CASE WHEN ylatitud = 0 AND xlongitud = 0 THEN 1 ELSE 0 END), 2)  AS pct_cero_cero,
       round(100.0 * avg(CASE WHEN manzana IS NOT NULL AND trim(manzana) <> ''
                              THEN 1 ELSE 0 END), 2)                                     AS pct_con_manzana,
       round(100.0 * avg(CASE WHEN ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6
                              THEN 1 ELSE 0 END), 2)                                     AS pct_ubigeo6
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY tipdireccion, flgvalidado
ORDER BY 3 DESC
LIMIT 40
