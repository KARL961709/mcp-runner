-- s04 GRANULARIDAD de la RM estandarizada -- su techo si se usara para geocodificar
SELECT flg_estandarizado,
       count(*)                                                                        AS n,
       round(100.0 * avg(CASE WHEN nombre_via IS NOT NULL AND trim(nombre_via) <> ''
                              AND numero_calle IS NOT NULL AND trim(numero_calle) <> ''
                              THEN 1 ELSE 0 END), 2)                                   AS pct_via_numero,
       round(100.0 * avg(CASE WHEN id_manzana IS NOT NULL AND trim(id_manzana) <> ''
                              THEN 1 ELSE 0 END), 2)                                   AS pct_manzana,
       round(100.0 * avg(CASE WHEN id_lote IS NOT NULL AND trim(id_lote) <> ''
                              THEN 1 ELSE 0 END), 2)                                   AS pct_lote,
       round(100.0 * avg(CASE WHEN ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6
                              THEN 1 ELSE 0 END), 2)                                   AS pct_ubigeo6,
       round(100.0 * avg(CASE WHEN codpostal IS NOT NULL AND trim(codpostal) <> ''
                              THEN 1 ELSE 0 END), 2)                                   AS pct_codpostal
FROM d_perm_aws.t_rm_direccion_estandarizada
GROUP BY flg_estandarizado
ORDER BY 2 DESC
LIMIT 20
