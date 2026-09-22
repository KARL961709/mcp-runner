-- e08_puente_llave.sql | encontrar el puente subject_id(66) <-> key_value(64): formato del subject_id (largo + primeros 2 chars) y prueba de join por substr(subject_id,3)=key_value
SELECT 'A_subj_fmt' AS bloque,
       CAST(length(subject_id) AS varchar) AS a,
       substr(subject_id, 1, 2) AS b,
       CAST(COUNT(*) AS varchar) AS c
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
GROUP BY length(subject_id), substr(subject_id, 1, 2)
UNION ALL
SELECT 'B_join_substr3',
       CAST(COUNT(*) AS varchar),
       CAST(COUNT(r.key_value) AS varchar),
       'match substr(subj,3)=key_value'
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp c
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r
       ON substr(c.subject_id, 3) = r.key_value
WHERE c.p_codmes = '202609' AND c.producto = 'PP' AND c.sub_producto = 'PP' AND c.num_carga = '2.1 Rec'
UNION ALL
SELECT 'C_keyval_len',
       CAST(length(key_value) AS varchar),
       CAST(COUNT(*) AS varchar),
       'largo key_value en R'
FROM disc_model_owner.mca_bd_reniec_xy_r_reest
GROUP BY length(key_value)
ORDER BY bloque, a
