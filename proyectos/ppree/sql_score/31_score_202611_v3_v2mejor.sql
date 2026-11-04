-- ============================================================================
-- 31. scr_stk_ree_pp_cal_202611_v3 -- la cadena V2-MEJOR aplicada sobre el _v2.
--
--   GENERADO por 137_genera_sql_202611_v3.py leyendo ESPECIFICACION.json r9 de la
--   version elegida. No se edita a mano: los parametros se asertan contra el
--   artefacto antes de escribir el archivo.
--
-- LEE    disc_model_owner.scr_stk_ree_pp_cal_202611_v2   (prob_modelo, celda, llaves)
--        e_perm_aws.t_mst_bcrp_rsk                       (porc_ipc, 14 meses por f_t)
-- ESCRIBE disc_model_owner.scr_stk_ree_pp_cal_202611_v3  (misma forma que el _v2)
--
-- LO QUE DEL _v2 NO SE REUTILIZA, Y POR QUE. Sus columnas prob_modelo_cal,
--   prob_modelo_cal_smacro y prob_modelo_cal_freeze son la cadena V1: calibracion
--   BETA (ln p y ln(1-p) por separado) y Vasicek con un rho UNICO de 0.0380301160.
--   Medido sobre las 10 filas de muestra: el corrimiento de macro en probit es el
--   MISMO numero en DEP y en NO DEP (1e-16), lo que la cadena V2 no puede producir
--   porque divide por sqrt(1-rho) de cada celda, y al invertirlo con la forma de V1
--   devuelve trf_macro01 con 5e-10 de error. O sea trf_macro01 es el f_t de V1 en
--   escala Z del factor sistemico, no un corrimiento de probit, y trf_macro02 es su
--   insumo macro (MA6 lag5 de porc_ipc, evaluado en 202610 para el vivo y en 202608
--   para el freeze). Ninguno de los dos sirve como f_t de esta cadena. El sufijo _v2
--   del nombre es la version del BUILD, no la version del modelo.
--
-- CADENA (V2-MEJOR, decidida el 2026-11-04)
--   pcal = 1/(1+exp(-(a*logit(prob_modelo) + b)))           Platt COMUN a las 2 celdas
--   pd   = max(piso, Phi((Phi^-1(pcal) + delta_celda + lambda*f_t)/sqrt(1-rho_celda)))
--   f_t  = max(cap_piso, beta*(MA3(infl interanual 12m, lag 0) - mu))   solo piso
--     a      +0.8010340076      b      -2.1828446667
--     delta  DEP +0.0185228999  NO DEP +0.0872494825
--     rho    DEP 0.0798680000   NO DEP 0.0703540000
--     lambda 1.00   beta 0.0538554432   mu 2.1022638452   cap_piso -0.0303843813   piso 0.0005
--   rho NO cambia respecto de 21_score_v1v2platt.sql: es el mismo parametro (CRE31.16
--   other retail evaluado en la LRA de cada celda). El artefacto lo lleva con cuatro
--   decimales mas y la diferencia mueve la PD menos de 1e-8, asi que se escribe el
--   valor del SQL desplegado para que el diff contra el no muestre ruido.
--
-- QUE CAMBIA CONTRA EL _v2
--   calibrador   beta por celda  ->  Platt COMUN
--   anclaje      delta de V1     ->  delta por celda re-resuelto sobre el Platt comun
--   macro        f_t de V1 (Z, MA6 lag5 mensual)  ->  f_t de V2 (MA3 lag0 interanual)
--   grupos       grupo_calibracion venia vacio    ->  se llena con los cortes ajustados
--
-- TRES COLUMNAS DE PD, QUE NO SON ALTERNATIVAS SINO USOS DISTINTOS
--   prob_modelo_cal          f_t VIVO del mes puntuado. Puede estar parada sobre la
--                            SENDA proyectada, ver abajo. NO es reproducible.
--   prob_modelo_cal_smacro   sin overlay (f_t = 0). Es el nivel del ancla, para diagnostico.
--   prob_modelo_cal_freeze   f_t congelado en 202609, el ancla de la calibracion. Es la
--                            APTA PARA CAMPANA y la unica reproducible.
--
-- EL CALENDARIO, Y POR QUE LA COLUMNA VIVA NO ES REPRODUCIBLE. La cadena usa MA3
--   lag 0, asi que para el mes M necesita el porc_ipc DE M, que el INEI publica el
--   dia 1 de M+1. Pero t_mst_bcrp_rsk no se queda en lo observado: carga tambien la
--   SENDA mensualizada del vintage vigente, de modo que el f_t vivo SALE aunque el mes
--   no exista todavia como dato. Medido el 2026-11-04: la tabla llega a 202612, el MA3
--   vivo de 202611 da 4.6882802298 y su f_t +0.1392710585.
--   CONSECUENCIA: cuando el mes se publique, el realizado reemplaza la proyeccion y
--   prob_modelo_cal CAMBIA para el mismo mes sin que nadie toque nada. Por eso
--   extra_02 marca MACRO_VIVA_SENDA cuando el mes puntuado es posterior a 202609, que es
--   el ultimo mes OBSERVADO verificado en la fuente primaria. La bandera viaja CON el
--   dato, que es donde sirve.
--   El f_t congelado no tiene ese problema y entra por CROSS JOIN a proposito: si
--   falta la macro de 202609 la tabla sale VACIA, que es la falla ruidosa.
--
-- CORTES DE GRUPO sobre puntuacion_cal_freeze: 997|987|975|944|940|850
--   G5 sube de 924 a 940. Es el unico corte que se mueve y el unico grupo que excedia
--   el apetito (RD 7.47 pct con IC95 bajo en 6.31 contra 5.80 de apetito).
--   El grupo calculado sobre la puntuacion VIVA va en extra_03, vacio si no hay macro.
--
-- GRANO. Transformacion 1 a 1 del _v2: no agrupa ni filtra. Si el _v2 trae duplicados
--   por llave, el _v3 trae los mismos. V8_qa_202611_v3.sql lo mide.
-- ============================================================================
CREATE TABLE disc_model_owner.scr_stk_ree_pp_cal_202611_v3
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['p_codmes']) AS
WITH spv AS (
  SELECT DISTINCT CAST(cod_mes AS VARCHAR) AS cmv FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v2
),
spz AS (
  SELECT '202609' AS cmz
),
yyv AS (
  SELECT c.cmv AS cm, t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy
  FROM spv c
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.cmv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k, DATE_PARSE(c.cmv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.cmv, t.k
  HAVING COUNT(m.porc_ipc) = 12
),
ftv AS (
  SELECT cm,
         AVG(yy) AS ma3,
         GREATEST(-0.0303843813, 0.0538554432 * (AVG(yy) - 2.1022638452)) AS f_t
  FROM yyv
  GROUP BY cm
  HAVING COUNT(yy) = 3
),
yyz AS (
  SELECT c.cmz AS cm, t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy
  FROM spz c
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.cmz, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k, DATE_PARSE(c.cmz, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.cmz, t.k
  HAVING COUNT(m.porc_ipc) = 12
),
ftz AS (
  SELECT cm,
         AVG(yy) AS ma3,
         GREATEST(-0.0303843813, 0.0538554432 * (AVG(yy) - 2.1022638452)) AS f_t
  FROM yyz
  GROUP BY cm
  HAVING COUNT(yy) = 3
),
b AS (
  SELECT v.*,
         CASE WHEN UPPER(TRIM(COALESCE(v.woe_trf_tipo_ingreso_dep, ''))) = 'DEP' THEN 'DEP' ELSE 'NO DEP' END AS celda,
         fv.f_t AS ft_viv, fv.ma3 AS ma3_viv,
         fz.f_t AS ft_frz, fz.ma3 AS ma3_frz,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, v.prob_modelo)) AS ps
  FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v2 v
  LEFT JOIN ftv fv ON fv.cm = CAST(v.cod_mes AS VARCHAR)
  CROSS JOIN ftz fz
),
c AS (
  SELECT b.*,
         CASE WHEN b.prob_modelo IS NULL THEN CAST(NULL AS DOUBLE)
              ELSE GREATEST(1e-12, LEAST(1.0 - 1e-12,
                     1.0 / (1.0 + exp(-(0.8010340076 * ln(b.ps / (1.0 - b.ps)) + (-2.1828446667))))))
         END AS pcal,
         CASE WHEN b.celda = 'DEP' THEN 0.0185228999 ELSE 0.0872494825 END AS dl,
         CASE WHEN b.celda = 'DEP' THEN sqrt(1.0 - 0.0798680000) ELSE sqrt(1.0 - 0.0703540000) END AS sq
  FROM b
),
q AS (
  SELECT c.*,
         CASE WHEN c.pcal IS NULL OR c.ft_viv IS NULL THEN CAST(NULL AS DOUBLE)
              ELSE GREATEST(0.0005, LEAST(0.9999, normal_cdf(0.0, 1.0,
                     (inverse_normal_cdf(0.0, 1.0, c.pcal) + c.dl + 1.00 * c.ft_viv) / c.sq)))
         END AS pdv,
         CASE WHEN c.pcal IS NULL THEN CAST(NULL AS DOUBLE)
              ELSE GREATEST(0.0005, LEAST(0.9999, normal_cdf(0.0, 1.0,
                     (inverse_normal_cdf(0.0, 1.0, c.pcal) + c.dl) / c.sq)))
         END AS pds,
         CASE WHEN c.pcal IS NULL OR c.ft_frz IS NULL THEN CAST(NULL AS DOUBLE)
              ELSE GREATEST(0.0005, LEAST(0.9999, normal_cdf(0.0, 1.0,
                     (inverse_normal_cdf(0.0, 1.0, c.pcal) + c.dl + 1.00 * c.ft_frz) / c.sq)))
         END AS pdz
  FROM c
),
r AS (
  SELECT q.*,
         CAST(ROUND(1000.0 * (1.0 - q.pdv)) AS INTEGER) AS scv,
         CAST(ROUND(1000.0 * (1.0 - q.pds)) AS INTEGER) AS scs,
         CAST(ROUND(1000.0 * (1.0 - q.pdz)) AS INTEGER) AS scz
  FROM q
)
SELECT f.cod_mes,
       f.key_value,
       f.cod_tip_doc,
       f.cod_cli,
       f.prob_modelo,
       f.puntuacion,
       f.modelo,
       f.fec_replica,
       f.grupo_ejec,
       f.segmento,
       f.orden,
       CASE WHEN f.scz IS NULL THEN ''
            WHEN f.scz >= 997 THEN 'G1'
            WHEN f.scz >= 987 THEN 'G2'
            WHEN f.scz >= 975 THEN 'G3'
            WHEN f.scz >= 944 THEN 'G4'
            WHEN f.scz >= 940 THEN 'G5'
            WHEN f.scz >= 850 THEN 'G6'
            ELSE 'R' END AS grupo_calibracion,
       f.pdv AS prob_modelo_cal,
       f.scv AS puntuacion_cal,
       f.pds AS prob_modelo_cal_smacro,
       f.scs AS puntuacion_cal_smacro,
       f.pdz AS prob_modelo_cal_freeze,
       f.scz AS puntuacion_cal_freeze,
       'V2-MEJOR platt comun 2026-11-04' AS extra_01,
       CONCAT(CASE WHEN f.ft_viv IS NULL THEN 'SIN_MACRO_VIVO'
                   WHEN CAST(f.cod_mes AS VARCHAR) > '202609' THEN 'MACRO_VIVA_SENDA'
                   ELSE 'MACRO_VIVA_OBS' END,
              CASE WHEN f.prob_modelo IS NULL THEN '|SIN_PROB' ELSE '' END) AS extra_02,
       CASE WHEN f.scv IS NULL THEN ''
            WHEN f.scv >= 997 THEN 'G1'
            WHEN f.scv >= 987 THEN 'G2'
            WHEN f.scv >= 975 THEN 'G3'
            WHEN f.scv >= 944 THEN 'G4'
            WHEN f.scv >= 940 THEN 'G5'
            WHEN f.scv >= 850 THEN 'G6'
            ELSE 'R' END AS extra_03,
       'freeze_202609|ult_obs_202609' AS extra_04,
       'cortes_997|987|975|944|940|850' AS extra_05,
       f.ft_viv  AS trf_macro01,
       f.ma3_viv AS trf_macro02,
       f.ft_frz  AS trf_macro01_freeze,
       f.ma3_frz AS trf_macro02_freeze,
       f.woe_avg_dda_tlc_12m,
       f.woe_rat_miemsup2r,
       f.woe_cnt_gestiones_6m,
       f.woe_std_datraso_rd_u1a,
       f.woe_num_inc_sld_tip_pas_12m,
       f.woe_max_clfibk_06m,
       f.woe_rat_sld_pp_u1m_tc_ibk,
       f.woe_flg_labdp,
       f.woe_avg_decrsld12m,
       f.woe_cnt_deccorreg_12m,
       f.woe_max_dias_atraso_no_ibk_3m,
       f.woe_avg_diamorasldppibk_12m,
       f.woe_mto_dda_otr_emp_12m,
       f.woe_ant_profesional,
       f.woe_mto_totalrec06m,
       f.woe_rat_maxsldppibk_03m,
       f.woe_rat_comparacion_u1m_u12m,
       f.woe_ant_primer_producto,
       f.woe_min_pasctasld_12m,
       f.woe_avg_slddispefpn_u6m,
       f.woe_sld_beta_pc_pp_1a,
       f.woe_num_vehiculos,
       f.woe_num_edad,
       f.woe_var_ent_dist_rd_1a,
       f.woe_max_dda_pp_rat_9m,
       f.woe_rat_actpas_03m,
       f.woe_avg_rat_dispefpnj_u1a,
       f.woe_num_titulo_prof,
       f.woe_rat_saldo_rt_t1_t12,
       f.woe_porc_max_sldrsg_06m,
       f.woe_cnt_dectctotal_12m,
       f.woe_flg_pasibk,
       f.woe_porc_avg_sld_rd_6m,
       f.woe_med_sld_sa_hip_3i_6m,
       f.woe_cnt_atraso_01_aj,
       f.woe_num_inmuebles,
       f.woe_avg_trxtot12m,
       f.woe_porc_avg_pctusotctot_u1a,
       f.woe_cnt_dias_adelanto_atraso,
       f.woe_cnt_mespeornorssff_12m,
       f.woe_rat_svotrppeallsf_3m,
       f.woe_med_dec_sld_tarj_3i_6m,
       f.woe_trf_mtomax_grifos_pos12m,
       f.woe_trf_far_mtomax_med_12m,
       f.woe_trf_mtot_tc_retail_pos1m,
       f.woe_trf_prm_restaur_pos_6m,
       f.woe_trf_mtoprm_altagama_12m,
       f.woe_trf_mto_salud_u24m,
       f.woe_trf_tipo_ingreso_dep,
       CAST(f.p_codmes AS VARCHAR) AS p_codmes
FROM r f