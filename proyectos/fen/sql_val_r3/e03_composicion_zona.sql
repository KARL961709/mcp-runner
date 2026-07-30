-- e03 CONFOUND CHECK -- la mezcla de zonas de la poblacion de calibracion debe ser estable
--     si la cartera migra de zona ano a ano, un spread temporal puede ser puro cambio de mezcla
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
),
j AS (
  SELECT substr(CAST(a.codmes AS varchar), 1, 4) AS anio,
         CASE WHEN g.r_label IN ('R4','R5') THEN 'alto'
              WHEN g.r_label IN ('R2','R3') THEN 'medio'
              WHEN g.r_label IN ('R0','R1') THEN 'bajo'
              ELSE 'sin_zona' END AS zona
  FROM disc_model_owner.pp_vc_ds_po_origpp a
  LEFT JOIN r ON r.key_value = a.id_value
  LEFT JOIN g ON g.dep = r.dep AND g.prov = r.prov AND g.dist = r.dist
  WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
)
SELECT anio,
       count(*)                                                                     AS n,
       round(100.0 * sum(CASE WHEN zona = 'bajo'     THEN 1 ELSE 0 END)/count(*), 2) AS pct_bajo,
       round(100.0 * sum(CASE WHEN zona = 'medio'    THEN 1 ELSE 0 END)/count(*), 2) AS pct_medio,
       round(100.0 * sum(CASE WHEN zona = 'alto'     THEN 1 ELSE 0 END)/count(*), 2) AS pct_alto,
       round(100.0 * sum(CASE WHEN zona = 'sin_zona' THEN 1 ELSE 0 END)/count(*), 2) AS pct_sin_zona
FROM j
GROUP BY anio
ORDER BY anio
