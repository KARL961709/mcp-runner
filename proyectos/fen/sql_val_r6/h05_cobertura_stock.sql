-- h05 EL NUMERO QUE DECIDE -- cobertura de coordenada USABLE sobre el stock, contra el censo (75.85% medido)
--     dedup por persona tomando la direccion de mayor prioridad y mas reciente
WITH d AS (
  SELECT tipdoc, key_value, ylatitud, xlongitud, manzana, ubigeo
  FROM (SELECT tipdoc, key_value, ylatitud, xlongitud, manzana, ubigeo,
               row_number() OVER (PARTITION BY tipdoc, key_value
                                  ORDER BY prioridad ASC, fecactualizacion DESC) AS rn
        FROM d_perm_aws.t_dmdireccion_apicliente
        WHERE codmes = (SELECT max(codmes) FROM d_perm_aws.t_dmdireccion_apicliente))
  WHERE rn = 1
),
s AS (
  SELECT cod_tip_doc AS tipdoc, key_value
  FROM e_perm_aws.scr_vcclibnk_rsk
  WHERE p_codmes = '202607'
)
SELECT count(*)                                                                            AS n_stock,
       round(100.0 * avg(CASE WHEN d.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)           AS pct_en_apicliente,
       round(100.0 * avg(CASE WHEN d.ylatitud BETWEEN -18.5 AND 0
                              AND d.xlongitud BETWEEN -81.5 AND -68.5 THEN 1 ELSE 0 END), 2) AS pct_coord_usable,
       round(100.0 * avg(CASE WHEN d.manzana IS NOT NULL AND trim(d.manzana) <> ''
                              THEN 1 ELSE 0 END), 2)                                       AS pct_con_manzana,
       round(100.0 * avg(CASE WHEN d.ubigeo IS NOT NULL AND length(trim(d.ubigeo)) = 6
                              THEN 1 ELSE 0 END), 2)                                       AS pct_con_ubigeo
FROM s
LEFT JOIN d ON d.tipdoc = s.tipdoc AND d.key_value = s.key_value
