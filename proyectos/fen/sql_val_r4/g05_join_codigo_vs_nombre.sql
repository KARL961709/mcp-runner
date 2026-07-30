-- g05 LA PRUEBA -- zona FEN del stock por CODIGO (t_dim_cliente.ubigeo_cd) vs por NOMBRE (RENIEC)
--     si el codigo cubre igual o mas, el stock deja de depender del join por nombre y sus parches
WITH s AS (
  SELECT cod_tip_doc AS tip_doc, key_value
  FROM e_perm_aws.scr_vcclibnk_rsk
  WHERE p_codmes = '202607'
),
c AS (
  SELECT tip_doc, key_value, ubigeo_cd
  FROM (SELECT tipo_identificacion_host AS tip_doc,
               key_value,
               CASE WHEN trim(ubigeo_cd) = '' THEN NULL ELSE trim(ubigeo_cd) END AS ubigeo_cd,
               row_number() OVER (PARTITION BY tipo_identificacion_host, key_value
                                  ORDER BY fecha_creacion DESC) AS rnk
        FROM e_perm_aws.t_dim_cliente
        WHERE tipo_persona_host = '01')
  WHERE rnk = 1
),
gcod AS (
  SELECT cod_ubigeo, r_label FROM d_perm_aws.grado_elnino_ubigeo_v3
),
gnom AS (
  SELECT upper(trim(departamento)) AS dep,
         CASE WHEN cod_ubigeo IN ('110301','110302','110303','110304','110305') THEN 'NASCA'
              WHEN cod_ubigeo = '150507' THEN 'CANETE'
              ELSE upper(trim(provincia)) END AS prov,
         CASE WHEN cod_ubigeo = '110301' THEN 'NAZCA'
              ELSE upper(trim(distrito)) END AS dist,
         r_label
  FROM d_perm_aws.grado_elnino_ubigeo_v3
  UNION ALL
  SELECT upper(trim(departamento)), upper(trim(provincia)), 'PUEBLO LIBRE', r_label
  FROM d_perm_aws.grado_elnino_ubigeo_v3
  WHERE cod_ubigeo = '150121'
),
r AS (
  SELECT key_value,
         max(regexp_replace(normalize(trim(upper(dep_ubi_domicilio)), NFD), '\p{M}', '')) AS dep,
         max(regexp_replace(normalize(trim(upper(pro_ubi_domicilio)), NFD), '\p{M}', '')) AS prov,
         max(regexp_replace(normalize(trim(upper(dis_ubi_domicilio)), NFD), '\p{M}', '')) AS dist
  FROM e_perm_aws.t_mst_reniec_rsk
  WHERE tip_doc = '1'
  GROUP BY key_value
)
SELECT count(*)                                                                     AS n_stock,
       round(100.0 * avg(CASE WHEN c.key_value  IS NOT NULL THEN 1 ELSE 0 END), 3)   AS pct_en_dimcli,
       round(100.0 * avg(CASE WHEN c.ubigeo_cd  IS NOT NULL THEN 1 ELSE 0 END), 3)   AS pct_con_ubigeo_cd,
       round(100.0 * avg(CASE WHEN gc.r_label   IS NOT NULL THEN 1 ELSE 0 END), 3)   AS pct_zona_por_codigo,
       round(100.0 * avg(CASE WHEN gn.r_label   IS NOT NULL THEN 1 ELSE 0 END), 3)   AS pct_zona_por_nombre,
       round(100.0 * avg(CASE WHEN gc.r_label IS NOT NULL AND gn.r_label IS NOT NULL
                              AND gc.r_label = gn.r_label THEN 1 ELSE 0 END), 3)     AS pct_ambas_concuerdan,
       round(100.0 * avg(CASE WHEN gc.r_label IS NOT NULL AND gn.r_label IS NOT NULL
                              AND gc.r_label <> gn.r_label THEN 1 ELSE 0 END), 3)    AS pct_ambas_discrepan
FROM s
LEFT JOIN c    ON c.tip_doc = s.tip_doc AND c.key_value = s.key_value
LEFT JOIN gcod gc ON gc.cod_ubigeo = c.ubigeo_cd
LEFT JOIN r    ON r.key_value = s.key_value
LEFT JOIN gnom gn ON gn.dep = r.dep AND gn.prov = r.prov AND gn.dist = r.dist
