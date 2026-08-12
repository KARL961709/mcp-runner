-- 70_cal.sql | maestro unico de la calibracion. Consolida poblacion, filtros, target, drivers y PD cruda.
-- TRES BUCKETS, el 98 no existe. flg_clean funde limpieza y nada mas. La disponibilidad va en flg_calib.
--   flg_clean  99  algun CASO3 = 1. Otra poblacion, no vuelve ni calibrando dirty
--              1   pasa todos los CASO2
--              0   resto
--   flg_calib  1   flg_clean distinto de 99, con pd_raw y sin fallas de dato ni de madurez
-- Reconciliacion exigida: 99 mas 1 mas 0 igual al universo del codmes, sin solape.
-- CASO3 son DOS y uno esta sin firmar: f_entidades quedo en 99 sin pasar el mismo escrutinio que bajo a edad de 99 a
-- dirty, y la q91 midio que excluye poblacion MAS riesgosa (bad rate 13.10 contra 10.37 de la base). Por eso se emite
-- ademas flg_clean_sin_ent, que lo trata como dirty: si la decision cambia, no hay que reconstruir.
-- flg_clean_macro es la variante para la serie larga. Suelta fraude y los swaps, que solo tienen fuente desde 202106
-- y 202201, para que el modelo macro y rho se estimen sobre los 77 meses y no sobre los 42 que deja el juego completo.
-- La brecha entre las dos esta acotada: fraude vale a lo sumo 0.11 pp de LRA.
CREATE TABLE disc_model_owner.ds_adm_tcnb_cal
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_cal/'
) AS
SELECT f.tip_doc,
       f.id_value,
       f.entidad,
       f.prelacion_cod,
       f.prelacion_sld,
       f.saldo_tc_ori,
       f.f_edad_rango, f.f_edad_nomatch, f.f_banc_u12m,
       f.f_cast_ori, f.f_jud_ori, f.f_ref_ori, f.f_ree_ori, f.f_malo_ori,
       f.f_cast_u24m, f.f_jud_u24m, f.f_ref_u6m, f.f_mayor_cpp,
       f.f_gar_conv, f.f_fraude, f.f_entidades,
       f.f_swap_u12m, f.f_swap_p12m, f.f_repro_p12m,
       f.ctrl_sin_fraude, f.ctrl_sin_swap,
       f.falla_sin_cuc, f.falla_sin_sbs, f.falla_sin_historia,
       t.max_dm_fut, t.missing_12, t.f_evento_fut, t.falla_madurez,
       t.target_12m, t.target_12m_corr, t.target_12m_b30, t.target_12m_full,
       d.tipo_ingreso, d.tipo_ingreso_dep, d.sit_lab_crudo, d.fuente_ingreso,
       d.seg_arq_salud, d.region_12m_prio, d.var_cuali_far_rubrofrec_9m_v3, d.flg_hosp_12m,
       d.falla_sin_tipo_ingreso, d.ctrl_inca_sin_dato, d.ctrl_fuente_nueva,
       q.pd_raw, q.puntuacion, q.pd_cal_vigente, q.puntuacion_cal_vigente, q.grupo_cal_vigente,
       q.sitlab_score, q.macro_inflacion, q.macro_desempleo, q.macro_desempleo_6, q.falla_sin_score,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 99
                 WHEN f.f_edad_rango + f.f_cast_ori + f.f_jud_ori + f.f_ref_ori + f.f_ree_ori
                    + f.f_malo_ori + f.f_cast_u24m + f.f_jud_u24m + f.f_ref_u6m + f.f_mayor_cpp
                    + f.f_gar_conv + f.f_fraude + f.f_swap_u12m = 0 THEN 1
                 ELSE 0 END AS INTEGER)                                                 AS flg_clean,
       CAST(CASE WHEN f.f_banc_u12m = 1 THEN 99
                 WHEN f.f_edad_rango + f.f_cast_ori + f.f_jud_ori + f.f_ref_ori + f.f_ree_ori
                    + f.f_malo_ori + f.f_cast_u24m + f.f_jud_u24m + f.f_ref_u6m + f.f_mayor_cpp
                    + f.f_gar_conv + f.f_fraude + f.f_swap_u12m + f.f_entidades = 0 THEN 1
                 ELSE 0 END AS INTEGER)                                                 AS flg_clean_sin_ent,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 99
                 WHEN f.f_edad_rango + f.f_cast_ori + f.f_jud_ori + f.f_ref_ori + f.f_ree_ori
                    + f.f_malo_ori + f.f_cast_u24m + f.f_jud_u24m + f.f_ref_u6m + f.f_mayor_cpp
                    + f.f_gar_conv = 0 THEN 1
                 ELSE 0 END AS INTEGER)                                                 AS flg_clean_macro,
       CAST(CASE WHEN (f.f_banc_u12m = 1 OR f.f_entidades = 1) THEN 0
                 WHEN q.pd_raw IS NULL THEN 0
                 WHEN f.f_edad_nomatch = 1 THEN 0
                 WHEN t.falla_madurez = 1 THEN 0
                 ELSE 1 END AS INTEGER)                                                 AS flg_calib,
       f.codmes_mrm
FROM disc_model_owner.ds_adm_tcnb_60_filtros f
LEFT JOIN disc_model_owner.ds_adm_tcnb_35_target  t ON t.tip_doc = f.tip_doc AND t.id_value = f.id_value
                            AND t.entidad = f.entidad AND t.codmes_mrm = f.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_tcnb_40_drivers d ON d.tip_doc = f.tip_doc AND d.id_value = f.id_value
                            AND d.codmes_mrm = f.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_tcnb_50_pd      q ON q.tip_doc = f.tip_doc AND q.id_value = f.id_value
                            AND q.codmes_mrm = f.codmes_mrm
