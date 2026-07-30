-- t02 LA GANANCIA REAL del puente -- personas del STOCK sin punto de censo pero con manzana de API
--     que caen en una llave (ubigeo, manzana) que el diccionario si conoce
WITH api AS (
  SELECT key_value, trim(ubigeo) AS ubigeo,
         regexp_replace(regexp_replace(upper(trim(manzana)), '[^A-Z0-9]', ''), '^(MZA|MZ)', '') AS mz
  FROM d_perm_aws.t_dmdireccion_apicliente
  WHERE manzana IS NOT NULL AND trim(manzana) <> ''
    AND ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6
),
cen AS (
  SELECT key_value, max(id_mzna) AS id_mzna,
         max(CASE WHEN latitud_y IS NOT NULL AND longitud_x IS NOT NULL THEN 1 ELSE 0 END) AS punto
  FROM e_perm_aws.t_agg_censo_enrich_rsk
  GROUP BY key_value
),
dicc AS (
  SELECT DISTINCT a.ubigeo, a.mz
  FROM api a JOIN cen c ON c.key_value = a.key_value
  WHERE a.mz <> '' AND c.id_mzna IS NOT NULL AND c.id_mzna <> 0
),
stk AS (SELECT DISTINCT key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202607')
SELECT count(*)                                                                        AS n_stock,
       round(100.0 * avg(CASE WHEN coalesce(c.punto, 0) = 1 THEN 1 ELSE 0 END), 2)       AS pct_punto_censo,
       round(100.0 * avg(CASE WHEN a.mz IS NOT NULL AND a.mz <> '' THEN 1 ELSE 0 END), 2) AS pct_con_mz_api,
       round(100.0 * avg(CASE WHEN coalesce(c.punto, 0) = 0
                              AND a.mz IS NOT NULL AND a.mz <> '' THEN 1 ELSE 0 END), 2)  AS pct_sin_punto_con_mz,
       round(100.0 * avg(CASE WHEN coalesce(c.punto, 0) = 0 AND d.mz IS NOT NULL
                              THEN 1 ELSE 0 END), 2)                                     AS pct_ganancia_puente,
       round(100.0 * avg(CASE WHEN coalesce(c.punto, 0) = 1 OR d.mz IS NOT NULL
                              THEN 1 ELSE 0 END), 2)                                     AS pct_techo_con_puente
FROM stk s
LEFT JOIN cen c ON c.key_value = s.key_value
LEFT JOIN (SELECT key_value, min(ubigeo) AS ubigeo, min(mz) AS mz FROM api GROUP BY key_value) a
       ON a.key_value = s.key_value
LEFT JOIN dicc d ON d.ubigeo = a.ubigeo AND d.mz = a.mz
