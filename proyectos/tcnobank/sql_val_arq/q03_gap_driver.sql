-- ============================================================================
-- Q03. BRECHA DE CALIBRACION CON Y SIN EL DRIVER DE ARQUETIPO
--   scan: ds_adm_vcnbank_tc_cal U scr_adm_vcnbank_tc_cal
--   pregunta: el corrimiento que la celda C recibio en IBK sirve en SS.FF.
--
--   QUITAR EL DRIVER ES UNA CONSTANTE EXACTA, no una re-estimacion. El driver
--   entra sumando -0.0350174239 al probit ANTES del Vasicek, y el Vasicek
--   divide entre sqrt(1-rho) = 0.9832598843. Deshacerlo es sumar
--   0.0350174239 / 0.9832598843 = 0.0356135997 al probit de prob_modelo_cal.
--   Verificado contra la cadena de 71_scr_cal, no despejado de memoria.
--
--   LO QUE ESTA CONSULTA NO PUEDE HACER: re-ajustar delta_0. En el paso 06
--   delta_0 y el driver se optimizan juntos, asi que al quitar el driver el
--   intercepto se mueve. Eso necesita el optimizador y NO existe en SQL. Por
--   eso van tambien las columnas gap_rel_*: cada celda menos la brecha global
--   de su grupo, que es exactamente la parte que un re-anclaje de nivel NO
--   puede cambiar. La comparacion de forma se lee ahi, no en gap_con/gap_sin.
--
--   Cohortes maduras solamente (target_12m IS NOT NULL).
-- ============================================================================
WITH d AS (
     SELECT tip_doc, id_value, entidad, codmes_mrm,
            coalesce(seg_arq_salud, '(nulo)')                                                AS arq,
            seg_arq_salud,
            target_12m,
            CASE WHEN entidad = '00002'                             THEN '1_IBK'
                 WHEN entidad IN ('00001','00004','00006','00142')  THEN '2_PANEL_RESTO'
                 ELSE                                                    '3_OTRAS_SSFF' END  AS grp,
            CASE WHEN f_banc_u12m = 1 OR f_sin_linea = 1 THEN 99
                 WHEN f_edad_rango + f_cast_ori + f_jud_ori + f_ref_ori + f_ree_ori
                    + f_malo_ori + f_cast_u24m + f_jud_u24m + f_ref_u6m + f_mayor_cpp
                    + f_gar_conv + f_fraude + f_swap_u12m = 0 THEN 1 ELSE 0 END              AS clean_sf
       FROM disc_model_owner.ds_adm_vcnbank_tc_cal
     ),
s AS (
     SELECT tip_doc, id_value, entidad, codmes_mrm, prob_modelo_cal
       FROM disc_model_owner.scr_adm_vcnbank_tc_cal
      WHERE prob_modelo_cal IS NOT NULL
     ),
j AS (
     SELECT d.grp,
            d.arq,
            d.codmes_mrm,
            d.target_12m,
            s.prob_modelo_cal                                                                AS p_con,
            CASE WHEN d.seg_arq_salud = 'C'
                 THEN normal_cdf(0, 1,
                        inverse_normal_cdf(0, 1,
                          CASE WHEN s.prob_modelo_cal < 1e-9     THEN 1e-9
                               WHEN s.prob_modelo_cal > 1 - 1e-9 THEN 1 - 1e-9
                               ELSE s.prob_modelo_cal END) + 0.0356135997)
                 ELSE s.prob_modelo_cal END                                                  AS p_sin
       FROM d
       JOIN s ON s.tip_doc = d.tip_doc AND s.id_value = d.id_value
             AND s.entidad = d.entidad AND s.codmes_mrm = d.codmes_mrm
      WHERE d.clean_sf = 1
        AND d.target_12m IS NOT NULL
     ),
g AS (
     SELECT v.ventana,
            j.grp,
            j.arq,
            count(*)             AS n,
            avg(j.target_12m)    AS rd,
            avg(j.p_con)         AS p_con,
            avg(j.p_sin)         AS p_sin
       FROM j
      CROSS JOIN (VALUES ('1_VENTANA_202411'), ('2_TODO_MADURO')) AS v (ventana)
      WHERE (v.ventana = '2_TODO_MADURO' OR j.codmes_mrm >= '202411')
      GROUP BY v.ventana, j.grp, j.arq
     )
SELECT ventana,
       grp,
       arq,
       n,
       round(100.0 * rd, 4)                                                                  AS rd_12m,
       round(100.0 * p_con, 4)                                                               AS pd_con_driver,
       round(100.0 * p_sin, 4)                                                               AS pd_sin_driver,
       round(10000.0 * (p_con - rd), 1)                                                      AS gap_con_bps,
       round(10000.0 * (p_sin - rd), 1)                                                      AS gap_sin_bps,
       round(10000.0 * ((p_con - rd)
             - sum(n * (p_con - rd)) OVER (PARTITION BY ventana, grp)
             / sum(n)               OVER (PARTITION BY ventana, grp)), 1)                    AS gap_rel_con_bps,
       round(10000.0 * ((p_sin - rd)
             - sum(n * (p_sin - rd)) OVER (PARTITION BY ventana, grp)
             / sum(n)               OVER (PARTITION BY ventana, grp)), 1)                    AS gap_rel_sin_bps
  FROM g
 ORDER BY ventana, grp, arq
