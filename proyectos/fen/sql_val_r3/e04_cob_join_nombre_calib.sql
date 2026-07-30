-- e04 COBERTURA DEL JOIN POR NOMBRE contra el grado que sobrevivio (d_perm_aws)
--     replica inline los fixes de la lookup borrada: NASCA, CANETE, alias PUEBLO LIBRE
WITH g AS (
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
SELECT substr(CAST(a.codmes AS varchar), 1, 4) AS anio,
       count(*)                                                                AS n_calib,
       round(100.0 * avg(CASE WHEN g.r_label IS NOT NULL THEN 1 ELSE 0 END), 3) AS pct_con_zona
FROM disc_model_owner.pp_vc_ds_po_origpp a
LEFT JOIN r ON r.key_value = a.id_value
LEFT JOIN g ON g.dep = r.dep AND g.prov = r.prov AND g.dist = r.dist
WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
GROUP BY 1
ORDER BY 1
