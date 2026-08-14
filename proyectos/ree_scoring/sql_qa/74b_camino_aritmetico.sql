-- 74b. CUAL DE LOS DOS CAMINOS ARITMETICOS ES EL DE PRODUCCION
--   74 dio max_dif del orden de 3e-11, que no es ninguna de las dos cosas que
--   podia ser: precision de maquina seria 1e-16 y un coeficiente distinto en el
--   sexto decimal seria 1e-7. Queda una tercera: el mismo coeficiente por un
--   camino distinto.
--   El pipeline aplica el corrimiento probit en DOS pasos, con vuelta a
--   probabilidad y recorte entre medio:
--       pd_ttc     = Phi(Phi_inv(pd_cal) + delta_seg)   recortado
--       pd_ttc_adj = Phi(Phi_inv(pd_ttc) + delta_0)
--   y 74 lo escribio COLAPSADO en Phi_inv(pd_cal) + delta_seg + delta_0, que es
--   identico en aritmetica real pero no en punto flotante: cada vuelta por
--   Phi_inv y Phi pasa por las aproximaciones de Trino, que no son exactas.
--   En scipy la diferencia entre los dos caminos es 2.8e-16, o sea nada, asi que
--   la hipotesis no se puede falsar desde afuera: hay que medirla aca.
--   Si dif_dos_pasos cae a 1e-16 mientras dif_colapsado se queda en 3e-11, el
--   camino de produccion es el de dos pasos y 71 tiene que escribirse igual.
--   Si los dos quedan en 3e-11, la diferencia esta en otro lado y el residuo es
--   inmaterial de todos modos.
SELECT trf_tipo_ingreso_dep                                                       AS seg,
       COUNT(*)                                                                   AS n,
       MAX(ABS(prob_colapsado - prob_orig))                                       AS dif_colapsado,
       MAX(ABS(prob_dos_pasos - prob_orig))                                       AS dif_dos_pasos,
       SUM(CASE WHEN ABS(prob_dos_pasos - prob_orig) > 1e-12 THEN 1 ELSE 0 END)   AS n_fuera_dos_pasos
  FROM (SELECT trf_tipo_ingreso_dep,
               prob_orig,
               GREATEST(LEAST(normal_cdf(0.0, 1.0,
                 ((z_cal + delta_seg + 0.034261721611022956)
                  - sqrt(0.038030115964094044) * f_t)
                 / sqrt(1.0 - 0.038030115964094044))
               , 1.0 - 1e-4), 1e-4)                                               AS prob_colapsado,
               GREATEST(LEAST(normal_cdf(0.0, 1.0,
                 ((inverse_normal_cdf(0.0, 1.0,
                     GREATEST(LEAST(normal_cdf(0.0, 1.0, z_cal + delta_seg),
                                    1.0 - 1e-9), 1e-9))
                   + 0.034261721611022956)
                  - sqrt(0.038030115964094044) * f_t)
                 / sqrt(1.0 - 0.038030115964094044))
               , 1.0 - 1e-4), 1e-4)                                               AS prob_dos_pasos
          FROM (SELECT trf_tipo_ingreso_dep,
                       CAST(prob_modelo_cal AS DOUBLE)                            AS prob_orig,
                       CAST(trf_f_t AS DOUBLE)                                    AS f_t,
                       CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN 0.061973725544583
                                                              ELSE 0.10257577255744288 END AS delta_seg,
                       inverse_normal_cdf(0.0, 1.0, GREATEST(LEAST(
                         1.0 / (1.0 + exp(-(
                           (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN -1.4235902271832188
                                                                   ELSE -1.8712301290911784 END)
                         + (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN  1.4307409240924087
                                                                   ELSE  1.12194919105907   END)
                           * ln(GREATEST(LEAST(CAST(probabilidad AS DOUBLE), 1.0 - 1e-9), 1e-9))
                         - (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN  0.11673242216482149
                                                                   ELSE  0.5587876581505312 END)
                           * ln(1.0 - GREATEST(LEAST(CAST(probabilidad AS DOUBLE), 1.0 - 1e-9), 1e-9))
                         )))
                       , 1.0 - 1e-9), 1e-9))                                      AS z_cal
                  FROM d_perm_aws.scr_stk_ree_pp_cal_202607) b) r
 GROUP BY 1
 ORDER BY 1
