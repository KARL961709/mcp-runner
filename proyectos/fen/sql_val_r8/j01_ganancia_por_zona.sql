-- j01 LA DECISION -- los 5.67pp de ganancia marginal, caen en la cola FEN o en Lima?
--     zona por CODIGO INEI via t_dim_cliente (g05: 99.76% de cobertura, mejor que el join por nombre)
--     grado = d_perm_aws.grado_elnino_ubigeo_v3 (la copia que sobrevivio; v4 todavia no esta en Athena)
WITH s AS (
  SELECT cod_tip_doc AS tipdoc, key_value
  FROM e_perm_aws.scr_vcclibnk_rsk
  WHERE p_codmes = '202607'
),
dc AS (
  SELECT tipdoc, key_value, ubigeo_cd
  FROM (SELECT tipo_identificacion_host AS tipdoc, key_value,
               CASE WHEN trim(ubigeo_cd) = '' THEN NULL ELSE trim(ubigeo_cd) END AS ubigeo_cd,
               row_number() OVER (PARTITION BY tipo_identificacion_host, key_value
                                  ORDER BY fecha_creacion DESC) AS rn
        FROM e_perm_aws.t_dim_cliente
        WHERE tipo_persona_host = '01')
  WHERE rn = 1
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
SELECT coalesce(g.r_label, 'SIN_ZONA')                                                   AS zona,
       count(*)                                                                          AS n_stock,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)         AS pct_con_censo,
       round(100.0 * avg(CASE WHEN c.key_value IS NULL
                              AND a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)          AS pct_ganancia,
       sum(CASE WHEN c.key_value IS NULL AND a.key_value IS NOT NULL THEN 1 ELSE 0 END)   AS n_ganancia,
       round(100.0 * avg(CASE WHEN c.key_value IS NULL
                              AND a.key_value IS NULL THEN 1 ELSE 0 END), 2)              AS pct_sin_nada,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL
                               OR a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)          AS pct_techo
FROM s
LEFT JOIN dc ON dc.tipdoc = s.tipdoc AND dc.key_value = s.key_value
LEFT JOIN d_perm_aws.grado_elnino_ubigeo_v3 g ON g.cod_ubigeo = dc.ubigeo_cd
LEFT JOIN c  ON c.tipdoc = s.tipdoc AND c.key_value = s.key_value
LEFT JOIN a  ON a.tipdoc = s.tipdoc AND a.key_value = s.key_value
GROUP BY coalesce(g.r_label, 'SIN_ZONA')
ORDER BY zona
