-- e05_cruce_camp_scores.sql | intento de cruce campana PP x scores por subject_id: match rate y PD PIT promedio (si la llave no es subject_id, esta falla y e01 dira la buena)
SELECT CAST(COUNT(*) AS varchar) AS n_camp,
       CAST(COUNT(s.subject_id) AS varchar) AS n_match,
       CAST(AVG(s.prob_modelo_cal_ppfacil) AS varchar) AS pd_pit_prom_ppfacil,
       CAST(AVG(s.puntuacion_modelo_cal_ppfacil) AS varchar) AS score_prom_ppfacil
FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp c
LEFT JOIN d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 s
       ON c.subject_id = s.subject_id
WHERE c.p_codmes = '202609' AND c.producto = 'PP' AND c.sub_producto = 'PP' AND c.num_carga = '2.1 Rec'
