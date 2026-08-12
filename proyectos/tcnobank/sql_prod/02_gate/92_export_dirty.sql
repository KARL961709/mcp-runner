-- ============================================================================
-- 92. EXPORT DIRTY
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_px_dirty
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = 's3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/tcnb/dirty/') AS
SELECT
       to_hex(md5(to_utf8(tip_doc || '|' || id_value || '|' || entidad)))              AS id_hash,
       entidad, prelacion_cod, prelacion_sld, saldo_tc_ori,
       f_edad_rango, f_edad_nomatch, f_banc_u12m, f_cast_ori, f_jud_ori, f_ref_ori, f_ree_ori, f_malo_ori, f_cast_u24m, f_jud_u24m, f_ref_u6m, f_mayor_cpp, f_gar_conv, f_fraude, f_entidades, f_swap_u12m, f_swap_p12m, f_repro_p12m,
       ctrl_cast_ori_m0, ctrl_jud_ori_m0, ctrl_ref_ori_m0, ctrl_ree_ori_m0, ctrl_malo_ori_m2,
       ctrl_sin_fraude, ctrl_sin_swap, ctrl_no_consumo, ctrl_inca_sin_dato, ctrl_fuente_nueva,
       falla_sin_sbs, falla_sin_cuc, falla_sin_historia, falla_sin_tipo_ingreso,
       falla_sin_score, falla_madurez,
       missing_12, max_dm_fut, f_evento_fut,
       target_01m, target_02m, target_03m, target_04m, target_05m, target_06m, target_07m, target_08m, target_09m, target_10m, target_11m, target_12m,
       tipo_ingreso, tipo_ingreso_dep, sit_lab_crudo, fuente_ingreso,
       seg_arq_salud, region_12m_prio, var_cuali_far_rubrofrec_9m_v3, flg_hosp_12m,
       pd_raw, puntuacion, pd_cal_vigente, puntuacion_cal_vigente, grupo_cal_vigente, sitlab_score,
       macro_inflacion, macro_desempleo, macro_desempleo_6,
       flg_clean, flg_clean_sin_ent, flg_clean_macro, flg_hist, flg_calib,
       codmes_mrm
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE flg_calib = 1
