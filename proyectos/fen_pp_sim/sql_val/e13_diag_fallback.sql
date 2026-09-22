-- e13_diag_fallback.sql | por que el fallback por nombre matcheo 0 (todo el 10% sin-reest cayo a 'none').
-- A: nombres de departamento (normalizados NFD) de los clientes SIN reest (lado campana). '(blank)' = sin geografia.
-- B: departamentos (normalizados NFD) presentes en grado_elnino_ubigeo_v3 (lado grado).
-- Si A domina '(blank)' -> no hay geografia, fallback imposible (none es correcto). Si A trae nombres que estan en B -> bug de join.
-- Read-only, ~50 filas. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e13_diag_fallback
WITH camp AS (
  SELECT substr(subject_id, 3) AS kv,
         upper(regexp_replace(normalize(trim(MAX(ubigeo_dep)), NFD), '\p{M}', '')) AS dep_n
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
  GROUP BY substr(subject_id, 3)
),
sinr AS (
  SELECT c.kv, c.dep_n
  FROM camp c
  JOIN      d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
  WHERE r.key_value IS NULL
)
SELECT 'A_campana_sinreest' AS bloque, COALESCE(NULLIF(dep_n, ''), '(blank)') AS a, CAST(COUNT(*) AS varchar) AS b
FROM sinr GROUP BY COALESCE(NULLIF(dep_n, ''), '(blank)')
UNION ALL
SELECT 'B_grado_deptos', upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')), CAST(COUNT(*) AS varchar)
FROM disc_model_owner.grado_elnino_ubigeo_v3
GROUP BY upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', ''))
ORDER BY bloque ASC, CAST(b AS bigint) DESC
