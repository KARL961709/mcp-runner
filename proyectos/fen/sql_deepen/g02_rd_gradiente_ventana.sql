-- g02 dosis-respuesta: RD 12m por r_label (R0..R5) en ventanas anuales de regimen, sobre pp_vc_ds_po_origpp IBK flg_calib_rd=1. Canal B: el gradiente R DEBE abrirse monotono SOLO en la ventana El Nino (Yaku 2023) y no en las placebo (2019,2021,2022,2024,2025) -> identifica gamma desde el CORTE TRANSVERSAL, inmune al 1-solo-evento-en-tiempo. COVID 2020 marcado aparte. READ-ONLY.
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
  SELECT CASE WHEN a.codmes BETWEEN 201901 AND 201912 THEN '1_2019'
              WHEN a.codmes BETWEEN 202001 AND 202012 THEN 'x_2020_covid'
              WHEN a.codmes BETWEEN 202101 AND 202112 THEN '2_2021'
              WHEN a.codmes BETWEEN 202201 AND 202212 THEN '3_2022'
              WHEN a.codmes BETWEEN 202301 AND 202312 THEN '4_2023_yaku'
              WHEN a.codmes BETWEEN 202401 AND 202412 THEN '5_2024'
              WHEN a.codmes BETWEEN 202501 AND 202508 THEN '6_2025'
              ELSE 'x_otro' END AS ventana,
         coalesce(g.r_label, 'sin_zona') AS r_label,
         CAST(a.flg_target_pp_12m AS double) AS d
  FROM disc_model_owner.pp_vc_ds_po_origpp a
  LEFT JOIN r ON r.key_value = a.id_value
  LEFT JOIN g ON g.dep = r.dep AND g.prov = r.prov AND g.dist = r.dist
  WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
    AND a.flg_target_pp_12m IS NOT NULL AND a.codmes <= 202508
)
SELECT ventana,
       count(*)                                                  AS n,
       round(100.0 * avg(CASE WHEN r_label = 'R0' THEN d END), 4) AS rd_r0,
       round(100.0 * avg(CASE WHEN r_label = 'R1' THEN d END), 4) AS rd_r1,
       round(100.0 * avg(CASE WHEN r_label = 'R2' THEN d END), 4) AS rd_r2,
       round(100.0 * avg(CASE WHEN r_label = 'R3' THEN d END), 4) AS rd_r3,
       round(100.0 * avg(CASE WHEN r_label = 'R4' THEN d END), 4) AS rd_r4,
       round(100.0 * avg(CASE WHEN r_label = 'R5' THEN d END), 4) AS rd_r5,
       sum(CASE WHEN r_label IN ('R4','R5') THEN 1 ELSE 0 END)    AS n_r45,
       round(100.0 * (avg(CASE WHEN r_label IN ('R4','R5') THEN d END)
                    - avg(CASE WHEN r_label IN ('R0','R1') THEN d END)), 4) AS spread_r45_r01
FROM j
GROUP BY ventana
ORDER BY ventana
