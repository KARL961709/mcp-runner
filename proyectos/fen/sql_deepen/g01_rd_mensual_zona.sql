-- g01 panel RD 12m MENSUAL por zona FEN (bajo/medio/alto) sobre pp_vc_ds_po_origpp IBK flg_calib_rd=1. MADUREZ: flg_target_pp_12m NO nulo Y codmes <= 202507 (ultima RD12 con 12m cerrado en este vintage, verificado en master_ppvc: target null desde 202508, originaciones hasta 202607). Bump 202507 en el proximo refresh. Formato ancho (1 fila por codmes) para paste chico. Alimenta Canal A (regresion vs ICEN) y la permutacion. Espejo de e01. READ-ONLY.
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
  SELECT CAST(a.codmes AS varchar) AS codmes,
         CASE WHEN g.r_label IN ('R4','R5') THEN 'alto'
              WHEN g.r_label IN ('R2','R3') THEN 'medio'
              WHEN g.r_label IN ('R0','R1') THEN 'bajo'
              ELSE 'sin_zona' END AS zona,
         CAST(a.flg_target_pp_12m AS double) AS d
  FROM disc_model_owner.pp_vc_ds_po_origpp a
  LEFT JOIN r ON r.key_value = a.id_value
  LEFT JOIN g ON g.dep = r.dep AND g.prov = r.prov AND g.dist = r.dist
  WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
    AND a.flg_target_pp_12m IS NOT NULL AND a.codmes <= 202507
)
SELECT codmes,
       count(*)                                                  AS n,
       sum(CASE WHEN zona = 'bajo'  THEN 1 ELSE 0 END)           AS n_bajo,
       sum(CASE WHEN zona = 'medio' THEN 1 ELSE 0 END)           AS n_medio,
       sum(CASE WHEN zona = 'alto'  THEN 1 ELSE 0 END)           AS n_alto,
       round(100.0 * avg(CASE WHEN zona = 'bajo'  THEN d END), 4) AS rd_bajo,
       round(100.0 * avg(CASE WHEN zona = 'medio' THEN d END), 4) AS rd_medio,
       round(100.0 * avg(CASE WHEN zona = 'alto'  THEN d END), 4) AS rd_alto
FROM j
GROUP BY codmes
ORDER BY codmes
