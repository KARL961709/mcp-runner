-- e14_traza_fallback.sql | traza por que el fallback matchea 0 para los sin-reest (257k a 'none').
-- Sobre la poblacion sin-reest (en campana + score, pero NO en mca_bd_reniec_xy_r_reest), mide cada paso de la cadena:
--   total -> en t_mst_reniec_rsk (tip1 / any tip) -> con nombre depto -> matchea grado (distrito / provincia / depto).
-- El primer conteo que caiga a ~0 marca donde se rompe. Read-only, 7 filas.
-- Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e14_traza_fallback
WITH camp AS (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
),
sinr AS (
  SELECT c.kv
  FROM camp c
  JOIN      d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
  WHERE r.key_value IS NULL
),
rn AS (
  SELECT key_value, tip_doc,
         upper(regexp_replace(normalize(trim(dep_ubi_domicilio), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(pro_ubi_domicilio), NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(dis_ubi_domicilio), NFD), '\p{M}', '')) AS dist_n
  FROM e_perm_aws.t_mst_reniec_rsk
),
gd AS (
  SELECT DISTINCT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
                  upper(regexp_replace(normalize(trim(provincia),    NFD), '\p{M}', '')) AS prov_n,
                  upper(regexp_replace(normalize(trim(distrito),     NFD), '\p{M}', '')) AS dist_n
  FROM disc_model_owner.grado_elnino_ubigeo_v3
)
SELECT '1_sinr_total' AS k, CAST(COUNT(*) AS varchar) AS v FROM sinr
UNION ALL SELECT '2_en_reniec_tip1',  CAST(COUNT(DISTINCT s.kv) AS varchar) FROM sinr s JOIN rn ON rn.key_value = s.kv AND rn.tip_doc = '1'
UNION ALL SELECT '3_en_reniec_anytip',CAST(COUNT(DISTINCT s.kv) AS varchar) FROM sinr s JOIN rn ON rn.key_value = s.kv
UNION ALL SELECT '4_tip1_con_depname',CAST(COUNT(DISTINCT s.kv) AS varchar) FROM sinr s JOIN rn ON rn.key_value = s.kv AND rn.tip_doc = '1' WHERE rn.dep_n <> ''
UNION ALL SELECT '5_match_grado_dist',CAST(COUNT(DISTINCT s.kv) AS varchar) FROM sinr s JOIN rn ON rn.key_value = s.kv AND rn.tip_doc = '1' JOIN gd ON gd.dep_n = rn.dep_n AND gd.prov_n = rn.prov_n AND gd.dist_n = rn.dist_n
UNION ALL SELECT '6_match_grado_prov',CAST(COUNT(DISTINCT s.kv) AS varchar) FROM sinr s JOIN rn ON rn.key_value = s.kv AND rn.tip_doc = '1' JOIN (SELECT DISTINCT dep_n, prov_n FROM gd) gp ON gp.dep_n = rn.dep_n AND gp.prov_n = rn.prov_n
UNION ALL SELECT '7_match_grado_dep', CAST(COUNT(DISTINCT s.kv) AS varchar) FROM sinr s JOIN rn ON rn.key_value = s.kv AND rn.tip_doc = '1' JOIN (SELECT DISTINCT dep_n FROM gd) gx ON gx.dep_n = rn.dep_n
ORDER BY k
