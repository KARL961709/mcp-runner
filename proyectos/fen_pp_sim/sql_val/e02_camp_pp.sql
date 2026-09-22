-- e02_camp_pp.sql | campana PP producto=PP subproducto=PP 202609: volumen, llave subject_id y su formato, y reparto por tipo y departamento
SELECT 'A_total' AS bloque, CAST(COUNT(*) AS varchar) AS a, CAST(COUNT(DISTINCT subject_id) AS varchar) AS b, CAST(MIN(length(subject_id)) AS varchar) AS c, CAST(MAX(length(subject_id)) AS varchar) AS d
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
UNION ALL
SELECT 'B_por_tipo', tipo, CAST(COUNT(*) AS varchar), '', ''
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
GROUP BY tipo
UNION ALL
SELECT 'C_top_dep', ubigeo_dep, CAST(COUNT(*) AS varchar), '', ''
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
GROUP BY ubigeo_dep
ORDER BY bloque, a
