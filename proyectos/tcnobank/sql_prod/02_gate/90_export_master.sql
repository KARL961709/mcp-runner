-- 90_export_master.sql | maestro completo, una fila por alta y entidad. Sin key_value: el export no saca identidad.
-- Se exporta hash de llave y no la llave: el canal de vuelta no lleva identidad.
CREATE TABLE disc_model_owner.ds_adm_tcnb_px_master
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_px_master/'
) AS
SELECT to_hex(md5(to_utf8(tip_doc || '|' || id_value || '|' || entidad)))               AS id_hash,
       entidad, prelacion_cod, prelacion_sld, saldo_tc_ori,
       f_edad_rango, f_edad_nomatch, f_banc_u12m, f_cast_ori, f_jud_ori, f_ref_ori, f_ree_ori,
       f_malo_ori, f_cast_u24m, f_jud_u24m, f_ref_u6m, f_mayor_cpp, f_gar_conv, f_fraude,
       f_entidades, f_swap_u12m, f_swap_p12m, f_repro_p12m,
       ctrl_sin_fraude, ctrl_sin_swap, ctrl_inca_sin_dato, ctrl_fuente_nueva,
       falla_sin_cuc, falla_sin_sbs, falla_sin_historia, falla_sin_tipo_ingreso, falla_sin_score,
       max_dm_fut, missing_12, f_evento_fut, falla_madurez,
       target_12m, target_12m_corr, target_12m_b30, target_12m_full,
       tipo_ingreso, tipo_ingreso_dep, sit_lab_crudo, fuente_ingreso,
       seg_arq_salud, region_12m_prio, var_cuali_far_rubrofrec_9m_v3, flg_hosp_12m,
       pd_raw, puntuacion, pd_cal_vigente, puntuacion_cal_vigente, grupo_cal_vigente, sitlab_score,
       macro_inflacion, macro_desempleo, macro_desempleo_6,
       flg_clean, flg_clean_sin_ent, flg_clean_macro, flg_calib,
       codmes_mrm
FROM disc_model_owner.ds_adm_tcnb_cal
WHERE 1 = 1
