-- ============================================================================
-- 70. ENSAMBLADO FINAL - TABLA DE CALIBRACION
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_cal
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_vcnbank_tc_cal/'
) AS
SELECT f.tip_doc,
       f.id_value,
       f.entidad,
       d.prelacion_cod,
       d.prelacion_sld,
       f.saldo_tc_ori,
       f.f_edad_rango, f.f_edad_nomatch, f.f_banc_u12m, f.f_cast_ori, f.f_jud_ori, f.f_ref_ori, f.f_ree_ori, f.f_malo_ori, f.f_cast_u24m, f.f_jud_u24m, f.f_ref_u6m, f.f_mayor_cpp, f.f_gar_conv, f.f_fraude, f.f_entidades, f.f_swap_u12m, f.f_swap_p12m, f.f_repro_p12m,
       f.ctrl_cast_ori_m0, f.ctrl_jud_ori_m0, f.ctrl_ref_ori_m0, f.ctrl_ree_ori_m0, f.ctrl_malo_ori_m0,
       f.ctrl_sin_fraude, f.ctrl_sin_swap, f.ctrl_no_consumo,
       f.falla_sin_sbs, f.falla_sin_cuc, f.falla_sin_historia,
       t.missing_12, t.max_dm_fut, t.f_evento_fut, t.falla_madurez,
       t.target_01m, t.target_02m, t.target_03m, t.target_04m, t.target_05m, t.target_06m, t.target_07m, t.target_08m, t.target_09m, t.target_10m, t.target_11m, t.target_12m,
       v.tipo_ingreso, v.tipo_ingreso_dep, v.sit_lab_crudo, v.fuente_ingreso,
       v.seg_arq_salud, v.region_12m_prio, v.var_cuali_far_rubrofrec_9m_v3, v.flg_hosp_12m,
       v.falla_sin_tipo_ingreso, v.ctrl_inca_sin_dato, v.ctrl_fuente_nueva,
       q.pd_raw, q.puntuacion, q.pd_cal_vigente, q.puntuacion_cal_vigente,
       q.grupo_cal_vigente, q.sitlab_score,
       q.macro_inflacion, q.macro_desempleo, q.macro_desempleo_6, q.falla_sin_score,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 99
                 WHEN f.f_edad_rango + f.f_cast_ori + f.f_jud_ori + f.f_ref_ori + f.f_ree_ori + f.f_malo_ori + f.f_cast_u24m + f.f_jud_u24m + f.f_ref_u6m + f.f_mayor_cpp + f.f_gar_conv + f.f_fraude + f.f_swap_u12m = 0 THEN 1 ELSE 0 END AS INTEGER)                             AS flg_clean,
       CAST(CASE WHEN f.f_banc_u12m = 1 THEN 99
                 WHEN f.f_edad_rango + f.f_cast_ori + f.f_jud_ori + f.f_ref_ori + f.f_ree_ori + f.f_malo_ori + f.f_cast_u24m + f.f_jud_u24m + f.f_ref_u6m + f.f_mayor_cpp + f.f_gar_conv + f.f_fraude + f.f_swap_u12m + f.f_entidades = 0 THEN 1 ELSE 0 END AS INTEGER)             AS flg_clean_sin_ent,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 99
                 WHEN f.f_edad_rango + f.f_cast_ori + f.f_jud_ori + f.f_ref_ori + f.f_ree_ori + f.f_malo_ori + f.f_cast_u24m + f.f_jud_u24m + f.f_ref_u6m + f.f_mayor_cpp + f.f_gar_conv = 0 THEN 1 ELSE 0 END AS INTEGER)                             AS flg_clean_macro,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 0
                 WHEN q.pd_raw IS NULL           THEN 0
                 WHEN f.f_edad_nomatch = 1       THEN 0
                 WHEN t.falla_madurez = 1        THEN 0
                 ELSE 1 END AS INTEGER)                                                AS flg_calib,
       f.codmes_mrm
FROM disc_model_owner.ds_adm_vcnbank_tc_60_filtros f
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_65_dedup   d ON d.tip_doc = f.tip_doc AND d.id_value = f.id_value
                            AND d.entidad = f.entidad AND d.codmes_mrm = f.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_50_targets t ON t.tip_doc = f.tip_doc AND t.id_value = f.id_value
                            AND t.entidad = f.entidad AND t.codmes_mrm = f.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_30_drivers v ON v.tip_doc = f.tip_doc AND v.id_value = f.id_value
                            AND v.codmes_mrm = f.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_40_pdraw   q ON q.tip_doc = f.tip_doc AND q.id_value = f.id_value
                            AND q.codmes_mrm = f.codmes_mrm
