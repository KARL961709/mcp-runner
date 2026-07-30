-- k03 COBERTURA GEO de admision en 202607, las 4 fuentes lado a lado y con la MISMA definicion
--     join solo por key_value: b04 probo que es unico en RENIEC (32.7M) y g03 en t_dim_cliente
WITH p AS (
  SELECT DISTINCT key_value FROM d_perm_aws.scr_vcadmbnk_hist_rsk WHERE p_codmes = '202607'
),
ren AS (
  SELECT key_value FROM e_perm_aws.t_mst_reniec_rsk
  WHERE tip_doc = '1' AND dis_ubi_domicilio IS NOT NULL
  GROUP BY key_value
),
dcl AS (
  SELECT key_value FROM e_perm_aws.t_dim_cliente
  WHERE tipo_persona_host = '01' AND ubigeo_cd IS NOT NULL AND length(trim(ubigeo_cd)) = 6
  GROUP BY key_value
),
cen AS (
  SELECT key_value FROM e_perm_aws.t_agg_censo_enrich_rsk
  WHERE latitud_y IS NOT NULL AND longitud_x IS NOT NULL
  GROUP BY key_value
),
api AS (
  SELECT key_value,
         max(CASE WHEN nomvia IS NOT NULL AND trim(nomvia) <> ''
                  AND numero IS NOT NULL AND trim(numero) <> '' THEN 1 ELSE 0 END) AS geocod
  FROM d_perm_aws.t_dmdireccion_apicliente
  WHERE ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6
  GROUP BY key_value
)
SELECT 'admision'                                                                        AS poblacion,
       count(*)                                                                        AS n,
       round(100.0 * avg(CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)       AS pct_reniec_distrito,
       round(100.0 * avg(CASE WHEN d.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)       AS pct_dimcli_ubigeo,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)       AS pct_censo_punto,
       round(100.0 * avg(CASE WHEN a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)       AS pct_api_ubigeo,
       round(100.0 * avg(CASE WHEN a.geocod = 1 THEN 1 ELSE 0 END), 2)                  AS pct_api_geocod,
       round(100.0 * avg(CASE WHEN d.key_value IS NOT NULL
                               OR r.key_value IS NOT NULL
                               OR a.key_value IS NOT NULL THEN 1 ELSE 0 END), 2)        AS pct_algun_distrito,
       round(100.0 * avg(CASE WHEN c.key_value IS NOT NULL OR a.geocod = 1
                              THEN 1 ELSE 0 END), 2)                                    AS pct_techo_punto
FROM p
LEFT JOIN ren r ON r.key_value = p.key_value
LEFT JOIN dcl d ON d.key_value = p.key_value
LEFT JOIN cen c ON c.key_value = p.key_value
LEFT JOIN api a ON a.key_value = p.key_value
