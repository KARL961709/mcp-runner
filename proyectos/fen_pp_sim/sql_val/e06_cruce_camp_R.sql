-- e06_cruce_camp_R.sql | prueba si subject_id (campana) = key_value (R): match rate campana PP x R, y reparto por r_label_reest de los que matchean
SELECT 'A_match' AS bloque, CAST(COUNT(*) AS varchar) AS a, CAST(COUNT(r.key_value) AS varchar) AS b
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp c
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.subject_id = r.key_value
WHERE c.p_codmes = '202609' AND c.producto = 'PP' AND c.sub_producto = 'PP' AND c.num_carga = '2.1 Rec'
UNION ALL
SELECT 'B_por_r_reest', COALESCE(r.r_label_reest, 'NO_MATCH'), CAST(COUNT(*) AS varchar)
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp c
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON c.subject_id = r.key_value
WHERE c.p_codmes = '202609' AND c.producto = 'PP' AND c.sub_producto = 'PP' AND c.num_carga = '2.1 Rec'
GROUP BY COALESCE(r.r_label_reest, 'NO_MATCH')
ORDER BY bloque, a
