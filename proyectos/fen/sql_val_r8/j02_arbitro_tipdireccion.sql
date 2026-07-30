-- j02 EL ARBITRO -- apicliente etiqueta el TIPO de direccion, RENIEC y dim_cliente no.
--     para los clientes donde las dos vias discrepan de zona, con cual concuerda apicliente?
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
r AS (
  SELECT key_value,
         max(regexp_replace(normalize(trim(upper(dep_ubi_domicilio)), NFD), '\p{M}', '')) AS dep,
         max(regexp_replace(normalize(trim(upper(pro_ubi_domicilio)), NFD), '\p{M}', '')) AS prov,
         max(regexp_replace(normalize(trim(upper(dis_ubi_domicilio)), NFD), '\p{M}', '')) AS dist
  FROM e_perm_aws.t_mst_reniec_rsk
  WHERE tip_doc = '1'
  GROUP BY key_value
),
gn AS (
  SELECT upper(trim(departamento)) AS dep, upper(trim(provincia)) AS prov,
         upper(trim(distrito)) AS dist, r_label
  FROM d_perm_aws.grado_elnino_ubigeo_v3
),
ap AS (
  SELECT tipdoc, key_value, tipdireccion, trim(ubigeo) AS ubigeo
  FROM (SELECT tipdoc, key_value, tipdireccion, ubigeo,
               row_number() OVER (PARTITION BY tipdoc, key_value, tipdireccion
                                  ORDER BY prioridad ASC, fecactualizacion DESC) AS rn
        FROM d_perm_aws.t_dmdireccion_apicliente
        WHERE ubigeo IS NOT NULL AND length(trim(ubigeo)) = 6)
  WHERE rn = 1
)
SELECT ap.tipdireccion,
       count(*)                                                                        AS n_discrepan,
       round(100.0 * avg(CASE WHEN ga.r_label = gc.r_label THEN 1 ELSE 0 END), 2)       AS pct_api_igual_codigo,
       round(100.0 * avg(CASE WHEN ga.r_label = gr.r_label THEN 1 ELSE 0 END), 2)       AS pct_api_igual_nombre,
       round(100.0 * avg(CASE WHEN ga.r_label IS NULL THEN 1 ELSE 0 END), 2)            AS pct_api_sin_zona
FROM s
JOIN dc ON dc.tipdoc = s.tipdoc AND dc.key_value = s.key_value
JOIN d_perm_aws.grado_elnino_ubigeo_v3 gc ON gc.cod_ubigeo = dc.ubigeo_cd
JOIN r  ON r.key_value = s.key_value
JOIN gn gr ON gr.dep = r.dep AND gr.prov = r.prov AND gr.dist = r.dist
JOIN ap ON ap.tipdoc = s.tipdoc AND ap.key_value = s.key_value
LEFT JOIN d_perm_aws.grado_elnino_ubigeo_v3 ga ON ga.cod_ubigeo = ap.ubigeo
WHERE gc.r_label <> gr.r_label
GROUP BY ap.tipdireccion
ORDER BY 2 DESC
LIMIT 20
