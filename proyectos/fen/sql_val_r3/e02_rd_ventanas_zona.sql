-- e02 EL CONTRASTE CON n GRANDE -- RD por nivel R en ventanas de regimen (COVID 2020 excluido)
--     si el spread se abre solo en la ventana El Nino, hay senal ciclica diferencial
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
  SELECT CASE WHEN a.codmes BETWEEN 201901 AND 201912 THEN '1_pre_2019'
              WHEN a.codmes BETWEEN 202101 AND 202212 THEN '2_lanina_2021_2022'
              WHEN a.codmes BETWEEN 202301 AND 202412 THEN '3_elnino_2023_2024'
              WHEN a.codmes BETWEEN 202501 AND 202504 THEN '4_post_2025'
              ELSE 'x_covid' END AS ventana,
         g.r_label,
         CAST(a.flg_target_pp_12m AS double) AS d
  FROM disc_model_owner.pp_vc_ds_po_origpp a
  LEFT JOIN r ON r.key_value = a.id_value
  LEFT JOIN g ON g.dep = r.dep AND g.prov = r.prov AND g.dist = r.dist
  WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
    AND a.codmes <= 202504
)
SELECT ventana,
       count(*)                                                       AS n,
       round(100.0 * avg(CASE WHEN r_label = 'R0' THEN d END), 3)      AS rd_r0,
       round(100.0 * avg(CASE WHEN r_label = 'R1' THEN d END), 3)      AS rd_r1,
       round(100.0 * avg(CASE WHEN r_label = 'R2' THEN d END), 3)      AS rd_r2,
       round(100.0 * avg(CASE WHEN r_label = 'R3' THEN d END), 3)      AS rd_r3,
       round(100.0 * avg(CASE WHEN r_label = 'R4' THEN d END), 3)      AS rd_r4,
       round(100.0 * avg(CASE WHEN r_label = 'R5' THEN d END), 3)      AS rd_r5,
       sum(CASE WHEN r_label IN ('R4','R5') THEN 1 ELSE 0 END)         AS n_r45,
       round(100.0 * (avg(CASE WHEN r_label IN ('R4','R5') THEN d END)
                    - avg(CASE WHEN r_label = 'R1' THEN d END)), 3)    AS spread_r45_r1
FROM j
WHERE ventana <> 'x_covid'
GROUP BY ventana
ORDER BY ventana
