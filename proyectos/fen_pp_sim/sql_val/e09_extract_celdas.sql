-- e09_sanity_cobertura.sql | chequeo compacto OPCIONAL de cobertura de la campana PP 202609.
-- NO es la extraccion del simulador (esa es el CTAS e10_sim_celdas_202609, grano ubigeo x R x grado, parquet).
-- Esto son 2 filas para pegar por texto y confirmar cuantas llaves deduplicadas tienen score y R
-- (la poblacion base del simulador). Solo conteos agregados.
-- Puente e08: substr(subject_id,3)=key_value. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e09_extract_celdas
SELECT 'cobertura' AS bloque,
       CAST(COUNT(*) AS varchar)               AS llaves_dedup,
       CAST(COUNT(u.key_value) AS varchar)     AS con_score,
       CAST(COUNT(r.key_value) AS varchar)     AS con_r,
       CAST(COUNT(CASE WHEN u.key_value IS NOT NULL AND r.key_value IS NULL THEN 1 END) AS varchar) AS score_sin_r
FROM (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
) c
LEFT JOIN d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
