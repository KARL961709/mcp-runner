-- i01 LA GANANCIA MARGINAL -- solo esto justifica construir geocodificacion
--     clientes SIN punto de censo pero CON direccion geocodificable en apicliente
WITH s AS (
  SELECT cod_tip_doc AS tipdoc, key_value
  FROM e_perm_aws.scr_vcclibnk_rsk
  WHERE p_codmes = '202607'
),
c AS (
  SELECT tip_doc AS tipdoc, key_value
  FROM e_perm_aws.t_agg_censo_enrich_rsk
  WHERE latitud_y IS NOT NULL AND longitud_x IS NOT NULL
  GROUP BY tip_doc, key_value
),
a AS (
  SELECT tipdoc, key_value
  FROM d_perm_aws.t_dmdireccion_apicliente
  WHERE nomvia IS NOT NULL AND trim(nomvia) <> ''
    AND numero IS NOT NULL AND trim(numero) <> ''
    AND ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6
  GROUP BY tipdoc, key_value
)
SELECT count(*)                                                                        AS n_stock,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)       AS pct_con_censo,
       round(100.0 * avg(CASE WHEN a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)       AS pct_api_geocodificable,
       round(100.0 * avg(CASE WHEN c.key_value IS NULL
                              AND a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)        AS pct_ganancia_marginal,
       round(100.0 * avg(CASE WHEN c.key_value IS NULL
                              AND a.key_value IS NULL THEN 1 ELSE 0 END), 2)            AS pct_sin_ninguna,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL
                               OR a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)        AS pct_techo_alcanzable
FROM s
LEFT JOIN c ON c.tipdoc = s.tipdoc AND c.key_value = s.key_value
LEFT JOIN a ON a.tipdoc = s.tipdoc AND a.key_value = s.key_value
