-- ============================================================================
-- 80. SCORE CALIBRADO SOBRE EL UNIVERSO SCOREADO - TRAMO 01 DE 6 (202401)  PILOTO
--   scan: scr_vcnbank_rsk U t_aws_360_cliente_mes_d3 U t_fact_edc_solicitud_retiro_afp_ibk
--         U t_agg_retail_user_trx_plin U t_rsk_cta_sueldo U t_mst_inter_ibk_base_cliente
--         U t_inca_sa
--
--   QUE ES. La misma cadena de calibracion que 71_scr_cal, aplicada a TODA fila
--   de scr_vcnbank_rsk en vez de a las altas. prob_modelo_cal y puntuacion_cal
--   llevan NUESTRA calibracion. Las columnas de la calibracion vigente que la
--   fuente ya traia con esos nombres viajan renombradas a *_vigente, para que no
--   queden dos calibraciones distintas compartiendo un mismo nombre.
--
--   PILOTO YA CORRIDO: 70 segundos para este mes, 26.4M filas. Con eso se
--   dimensionaron los tramos que siguen a 6 meses (~420 s, 47 por ciento del
--   timeout de 900 s del runner). Se dejo margen a proposito: con INSERT INTO un
--   TIMEOUT es peligroso porque el limite es del runner y no de Athena, la
--   insercion pudo completarse igual, y relanzar duplicaria las filas sin avisar.
--   Nota vieja, que el piloto ya contesto: eran ~26M filas de un
--   solo mes, contra ~200K altas: 123 veces mas. 30_drivers deja anotado que la
--   poblacion entra por INNER JOIN ANTES de cada ventana porque si no el
--   row_number ordena 1,250 millones de filas de inca y Athena agota recursos, y
--   aca esa poblacion casi no restringe. Con el tiempo de este tramo se sizea el
--   resto: si tarda de mas, se regeneran los demas mas chicos ANTES de lanzarlos.
--   Aca no hay lookback acumulado como en el RCC, asi que el costo deberia
--   escalar casi lineal con los meses del tramo -- pero eso se confirma midiendo,
--   que es justo lo que en el RCC se dio por supuesto y salio 4x contra 1.9x.
--
--   QUE ES ESTA TABLA. Es la POBLACION OBJETIVO sobre la que se lanza el
--   modelo, no altas: los desembolsos todavia no ocurrieron. Por eso sus 50
--   columnas no traen mora ni identificacion de alta, y no tienen por que
--   traerlas. Un modelo de admision existe justamente para pronunciarse ANTES.
--
--   La fuente ya trae prob_modelo_cal, puntuacion_cal y grupo_calibracion sobre
--   sus ~25M filas: la calibracion vigente ya vive en esta superficie y este
--   build la reemplaza por la nueva. Como las dos viajan lado a lado sobre las
--   mismas filas, se pueden comparar de frente.
--
--   Los puntos de corte viajan aplicados en grupo_cal, con los umbrales de la
--   opcion B. Es la columna que se compara contra grupo_cal_vigente y la que
--   decide la oferta.
--
--   CADENA, sin reajustar un coeficiente:
--     pd_raw -> BetaCal(nodo) -> corrimiento probit(nodo) -> delta_0 + driver
--            -> Vasicek PIT(F del mes)
--     rho 0.0332  lambda 1  delta_0 0.182367613  driver seg_arq_salud='C' -0.0350174239
--
--   EL NODO ES EL MISMO. Las 20 ramas y las tres fuentes gobernadas, con los
--   mismos rezagos: pasivos [M-6, M-1], PLIN [M-3, M-1], cuenta sueldo M-1.
--   Ninguna se lee en el mes de la decision, asi que no hay look-ahead.
--
--   prob_model viene REAL, o sea float32 con ~7 digitos. Se pasa a DOUBLE antes
--   de ln(p) porque la cadena toma logaritmos y ahi la precision se nota.
--   Medido: las 42 particiones traen prob_model en el 100 por ciento de sus
--   filas, asi que aca no hay ninguna fila sin score que explicar.
-- ============================================================================
CREATE TABLE disc_model_owner.scr_univ_vcnbank_tc_cal
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['p_codmes']) AS
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
po AS (
     SELECT s.cod_tip_doc                                                         AS tip_doc,
            s.key_value                                                           AS id_value,
            CAST(s.prob_model AS DOUBLE)                                          AS pd_raw,
            s.puntuacion,
            CAST(s.prob_modelo_cal AS DOUBLE)                                     AS pd_cal_vigente,
            s.puntuacion_cal                                                      AS puntuacion_cal_vigente,
            s.grupo_calibracion                                                   AS grupo_cal_vigente,
            s.tip_situacion_laboral                                               AS sitlab_score,
            s.p_codmes,
            date_format(date_add('month', -1, date_parse(s.p_codmes, '%Y%m')), '%Y%m') AS m01,
            date_format(date_add('month', -2, date_parse(s.p_codmes, '%Y%m')), '%Y%m') AS m02,
            date_format(date_add('month', -3, date_parse(s.p_codmes, '%Y%m')), '%Y%m') AS m03,
            date_format(date_add('month', -6, date_parse(s.p_codmes, '%Y%m')), '%Y%m') AS m06
       FROM e_perm_aws.scr_vcnbank_rsk s
      WHERE s.p_codmes = '202401'
     ),
llaves AS (
     SELECT DISTINCT tip_doc, id_value, m01, m02, m03, m06 FROM po
     ),
pas_m AS (
     SELECT k.tip_doc, k.id_value,
            CAST(a.codmes AS VARCHAR)                                             AS codmes,
            max(  coalesce(TRY_CAST(a.saldo_fdp_tot_pasivo AS DOUBLE), 0)
                - coalesce(TRY_CAST(a.saldo_fdp_tot_cts    AS DOUBLE), 0))        AS saldo
       FROM llaves k
       INNER JOIN e_perm_aws.t_aws_360_cliente_mes_d3 a
              ON a.key_value = k.id_value
             AND CAST(a.cod_tipo_documento AS VARCHAR) = k.tip_doc
             AND CAST(a.codmes AS VARCHAR) BETWEEN k.m06 AND k.m01
      GROUP BY k.tip_doc, k.id_value, CAST(a.codmes AS VARCHAR)
     ),
pas AS (
     SELECT tip_doc, id_value,
            count(CASE WHEN saldo > 900 THEN 1 END)                               AS n_meses_900
       FROM pas_m GROUP BY tip_doc, id_value
     ),
afp AS (
     SELECT k.tip_doc, k.id_value,
            max(CASE WHEN date_format(a.ts_solicitud, '%Y%m') <= k.m01
                     THEN 1 ELSE 0 END)                                           AS retiro_afp
       FROM llaves k
       INNER JOIN e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk a
              ON CAST(a.key_value AS VARCHAR)   = k.id_value
             AND CAST(a.cod_tip_doc AS VARCHAR) = k.tip_doc
      GROUP BY k.tip_doc, k.id_value
     ),
pln_m AS (
     SELECT k.tip_doc, k.id_value, a.p_codmes,
            sum(coalesce(TRY_CAST(a.numero_trx AS DOUBLE), 0))                    AS n_trx_tot,
            sum(CASE WHEN a.tipo_transf = 'Enviadas'
                     THEN coalesce(TRY_CAST(a.numero_trx AS DOUBLE), 0)
                     ELSE 0 END)                                                  AS n_trx_out,
            sum(CASE WHEN a.tipo_transf = 'Enviadas'
                     THEN coalesce(TRY_CAST(a.monto_transf AS DOUBLE), 0)
                     ELSE 0 END)                                                  AS mto_out
       FROM llaves k
       INNER JOIN e_perm_aws.t_agg_retail_user_trx_plin a
              ON CAST(a.cif_key AS VARCHAR) = k.id_value
             AND a.p_codmes BETWEEN k.m03 AND k.m01
      GROUP BY k.tip_doc, k.id_value, a.p_codmes
     ),
pln AS (
     SELECT tip_doc, id_value,
            count(CASE WHEN n_trx_tot > 0 THEN 1 END)                             AS cant_trx_u3m,
            count(CASE WHEN n_trx_out > 0 AND mto_out / n_trx_out >= 30
                       THEN 1 END)                                                AS cant_30_prm_out,
            count(CASE WHEN n_trx_out >= 20 THEN 1 END)                           AS cant_20_trx_out
       FROM pln_m GROUP BY tip_doc, id_value
     ),
cta AS (
     SELECT CAST(a.key_value AS VARCHAR)                                          AS id_value,
            CAST(CAST(a.tipdoc AS INTEGER) AS VARCHAR)                            AS tip_doc,
            max(TRY_CAST(a.flg_cs_riesgos AS INTEGER))                            AS flg_cs
       FROM e_perm_aws.t_rsk_cta_sueldo a
       INNER JOIN llaves k
              ON k.id_value = CAST(a.key_value AS VARCHAR)
             AND k.tip_doc  = CAST(CAST(a.tipdoc AS INTEGER) AS VARCHAR)
             AND CAST(a.codmes AS VARCHAR) = k.m01
      GROUP BY CAST(a.key_value AS VARCHAR), CAST(CAST(a.tipdoc AS INTEGER) AS VARCHAR)
     ),
mapa AS (
     SELECT tip_doc, id_value, inter_party_id
       FROM (SELECT k.tip_doc, k.id_value, b.inter_party_id,
                    row_number() OVER (PARTITION BY k.tip_doc, k.id_value
                                       ORDER BY b.inter_load_date DESC,
                                                b.inter_party_id ASC)             AS rn
               FROM e_perm_aws.t_mst_inter_ibk_base_cliente b
               INNER JOIN llaves k ON k.tip_doc = b.tip_doc AND k.id_value = b.key_value) x
      WHERE x.rn = 1
     ),
arq AS (
     SELECT tip_doc, id_value, seg_arq_salud
       FROM (SELECT k.tip_doc, k.id_value, a.seg_arq_salud,
                    row_number() OVER (PARTITION BY k.tip_doc, k.id_value
                                       ORDER BY a.load_date DESC)                 AS rn
               FROM llaves k
               INNER JOIN mapa m ON m.tip_doc = k.tip_doc AND m.id_value = k.id_value
               INNER JOIN e_perm_aws.t_inca_sa a
                      ON a.party_id = m.inter_party_id AND a.cod_mes = k.m02) z
      WHERE z.rn = 1
     ),
base AS (
     SELECT po.tip_doc, po.id_value, po.pd_raw, po.puntuacion, po.pd_cal_vigente,
            po.puntuacion_cal_vigente, po.grupo_cal_vigente, po.sitlab_score, po.p_codmes,
            f.f_mes,
            arq.seg_arq_salud,
            CAST(CASE WHEN coalesce(pas.n_meses_900, 0) = 6
                       AND coalesce(afp.retiro_afp, 0) = 0
                      THEN 1 ELSE 0 END AS INTEGER)                               AS flag_pasivos_afp_f,
            CAST(coalesce(cta.flg_cs, 0) AS INTEGER)                              AS flg_cs_v2,
            CAST(CASE WHEN coalesce(pln.cant_trx_u3m, 0) >= 1
                      THEN 1 ELSE 0 END AS INTEGER)                               AS flg_plinero_u3m,
            CAST(CASE WHEN coalesce(pln.cant_30_prm_out, 0) >= 1
                      THEN 1 ELSE 0 END AS INTEGER)                               AS flg_plin_f1,
            CAST(CASE WHEN coalesce(pln.cant_20_trx_out, 0) >= 1
                      THEN 1 ELSE 0 END AS INTEGER)                               AS flg_plin_f2,
            CAST(CASE WHEN pas.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)     AS ctrl_sin_360,
            CAST(CASE WHEN cta.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)     AS ctrl_sin_cta_sueldo,
            CAST(CASE WHEN pln.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)     AS ctrl_sin_plin,
            CASE WHEN po.pd_raw IS NULL    THEN NULL
                 WHEN po.pd_raw < 1e-9     THEN 1e-9
                 WHEN po.pd_raw > 1 - 1e-9 THEN 1 - 1e-9
                 ELSE po.pd_raw END                                               AS p
       FROM po
       LEFT JOIN ft f ON f.codmes = po.p_codmes
       LEFT JOIN pas  ON pas.tip_doc = po.tip_doc AND pas.id_value = po.id_value
       LEFT JOIN afp  ON afp.tip_doc = po.tip_doc AND afp.id_value = po.id_value
       LEFT JOIN pln  ON pln.tip_doc = po.tip_doc AND pln.id_value = po.id_value
       LEFT JOIN cta  ON cta.tip_doc = po.tip_doc AND cta.id_value = po.id_value
       LEFT JOIN arq  ON arq.tip_doc = po.tip_doc AND arq.id_value = po.id_value
     ),
nodo AS (
     SELECT base.*,
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
       FROM base
     ),
cal AS (
     SELECT nodo.*,
            CASE
                 WHEN nodo_calc = 'N1' THEN 1.4695148039 + 1.8256925084 * ln(p) - 0.079454116 * ln(1 - p)
                 WHEN nodo_calc = 'N2' THEN 0.902603441 + 1.4643579021 * ln(p) - 0 * ln(1 - p)
                 WHEN nodo_calc = 'N3' THEN 0.949176224 + 1.3276667784 * ln(p) - 0 * ln(1 - p)
            END                                                            AS z_beta,
            CASE
                 WHEN nodo_calc = 'N1' THEN -0.1603550806
                 WHEN nodo_calc = 'N2' THEN -0.2666897826
                 WHEN nodo_calc = 'N3' THEN -0.2740820643
            END                                                            AS delta_nodo,
            CASE WHEN seg_arq_salud = 'C' THEN -0.0350174239 ELSE 0 END                      AS driver
       FROM nodo
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
            END                                                                   AS pd_cal_calc
       FROM adj
     )
SELECT tip_doc,
       id_value,
       pd_raw,
       puntuacion,
       nodo_calc,
       flag_pasivos_afp_f,
       flg_cs_v2,
       flg_plinero_u3m,
       flg_plin_f1,
       flg_plin_f2,
       CAST((1 - ctrl_sin_360) + (1 - ctrl_sin_cta_sueldo)
            + (1 - ctrl_sin_plin) AS INTEGER)                                     AS ctrl_nodo_n_fuentes,
       CAST(CASE WHEN ctrl_sin_360 = 1 AND ctrl_sin_cta_sueldo = 1
                  AND ctrl_sin_plin = 1 THEN 0 ELSE 1 END AS INTEGER)             AS ctrl_nodo_observado,
       seg_arq_salud,
       sitlab_score,
       pd_cal_calc                                                                AS prob_modelo_cal,
       CAST(CASE WHEN pd_cal_calc IS NULL THEN NULL
                 ELSE FLOOR(1000 * (1 - pd_cal_calc)) END AS INTEGER)             AS puntuacion_cal,
       CASE WHEN pd_cal_calc IS NULL THEN NULL
            ELSE CASE
                 WHEN FLOOR(1000 * (1 - pd_cal_calc)) >= 972 THEN 'G1'
                 WHEN FLOOR(1000 * (1 - pd_cal_calc)) >= 964 THEN 'G2'
                 WHEN FLOOR(1000 * (1 - pd_cal_calc)) >= 938 THEN 'G3'
                 WHEN FLOOR(1000 * (1 - pd_cal_calc)) >= 899 THEN 'G4'
                 WHEN FLOOR(1000 * (1 - pd_cal_calc)) >= 768 THEN 'G5'
                 ELSE 'R'
                 END
       END                                                                        AS grupo_cal,
       pd_cal_vigente,
       puntuacion_cal_vigente,
       grupo_cal_vigente,
       p_codmes
  FROM pit
