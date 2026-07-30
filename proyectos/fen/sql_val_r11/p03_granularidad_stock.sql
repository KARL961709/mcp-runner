-- p03 ESCALERA DE GRANULARIDAD -- stock 202607, que nivel geografico alcanza cada fuente
--     apicliente se agrega con max() por persona: mide "lo tiene en AL MENOS UNA direccion" = techo
WITH p AS (
  SELECT DISTINCT key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202607'
),
ren AS (
  SELECT key_value,
         max(CASE WHEN dep_ubi_domicilio IS NOT NULL AND trim(dep_ubi_domicilio) <> '' THEN 1 ELSE 0 END) AS dep,
         max(CASE WHEN pro_ubi_domicilio IS NOT NULL AND trim(pro_ubi_domicilio) <> '' THEN 1 ELSE 0 END) AS prov,
         max(CASE WHEN dis_ubi_domicilio IS NOT NULL AND trim(dis_ubi_domicilio) <> '' THEN 1 ELSE 0 END) AS dist,
         max(CASE WHEN cod_ubi_domicilio IS NOT NULL AND length(trim(cod_ubi_domicilio)) = 6 THEN 1 ELSE 0 END) AS cod6
  FROM e_perm_aws.t_mst_reniec_rsk WHERE tip_doc = '1' GROUP BY key_value
),
dcl AS (
  SELECT key_value,
         max(CASE WHEN ubigeo_cd IS NOT NULL AND length(trim(ubigeo_cd)) = 6 THEN 1 ELSE 0 END) AS ubi6
  FROM e_perm_aws.t_dim_cliente WHERE tipo_persona_host = '01' GROUP BY key_value
),
cen AS (
  SELECT key_value,
         max(CASE WHEN latitud_y IS NOT NULL AND longitud_x IS NOT NULL THEN 1 ELSE 0 END) AS punto,
         max(CASE WHEN id_mzna IS NOT NULL AND trim(id_mzna) <> '' THEN 1 ELSE 0 END)      AS mzna
  FROM e_perm_aws.t_agg_censo_enrich_rsk GROUP BY key_value
),
api AS (
  SELECT key_value,
         max(CASE WHEN departamento IS NOT NULL AND trim(departamento) <> '' THEN 1 ELSE 0 END) AS dep,
         max(CASE WHEN provincia IS NOT NULL AND trim(provincia) <> '' THEN 1 ELSE 0 END)      AS prov,
         max(CASE WHEN distrito IS NOT NULL AND trim(distrito) <> '' THEN 1 ELSE 0 END)        AS dist,
         max(CASE WHEN ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6 THEN 1 ELSE 0 END)      AS ubi6,
         max(CASE WHEN manzana IS NOT NULL AND trim(manzana) <> '' THEN 1 ELSE 0 END)          AS mzna,
         max(CASE WHEN lote IS NOT NULL AND trim(lote) <> '' THEN 1 ELSE 0 END)                AS lote,
         max(CASE WHEN manzana IS NOT NULL AND trim(manzana) <> ''
                   AND lote IS NOT NULL AND trim(lote) <> '' THEN 1 ELSE 0 END)                AS mzna_lote,
         max(CASE WHEN nomvia IS NOT NULL AND trim(nomvia) <> ''
                   AND numero IS NOT NULL AND trim(numero) <> '' THEN 1 ELSE 0 END)            AS via_num
  FROM d_perm_aws.t_dmdireccion_apicliente GROUP BY key_value
)
SELECT 'STK' AS poblacion, count(*) AS n,
       round(100.0 * avg(coalesce(r.dep, 0)), 2)       AS ren_dep,
       round(100.0 * avg(coalesce(r.prov, 0)), 2)      AS ren_prov,
       round(100.0 * avg(coalesce(r.dist, 0)), 2)      AS ren_dist,
       round(100.0 * avg(coalesce(r.cod6, 0)), 2)      AS ren_cod6_noinei,
       round(100.0 * avg(coalesce(d.ubi6, 0)), 2)      AS dcl_ubigeo6,
       round(100.0 * avg(coalesce(a.dist, 0)), 2)      AS api_dist,
       round(100.0 * avg(coalesce(a.ubi6, 0)), 2)      AS api_ubigeo6,
       round(100.0 * avg(coalesce(a.mzna, 0)), 2)      AS api_mzna,
       round(100.0 * avg(coalesce(a.lote, 0)), 2)      AS api_lote,
       round(100.0 * avg(coalesce(a.mzna_lote, 0)), 2) AS api_mzna_y_lote,
       round(100.0 * avg(coalesce(a.via_num, 0)), 2)   AS api_via_numero,
       round(100.0 * avg(coalesce(c.mzna, 0)), 2)      AS cen_mzna,
       round(100.0 * avg(coalesce(c.punto, 0)), 2)     AS cen_punto,
       round(100.0 * avg(CASE WHEN coalesce(c.mzna,0) = 1 OR coalesce(a.mzna,0) = 1
                              THEN 1 ELSE 0 END), 2)   AS mzna_cualquiera,
       round(100.0 * avg(CASE WHEN coalesce(d.ubi6,0) = 1 OR coalesce(r.dist,0) = 1
                               OR coalesce(a.ubi6,0) = 1 THEN 1 ELSE 0 END), 2) AS distrito_cualquiera
FROM p
LEFT JOIN ren r ON r.key_value = p.key_value
LEFT JOIN dcl d ON d.key_value = p.key_value
LEFT JOIN cen c ON c.key_value = p.key_value
LEFT JOIN api a ON a.key_value = p.key_value
