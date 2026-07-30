-- t01 SE PUEDE PUENTEAR LA MANZANA? -- las personas que estan en censo Y en API dan el diccionario
--     (ubigeo, manzana_texto_normalizada) -> id_mzna. Si una llave mapea a varios id_mzna, no sirve.
WITH api AS (
  SELECT key_value, trim(ubigeo) AS ubigeo,
         regexp_replace(regexp_replace(upper(trim(manzana)), '[^A-Z0-9]', ''), '^(MZA|MZ)', '') AS mz
  FROM d_perm_aws.t_dmdireccion_apicliente
  WHERE manzana IS NOT NULL AND trim(manzana) <> ''
    AND ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6
),
cen AS (
  SELECT key_value, max(id_mzna) AS id_mzna
  FROM e_perm_aws.t_agg_censo_enrich_rsk
  WHERE id_mzna IS NOT NULL AND id_mzna <> 0
  GROUP BY key_value
),
par AS (
  SELECT a.ubigeo, a.mz, c.id_mzna
  FROM api a JOIN cen c ON c.key_value = a.key_value
  WHERE a.mz <> ''
)
SELECT count(*)                                                     AS pares_persona,
       count(DISTINCT (ubigeo || '|' || mz))                         AS llaves_texto,
       count(DISTINCT (ubigeo || '|' || mz || '|' || CAST(id_mzna AS varchar))) AS llaves_x_idmzna,
       round(1.0 * count(DISTINCT (ubigeo || '|' || mz || '|' || CAST(id_mzna AS varchar)))
                 / nullif(count(DISTINCT (ubigeo || '|' || mz)), 0), 3) AS idmzna_por_llave
FROM par
