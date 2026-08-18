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
--   EL NODO NO SE INVENTA ACA. Las cinco banderas ya vienen construidas en la
--   cadena 13/14/15 -> 16_nodo, desde FUENTES GOBERNADAS de e_perm_aws y con el
--   rezago declarado en cada una:
--     t_aws_360_cliente_mes_d3            pasivos, ventana [M-6, M-1]
--     t_fact_edc_solicitud_retiro_afp_ibk retiro AFP, anclado en M-1
--     t_agg_retail_user_trx_plin          PLIN, ventana [M-3, M-1]
--     t_rsk_cta_sueldo                    cuenta sueldo, M-1
--   Ninguna se lee en el mes de la decision, asi que no hay look-ahead, y el
--   pasivo se reconstruyo desde el 360 gobernado justamente porque la suma del
--   script original vivia en datalab, que no es fuente gobernada (13_pasivos).
--   Las anclas estan medidas contra el csv de nodos, no supuestas: PLIN u3m da
--   57.03 por ciento en IBK clean contra 56.7 del csv.
--
--   Lo unico que este paso vuelve a evaluar es el CASE de 20 ramas, porque
--   16_nodo lo cierra con SIN_ALCANCE fuera de la entidad 00002. Las banderas
--   en si ya existen para las 25 entidades sin un solo nulo. Verificado:
--   nodo_calc reproduce nodo_final en las 1,690,263 filas de IBK sin una
--   discrepancia, y nodo_final viaja al lado para repetir el chequeo sobre la
--   tabla escrita.
--
--   FUERA DE IBK ESTO ES EXTRAPOLACION, que es lo unico que produccion puede
--   hacer: no hay forma de calibrar distinto por entidad. Y es defendible
--   precisamente porque las cuatro fuentes son gobernadas y se leen igual para
--   todos, con el mismo rezago. Lo que cambia entre entidades no es la regla
--   sino la cobertura: entre 55 y 63 por ciento de los clientes de otros bancos
--   no aparecen en ninguna de las tres fuentes de comportamiento, asi que a
--   ellos el nodo se les arma desde la ausencia y caen en N3. Eso es un hecho
--   medido de la cobertura, no un defecto de la replica, y por eso viaja como
--   columna: ctrl_nodo_n_fuentes cuenta en cuantas de las tres se los vio y
--   ctrl_nodo_observado marca con 0 a los que no estan en ninguna.
--
--   El F del mes viaja precalculado en convencion Vasicek, ya centrado y topeado
--   a [-0.7056560795, 0.3143482354]. Recalcularlo aca seria un lugar mas donde equivocarse.
--
--   LA TABLA DE F PUEDE TENER MAS MESES QUE EL ds_, y no es un error. F depende
--   solo de la inflacion observada, asi que se calcula para todo mes publicado.
--   Hasta donde se SCOREA lo decide otra cosa: la frontera del RCC. Medido el
--   2026-08-14 contando filas por particion, t_fact_report_rcc_rsk cierra en
--   202606 y 202607 no existe, asi que la poblacion no puede pasar de 202606.
--   Un mes con F pero sin filas en el ds_ simplemente no aparece en el LEFT JOIN.
--   Las otras cinco fuentes llegan mas lejos: el score a 202608 y las tres del
--   nodo a 202607. PLIN tiene particion 202608 pero a medias -28.9M filas contra
--   55.6M de un mes normal-, que es por que la frontera se mide contando y no
--   con max().
-- ============================================================================
CREATE TABLE disc_model_owner.scr_adm_vcnbank_tc_cal AS
WITH ft AS (
     SELECT codmes, f_mes
       FROM (VALUES
            ('202303', -0.7056560795),
            ('202304', -0.7056560795),
            ('202305', -0.7056560795),
            ('202306', -0.7056560795),
            ('202307', -0.7056560795),
            ('202308', -0.7056560795),
            ('202309', -0.5902261957),
            ('202310', -0.4110339926),
            ('202311', -0.2305283514),
            ('202312', -0.128578414),
            ('202401', -0.0740489159),
            ('202402', -0.1430586906),
            ('202403', -0.0794451794),
            ('202404', 0.0796951644),
            ('202405', 0.1862548426),
            ('202406', 0.1146142237),
            ('202407', 0.154904096),
            ('202408', 0.1788061397),
            ('202409', 0.2449909096),
            ('202410', 0.1851711923),
            ('202411', 0.11803515),
            ('202412', 0.1961244902),
            ('202501', 0.2254301815),
            ('202502', 0.3143482354),
            ('202503', 0.3143482354),
            ('202504', 0.2764568895),
            ('202505', 0.2675597012),
            ('202506', 0.2657597305),
            ('202507', 0.2670135203),
            ('202508', 0.3143482354),
            ('202509', 0.3143482354),
            ('202510', 0.3143482354),
            ('202511', 0.3143482354),
            ('202512', 0.3129956207),
            ('202601', 0.2639184403),
            ('202602', 0.1328066619),
            ('202603', -0.2734627438),
            ('202604', -0.3270054231),
            ('202605', -0.2991375921),
            ('202606', -0.3256683805),
            ('202607', -0.3400358764)
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
