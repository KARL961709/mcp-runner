-- m1_10 MARCADO GEO de ADMISION + STOCK en 202607, una fila por persona-poblacion.
-- REQUIERE que v4_10_create ya haya corrido (lee grado_elnino_ubigeo_v4).
-- Cascada de ubigeo por exactitud MEDIDA: dim_cliente (j02: 94.85% de acuerdo) > RENIEC nombre
-- (unica via para el 31% de admision que no es cliente) > apicliente.
-- ~15.5M filas. Es un BUILD, no una sonda.
CREATE TABLE disc_model_owner.fen_geo_marca_202607
WITH (format = 'PARQUET', external_location = '<S3_DATOS>/fen/fen_geo_marca_202607/') AS
WITH pob AS (
  SELECT 'ADM' AS poblacion, cod_tip_doc, key_value
  FROM d_perm_aws.scr_vcadmbnk_hist_rsk
  WHERE p_codmes = '202607'
  GROUP BY 1, 2, 3
  UNION ALL
  SELECT 'STK', cod_tip_doc, key_value
  FROM e_perm_aws.scr_vcclibnk_rsk
  WHERE p_codmes = '202607'
  GROUP BY 1, 2, 3
),
dcl AS (
  SELECT key_value, ubigeo_cd
  FROM (SELECT key_value,
               CASE WHEN trim(ubigeo_cd) = '' THEN NULL ELSE trim(ubigeo_cd) END AS ubigeo_cd,
               row_number() OVER (PARTITION BY key_value ORDER BY fecha_creacion DESC) AS rn
        FROM e_perm_aws.t_dim_cliente
        WHERE tipo_persona_host = '01')
  WHERE rn = 1 AND ubigeo_cd IS NOT NULL AND length(ubigeo_cd) = 6
),
gnom AS (
  SELECT upper(trim(departamento)) AS dep,
         CASE WHEN cod_ubigeo IN ('110301','110302','110303','110304','110305') THEN 'NASCA'
              WHEN cod_ubigeo = '150507' THEN 'CANETE'
              ELSE upper(trim(provincia)) END AS prov,
         CASE WHEN cod_ubigeo = '110301' THEN 'NAZCA'
              ELSE upper(trim(distrito)) END AS dist,
         cod_ubigeo
  FROM disc_model_owner.grado_elnino_ubigeo_v4
  UNION ALL
  SELECT upper(trim(departamento)), upper(trim(provincia)), 'PUEBLO LIBRE', cod_ubigeo
  FROM disc_model_owner.grado_elnino_ubigeo_v4
  WHERE cod_ubigeo = '150121'
),
ren AS (
  SELECT r.key_value, min(g.cod_ubigeo) AS cod_ubigeo
  FROM (SELECT key_value,
               max(regexp_replace(normalize(trim(upper(dep_ubi_domicilio)), NFD), '\p{M}', '')) AS dep,
               max(regexp_replace(normalize(trim(upper(pro_ubi_domicilio)), NFD), '\p{M}', '')) AS prov,
               max(regexp_replace(normalize(trim(upper(dis_ubi_domicilio)), NFD), '\p{M}', '')) AS dist
        FROM e_perm_aws.t_mst_reniec_rsk
        WHERE tip_doc = '1'
        GROUP BY key_value) r
  JOIN gnom g ON g.dep = r.dep AND g.prov = r.prov AND g.dist = r.dist
  GROUP BY r.key_value
),
api AS (
  SELECT key_value, ubigeo, geocodificable
  FROM (SELECT key_value, trim(ubigeo) AS ubigeo,
               CASE WHEN nomvia IS NOT NULL AND trim(nomvia) <> ''
                     AND numero IS NOT NULL AND trim(numero) <> '' THEN 1 ELSE 0 END AS geocodificable,
               row_number() OVER (PARTITION BY key_value
                                  ORDER BY CASE WHEN tipdireccion = 'DIRECCION DE DOMICILIO' THEN 1
                                                WHEN tipdireccion = 'DIRECCION PRINCIPAL' THEN 2
                                                ELSE 3 END,
                                           prioridad ASC, fecactualizacion DESC) AS rn
        FROM d_perm_aws.t_dmdireccion_apicliente
        WHERE ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6)
  WHERE rn = 1
),
cen AS (
  SELECT key_value, max(latitud_y) AS lat, max(longitud_x) AS lon, max(id_mzna) AS id_mzna
  FROM e_perm_aws.t_agg_censo_enrich_rsk
  WHERE latitud_y IS NOT NULL AND longitud_x IS NOT NULL
  GROUP BY key_value
),
res AS (
  SELECT p.poblacion, p.cod_tip_doc, p.key_value,
         coalesce(d.ubigeo_cd, r.cod_ubigeo, a.ubigeo)                AS ubigeo,
         CASE WHEN d.ubigeo_cd  IS NOT NULL THEN 'DIMCLI'
              WHEN r.cod_ubigeo IS NOT NULL THEN 'RENIEC_NOMBRE'
              WHEN a.ubigeo     IS NOT NULL THEN 'APICLIENTE'
              ELSE 'SIN' END                                          AS ubigeo_fuente,
         CASE WHEN d.ubigeo_cd  IS NOT NULL THEN 1
              WHEN r.cod_ubigeo IS NOT NULL THEN 2
              WHEN a.ubigeo     IS NOT NULL THEN 3
              ELSE 9 END                                              AS ubigeo_calidad,
         c.lat, c.lon, c.id_mzna,
         CASE WHEN c.lat IS NOT NULL THEN 'CENSO' ELSE 'SIN' END      AS punto_fuente,
         CASE WHEN c.lat IS NOT NULL THEN 1 ELSE 9 END                AS punto_calidad,
         coalesce(a.geocodificable, 0)                                AS flg_geocodificable
  FROM pob p
  LEFT JOIN dcl d ON d.key_value = p.key_value
  LEFT JOIN ren r ON r.key_value = p.key_value
  LEFT JOIN api a ON a.key_value = p.key_value
  LEFT JOIN cen c ON c.key_value = p.key_value
)
SELECT res.poblacion, res.cod_tip_doc, res.key_value,
       res.ubigeo, res.ubigeo_fuente, res.ubigeo_calidad,
       res.lat, res.lon, res.id_mzna, res.punto_fuente, res.punto_calidad,
       res.flg_geocodificable,
       g.r_label, g.r_nivel, g.pacifico, g.gate_cronica, g.patron_evento, g.pct_expuesto
FROM res
LEFT JOIN disc_model_owner.grado_elnino_ubigeo_v4 g ON g.cod_ubigeo = res.ubigeo
