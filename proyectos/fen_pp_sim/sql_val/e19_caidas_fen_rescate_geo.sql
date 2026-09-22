-- e19_caidas_fen_rescate_geo.sql | Caidos UNICOS por FEN (los ~81k) dentro de la campana PP 2609:
--   (1) su distribucion R0-R5 (R final = reest preferido, la que usa el simulador),
--   (2) "rescate por geolocalizacion": cuantos, por su DOMICILIO DECLARADO caerian en R4/R5, pero al
--       geolocalizarlos con reest (XY per-persona) bajan a R<=3.
-- Pone decl_r (domicilio RENIEC -> nombre normalizado -> grado_elnino_ubigeo_v3, distrito/prov/depto)
--   y reest_r (r_nivel_reest per-persona) LADO A LADO -- a diferencia de e10 que los COALESCE en una sola R.
-- Join por NOMBRE (NFD + strip acentos) para esquivar la trampa INEI<>RENIEC. Puente e08: substr(subject_id,3)=key_value.
-- Read-only, solo agregados. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e19_caidas_fen_rescate_geo
WITH caida AS (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_mo_caida_fen_2609_tmp
  WHERE camp = '2609-2REC' AND producto = 'PP' AND CAST(tot_caidas AS double) = 1
),
g AS (
  SELECT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(provincia),    NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(distrito),     NFD), '\p{M}', '')) AS dist_n,
         r_nivel, pct_expuesto
  FROM d_perm_aws.grado_elnino_ubigeo_v3
),
dist_g AS (SELECT dep_n, prov_n, dist_n, CAST(round(AVG(r_nivel)) AS integer) AS r_nivel FROM g GROUP BY dep_n, prov_n, dist_n),
prov_g AS (SELECT dep_n, prov_n, SUM(r_nivel*(pct_expuesto+0.001))/SUM(pct_expuesto+0.001) AS r_prov FROM g GROUP BY dep_n, prov_n),
dep_g  AS (SELECT dep_n, SUM(r_nivel*(pct_expuesto+0.001))/SUM(pct_expuesto+0.001) AS r_dep FROM g GROUP BY dep_n),
rn AS (
  SELECT key_value,
         upper(regexp_replace(normalize(trim(dep_ubi_domicilio), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(pro_ubi_domicilio), NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(dis_ubi_domicilio), NFD), '\p{M}', '')) AS dist_n
  FROM e_perm_aws.t_mst_reniec_rsk WHERE tip_doc = '1'
),
base AS (
  SELECT c.kv,
         CASE WHEN r.r_nivel_reest IS NOT NULL THEN CAST(round(r.r_nivel_reest) AS integer) END AS reest_r,
         COALESCE(dd.r_nivel, CAST(round(pg.r_prov) AS integer), CAST(round(dg.r_dep) AS integer)) AS decl_r,
         CASE WHEN r.r_nivel_reest IS NOT NULL THEN 'reest'
              WHEN dd.r_nivel IS NOT NULL      THEN 'decl_dist'
              WHEN pg.r_prov  IS NOT NULL      THEN 'decl_prov'
              WHEN dg.r_dep   IS NOT NULL      THEN 'decl_dep'
              ELSE 'none' END AS geo_src,
         u.prob_modelo_cal_ppfacil AS pd_pit
  FROM caida c
  JOIN      d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
  LEFT JOIN rn      ON rn.key_value = c.kv
  LEFT JOIN dist_g dd ON dd.dep_n = rn.dep_n AND dd.prov_n = rn.prov_n AND dd.dist_n = rn.dist_n
  LEFT JOIN prov_g pg ON pg.dep_n = rn.dep_n AND pg.prov_n = rn.prov_n
  LEFT JOIN dep_g  dg ON dg.dep_n = rn.dep_n
),
fin AS (
  SELECT kv, reest_r, decl_r, geo_src, pd_pit,
         COALESCE(reest_r, decl_r, 0) AS final_r,
         CASE WHEN reest_r IS NOT NULL THEN 1 ELSE 0 END AS has_reest
  FROM base
)
SELECT 'A0_caidos_bruto' AS bloque, '' AS k1, '' AS k2, CAST(COUNT(*) AS varchar) AS n, '' AS pd_pit_avg FROM caida
UNION ALL
SELECT 'A1_caidos_scored', '', '', CAST(COUNT(*) AS varchar), '' FROM fin
UNION ALL
SELECT 'A1b_caidos_scored_distinct', '', '', CAST(COUNT(DISTINCT kv) AS varchar), '' FROM fin
UNION ALL
SELECT 'B_geo_src', geo_src, '', CAST(COUNT(*) AS varchar), CAST(round(AVG(pd_pit),4) AS varchar) FROM fin GROUP BY geo_src
UNION ALL
SELECT 'C_final_R_dist', CAST(final_r AS varchar), '', CAST(COUNT(*) AS varchar), CAST(round(AVG(pd_pit),4) AS varchar) FROM fin GROUP BY final_r
UNION ALL
SELECT 'D_decl_R_dist', CAST(decl_r AS varchar), '', CAST(COUNT(*) AS varchar), CAST(round(AVG(pd_pit),4) AS varchar) FROM fin WHERE decl_r IS NOT NULL GROUP BY decl_r
UNION ALL
SELECT 'E_xtab_declR_reestR', CAST(decl_r AS varchar), CAST(reest_r AS varchar), CAST(COUNT(*) AS varchar), CAST(round(AVG(pd_pit),4) AS varchar)
FROM fin WHERE reest_r IS NOT NULL AND decl_r IS NOT NULL GROUP BY decl_r, reest_r
UNION ALL
SELECT 'F_rescate_declR45',
       CASE WHEN reest_r <= 3 THEN '1_rescatado_reest<=3' WHEN reest_r >= 4 THEN '2_confirmado_reest>=4' ELSE '3_otro' END, '',
       CAST(COUNT(*) AS varchar), CAST(round(AVG(pd_pit),4) AS varchar)
FROM fin WHERE has_reest = 1 AND decl_r IN (4,5)
GROUP BY CASE WHEN reest_r <= 3 THEN '1_rescatado_reest<=3' WHEN reest_r >= 4 THEN '2_confirmado_reest>=4' ELSE '3_otro' END
ORDER BY bloque, k1, k2
