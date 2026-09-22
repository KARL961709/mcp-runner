-- e11_geo_fallback.sql | exploracion para cerrar el fallback de R (todo cliente debe tener R/score directo).
-- Objetivo: quien no tiene R reestructurado (per-persona) cae al grado distrital SIN reest de grado_elnino_ubigeo_v3.
-- Necesito 4 cosas: (1) columnas de grado_elnino_ubigeo_v3, (2) geografia que trae la campana (para los sin-reest),
-- (3) columnas R/geo de mca_bd_reniec_xy_r_reest, (4) cobertura real (cuantos tienen reest vs base vs nada).
-- Read-only, ~30 filas. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e11_geo_fallback
SELECT 'A_grado_v3_cols' AS bloque, table_schema || '.' || column_name AS a, data_type AS b
FROM information_schema.columns
WHERE table_name = 'grado_elnino_ubigeo_v3' AND table_schema IN ('d_perm_aws', 'disc_model_owner')
UNION ALL
SELECT 'B_camp_geo_cols', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 't_edc_ar_camp_vars_sep2qrec_temp'
  AND regexp_like(lower(column_name), 'ubi|dep|dom|dist|prov|geo|lat|lon|region|nodo')
UNION ALL
SELECT 'C_reest_cols', column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'mca_bd_reniec_xy_r_reest'
  AND regexp_like(lower(column_name), 'nivel|label|ubi|geo|lat|lon|dep|dist|prov')
UNION ALL
SELECT 'D_cobertura' AS bloque,
       'dedup | con_row_R | reest_notnull | base_notnull' AS a,
       CAST(COUNT(*) AS varchar) || ' | ' || CAST(COUNT(r.key_value) AS varchar) || ' | ' ||
       CAST(COUNT(r.r_nivel_reest) AS varchar) || ' | ' || CAST(COUNT(r.r_nivel) AS varchar) AS b
FROM (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
) c
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON r.key_value = c.kv
GROUP BY 1, 2
ORDER BY 1, 2
