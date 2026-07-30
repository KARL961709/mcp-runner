-- f14 GATE de 04_granular_stock: cobertura de geo FINA (censo lat/long + manzana) sobre el stock
--     claim a validar: 75.9% con punto y unica fuente con manzana
SELECT s.p_codmes,
       count(*)                                                                       AS n_stock,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)      AS pct_en_censo,
       round(100.0 * avg(CASE WHEN c.latitud_y IS NOT NULL
                              AND c.longitud_x IS NOT NULL THEN 1 ELSE 0 END), 2)      AS pct_con_latlon,
       round(100.0 * avg(CASE WHEN c.id_mzna IS NOT NULL THEN 1 ELSE 0 END), 2)        AS pct_con_manzana
FROM (SELECT p_codmes, cod_tip_doc AS tip_doc, key_value
      FROM e_perm_aws.scr_vcclibnk_rsk
      WHERE p_codmes >= '202604') s
LEFT JOIN (SELECT tip_doc, key_value, latitud_y, longitud_x, id_mzna
           FROM e_perm_aws.t_agg_censo_enrich_rsk) c
       ON c.tip_doc = s.tip_doc AND c.key_value = s.key_value
GROUP BY s.p_codmes
ORDER BY s.p_codmes
