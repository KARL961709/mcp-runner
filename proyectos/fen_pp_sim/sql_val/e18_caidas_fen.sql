-- e18_caidas_fen.sql | dimensiona la tabla de caidas por FEN y su relacion con la campaña, antes de sumarla a la base.
-- Tabla: d_perm_aws.t_edc_mo_caida_fen_2609_tmp (camp, producto, subject_id, tot_caidas[string]). Filtro: camp='2609-2REC' AND producto='PP'.
-- Chequea: (A) filas y subject_id distintos, formato del subject_id; (B) reparto por tot_caidas; (C) solape con la campaña 2.5M (ya en base vs nuevos).
-- Read-only. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e18_caidas_fen
WITH caida AS (
  SELECT DISTINCT subject_id, tot_caidas
  FROM d_perm_aws.t_edc_mo_caida_fen_2609_tmp
  WHERE camp = '2609-2REC' AND producto = 'PP'
),
camp AS (
  SELECT DISTINCT subject_id
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
)
SELECT 'A_filas' AS bloque, CAST(COUNT(*) AS varchar) AS a, '' AS b
FROM d_perm_aws.t_edc_mo_caida_fen_2609_tmp WHERE camp = '2609-2REC' AND producto = 'PP'
UNION ALL
SELECT 'A_subj_distinct_y_largo', CAST(COUNT(DISTINCT subject_id) AS varchar),
       CAST(MIN(length(subject_id)) AS varchar) || '-' || CAST(MAX(length(subject_id)) AS varchar) || ' pref=' || MAX(substr(subject_id,1,2))
FROM d_perm_aws.t_edc_mo_caida_fen_2609_tmp WHERE camp = '2609-2REC' AND producto = 'PP'
UNION ALL
SELECT 'B_tot_caidas_' || tot_caidas, CAST(COUNT(DISTINCT subject_id) AS varchar), ''
FROM d_perm_aws.t_edc_mo_caida_fen_2609_tmp WHERE camp = '2609-2REC' AND producto = 'PP' GROUP BY tot_caidas
UNION ALL
SELECT 'C_ya_en_campaña', CAST(COUNT(*) AS varchar), '' FROM caida c WHERE c.subject_id IN (SELECT subject_id FROM camp)
UNION ALL
SELECT 'C_nuevos_no_en_campaña', CAST(COUNT(*) AS varchar), '' FROM caida c WHERE c.subject_id NOT IN (SELECT subject_id FROM camp)
UNION ALL
SELECT 'C_nuevos_tot1_no_en_campaña', CAST(COUNT(*) AS varchar), '' FROM caida c WHERE c.tot_caidas='1' AND c.subject_id NOT IN (SELECT subject_id FROM camp)
ORDER BY bloque
