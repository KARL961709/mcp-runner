-- ============================================================================
-- Q02. RIESGO OBSERVADO POR CELDA DE ARQUETIPO - IBK CONTRA SS.FF.
--   scan: ds_adm_vcnbank_tc_cal
--   pregunta: el arquetipo separa riesgo fuera de Interbank
--
--   COHORTES MADURAS SOLAMENTE. target_12m IS NOT NULL es la definicion de
--   madurez de la tabla: un mes inmaduro trae NULL, nunca 0, asi que este filtro
--   es la frontera y no un recorte a mano.
--
--   clean_sf reconstruye flg_clean SIN f_entidades. Hay que hacerlo asi porque
--   flg_clean manda al 99 a toda entidad fuera del panel de 5, y con eso SS.FF.
--   no tiene bucket limpio en el que mirarse. Sobre IBK clean_sf tiene que
--   reproducir flg_clean exacto: la columna chk_ibk_igual lo verifica en la
--   misma salida en vez de dejarlo dicho.
-- ============================================================================
WITH b AS (
     SELECT CASE WHEN entidad = '00002'                             THEN '1_IBK'
                 WHEN entidad IN ('00001','00004','00006','00142')  THEN '2_PANEL_RESTO'
                 ELSE                                                    '3_OTRAS_SSFF' END  AS grp,
            coalesce(seg_arq_salud, '(nulo)')                                                AS arq,
            codmes_mrm,
            target_12m,
            pd_raw,
            pd_cal_vigente,
            flg_clean,
            CASE WHEN f_banc_u12m = 1 OR f_sin_linea = 1 THEN 99
                 WHEN f_edad_rango + f_cast_ori + f_jud_ori + f_ref_ori + f_ree_ori
                    + f_malo_ori + f_cast_u24m + f_jud_u24m + f_ref_u6m + f_mayor_cpp
                    + f_gar_conv + f_fraude + f_swap_u12m = 0 THEN 1 ELSE 0 END              AS clean_sf
       FROM disc_model_owner.ds_adm_vcnbank_tc_cal
     )
SELECT v.ventana,
       b.grp,
       b.arq,
       count(*)                                                                  AS n,
       round(100.0 * avg(b.target_12m), 4)                                       AS rd_12m,
       round(100.0 * avg(b.pd_raw), 4)                                           AS pd_raw_media,
       round(100.0 * avg(b.pd_cal_vigente), 4)                                   AS pd_vigente_media,
       sum(CASE WHEN b.grp = '1_IBK' AND b.clean_sf <> b.flg_clean THEN 1 ELSE 0 END) AS chk_ibk_igual
  FROM b
 CROSS JOIN (VALUES ('1_VENTANA_202411'), ('2_TODO_MADURO')) AS v (ventana)
 WHERE b.clean_sf = 1
   AND b.pd_raw IS NOT NULL
   AND b.target_12m IS NOT NULL
   AND (v.ventana = '2_TODO_MADURO' OR b.codmes_mrm >= '202411')
 GROUP BY v.ventana, b.grp, b.arq
 ORDER BY v.ventana, b.grp, b.arq
