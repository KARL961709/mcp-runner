-- ============================================================================
-- 71. SCORE CALIBRADO SOBRE TODA LA TABLA ds_
--   scan: ds_adm_vcnbank_tc_cal
--   ancla: los coeficientes son los del pipeline, sin reajustar ninguno.
--          calibracion_beta.json y pit_transformation.json
--
--   UNA FILA POR CADA FILA DEL ds_. Donde hay pd_raw sale score, donde no sale
--   NULL con motivo_sin_score. Asi un join contra el ds_ no pierde llaves en
--   silencio. Medido antes de escribir esto: 1,539,693 filas tienen pd_raw y
--   las 1,539,693 salen con score, en las 25 entidades y en los tres buckets de
--   flg_clean. Las otras 11,980,397 llevan falla_sin_score = 1, que explica la
--   ausencia al 100 por ciento. No es una limitacion de la calibracion sino de
--   la fuente: esas filas nunca fueron scoreadas por el modelo de produccion,
--   y sin pd_raw no hay nada que calibrar.
--
--   CADENA:
--     pd_raw -> BetaCal(nodo) -> corrimiento probit(nodo) -> delta_0 + driver
--            -> Vasicek PIT(F del mes) -> prob_modelo_cal -> puntuacion_cal
--     rho 0.0332  lambda 1  LRA 0.0698337961  delta_0 0.182367613  driver seg_arq_salud='C' -0.0350174239
--
--   EL NODO SE RECONSTRUYE. 16_nodo.sql pone SIN_ALCANCE fuera de la entidad
--   00002, pero sus cinco banderas existen para las 25 entidades sin un solo
--   nulo porque 16_nodo las coalesce a 0. Aca se replican las 20 ramas: se
--   verifico que nodo_calc reproduce nodo_final en las 1,690,263 filas de IBK
--   sin una discrepancia. nodo_final viaja al lado para que el chequeo se pueda
--   repetir sobre la tabla escrita.
--
--   FUERA DE IBK ESTO ES EXTRAPOLACION, que es lo unico que produccion puede
--   hacer: no hay forma de calibrar distinto por entidad. Al leerlo hay que
--   tener presente que las tres fuentes del nodo son internas de Interbank y
--   que entre 55 y 63 por ciento de los clientes de otros bancos no aparecen en
--   ninguna, asi que a ellos el nodo se les arma desde la ausencia y caen en N3.
--   ctrl_nodo_n_fuentes cuenta en cuantas de las tres se los vio, y
--   ctrl_nodo_observado marca con 0 exactamente a los que no estan en ninguna.
--
--   El F del mes viaja precalculado en convencion Vasicek, ya centrado y topeado
--   a [-0.725565158, 0.2705294769]. Recalcularlo aca seria un lugar mas donde equivocarse.
-- ============================================================================
CREATE TABLE disc_model_owner.scr_adm_vcnbank_tc_cal AS
WITH ft AS (
     SELECT codmes, f_mes
       FROM (VALUES
            ('202303', -0.725565158),
            ('202304', -0.725565158),
            ('202305', -0.725565158),
            ('202306', -0.725565158),
            ('202307', -0.725565158),
            ('202308', -0.725565158),
            ('202309', -0.6219053639),
            ('202310', -0.4440329607),
            ('202311', -0.2714095039),
            ('202312', -0.1826622359),
            ('202401', -0.0730589765),
            ('202402', -0.0689340902),
            ('202403', -0.0087596719),
            ('202404', 0.125568068),
            ('202405', 0.2313565154),
            ('202406', 0.1767349461),
            ('202407', 0.2044853755),
            ('202408', 0.2257544382),
            ('202409', 0.2705294769),
            ('202410', 0.2148766685),
            ('202411', 0.1373401029),
            ('202412', 0.1749871898),
            ('202501', 0.1979078941),
            ('202502', 0.2671184877),
            ('202503', 0.2705294769),
            ('202504', 0.2359181893),
            ('202505', 0.217751397),
            ('202506', 0.2221284248),
            ('202507', 0.2214549678),
            ('202508', 0.2705294769),
            ('202509', 0.2705294769),
            ('202510', 0.2705294769),
            ('202511', 0.2705294769),
            ('202512', 0.2705294769),
            ('202601', 0.2705294769),
            ('202602', 0.0239381285),
            ('202603', -0.2535885874),
            ('202604', -0.3064478262),
            ('202605', -0.2798003393)
            ) AS t (codmes, f_mes)
     ),
base AS (
     SELECT b.tip_doc,
            b.id_value,
            b.entidad,
            b.flg_clean,
            b.flg_calib,
            b.pd_raw,
            b.falla_sin_score,
            b.nodo_final,
            b.pd_cal_vigente,
            b.puntuacion_cal_vigente,
            b.seg_arq_salud,
            b.codmes_mrm,
            f.f_mes,
            CAST((1 - b.ctrl_sin_360) + (1 - b.ctrl_sin_cta_sueldo)
                 + (1 - b.ctrl_sin_plin) AS INTEGER)                              AS ctrl_nodo_n_fuentes,
            CAST(CASE WHEN b.ctrl_sin_360 = 1 AND b.ctrl_sin_cta_sueldo = 1
                       AND b.ctrl_sin_plin = 1 THEN 0 ELSE 1 END AS INTEGER)      AS ctrl_nodo_observado,
            CASE WHEN b.pd_raw IS NULL    THEN NULL
                 WHEN b.pd_raw < 1e-9     THEN 1e-9
                 WHEN b.pd_raw > 1 - 1e-9 THEN 1 - 1e-9
                 ELSE b.pd_raw END                                                AS p,
            CASE
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 1 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 0 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 1 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 0 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 1 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 0 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 1 THEN 'N2'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 0 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 1 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 0 THEN 'N1'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 1 THEN 'N3'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 0 THEN 'N2'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 1 THEN 'N3'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 1 AND flg_plin_f2 = 0 THEN 'N2'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 1 THEN 'N3'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 1 AND flg_plin_f1 = 0 AND flg_plin_f2 = 0 THEN 'N3'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 0 THEN 'N2'
                 WHEN flag_pasivos_afp_f = 1 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 0 THEN 'N2'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 1 AND flg_plinero_u3m = 0 THEN 'N2'
                 WHEN flag_pasivos_afp_f = 0 AND flg_cs_v2 = 0 AND flg_plinero_u3m = 0 THEN 'N3'
            END                                                            AS nodo_calc
       FROM disc_model_owner.ds_adm_vcnbank_tc_cal b
       LEFT JOIN ft f ON f.codmes = b.codmes_mrm
     ),
cal AS (
     SELECT base.*,
            CASE
                 WHEN nodo_calc = 'N1' THEN 1.4695148039 + 1.8256925084 * ln(p) - 0.079454116 * ln(1 - p)
                 WHEN nodo_calc = 'N2' THEN 0.902603441 + 1.4643579021 * ln(p) - 0 * ln(1 - p)
                 WHEN nodo_calc = 'N3' THEN 0.949176224 + 1.3276667784 * ln(p) - 0 * ln(1 - p)
            END                                                             AS z_beta,
            CASE
                 WHEN nodo_calc = 'N1' THEN -0.1603550806
                 WHEN nodo_calc = 'N2' THEN -0.2666897826
                 WHEN nodo_calc = 'N3' THEN -0.2740820643
            END                                                            AS delta_nodo,
            CASE WHEN seg_arq_salud = 'C' THEN -0.0350174239 ELSE 0 END                      AS driver
       FROM base
     ),
adj AS (
     SELECT cal.*,
            inverse_normal_cdf(0, 1,
                CASE WHEN 1.0 / (1 + exp(-z_beta)) < 1e-9     THEN 1e-9
                     WHEN 1.0 / (1 + exp(-z_beta)) > 1 - 1e-9 THEN 1 - 1e-9
                     ELSE 1.0 / (1 + exp(-z_beta)) END)
            + delta_nodo + 0.182367613 + driver                                          AS z_adj
       FROM cal
     ),
pit AS (
     SELECT adj.*,
            CASE WHEN z_adj IS NULL OR f_mes IS NULL THEN NULL
                 ELSE normal_cdf(0, 1, (z_adj - 0.1822086716 * 1 * f_mes) / 0.9832598843)
            END                                                                   AS prob_modelo_cal
       FROM adj
     )
SELECT tip_doc,
       id_value,
       entidad,
       flg_clean,
       flg_calib,
       pd_raw,
       falla_sin_score,
       nodo_calc,
       nodo_final,
       ctrl_nodo_n_fuentes,
       ctrl_nodo_observado,
       prob_modelo_cal,
       CAST(CASE WHEN prob_modelo_cal IS NULL THEN NULL
                 ELSE FLOOR(1000 * (1 - prob_modelo_cal)) END AS INTEGER)         AS puntuacion_cal,
       pd_cal_vigente,
       puntuacion_cal_vigente,
       CASE WHEN prob_modelo_cal IS NOT NULL THEN NULL
            WHEN falla_sin_score = 1 THEN 'sin score de produccion'
            WHEN pd_raw IS NULL      THEN 'pd_raw nulo con falla_sin_score = 0'
            WHEN f_mes  IS NULL      THEN 'codmes fuera del calendario macro'
            WHEN nodo_calc IS NULL   THEN 'banderas de nodo nulas'
            ELSE                          'revisar'
       END                                                                        AS motivo_sin_score,
       codmes_mrm
  FROM pit
