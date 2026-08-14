-- 74. LOS COEFICIENTES DE LA VIGENTE, PUESTOS A PRUEBA CONTRA SUS PROPIAS FILAS
--   recomputa prob_modelo_cal desde probabilidad, trf_tipo_ingreso_dep y trf_f_t
--   de la MISMA tabla, con los coeficientes de ENTREGA_REE_FINAL.
--   Usar el trf_f_t DE LA VIGENTE es lo que hace decisiva esta prueba: el literal
--   del cap sale de la ecuacion y lo unico que queda a prueba son los coeficientes.
--   72 no podia separarlos porque entraba con el factor recalculado.
--   Coeficientes bajo prueba: BetaCal m/a/b por segmento, corrimiento probit por
--   segmento, delta_0 global, rho y lambda. Si los diez coinciden, max_dif cae al
--   orden de 1e-16, que es precision de maquina.
--   El umbral de 1e-12 no es arbitrario. Medido perturbando cada coeficiente en
--   1e-6 sobre las filas entregadas, max_dif se va a entre 7.4e-8 (aD) y 9.8e-7
--   (bN), con rho en 8.2e-7: cinco ordenes de magnitud arriba del umbral. O sea
--   que n_fuera = 0 acota cada coeficiente a coincidir mejor que 1e-11.
--   n_fuera es la cuenta dura: distinto de 0 es FALLA.
--   Se abre por mes y por segmento a proposito: una serie construida por tramos
--   podria llevar coeficientes distintos en meses distintos, y un maximo global
--   lo escondaria detras del peor mes.
SELECT codmes,
       seg,
       n,
       max_dif,
       dif_prom,
       n_fuera
  FROM (SELECT CAST(codmes AS VARCHAR)                                            AS codmes,
               trf_tipo_ingreso_dep                                               AS seg,
               COUNT(*)                                                           AS n,
               MAX(ABS(prob_recalc - prob_orig))                                  AS max_dif,
               AVG(ABS(prob_recalc - prob_orig))                                  AS dif_prom,
               SUM(CASE WHEN ABS(prob_recalc - prob_orig) > 1e-12
                        THEN 1 ELSE 0 END)                                        AS n_fuera
          FROM (SELECT codmes,
                       trf_tipo_ingreso_dep,
                       CAST(prob_modelo_cal AS DOUBLE)                            AS prob_orig,
                       GREATEST(LEAST(
                         normal_cdf(0.0, 1.0,
                           ((inverse_normal_cdf(0.0, 1.0,
                              GREATEST(LEAST(
                                1.0 / (1.0 + exp(-(
                                  (CASE WHEN trf_tipo_ingreso_dep = 'DEP'
                                        THEN -1.4235902271832188
                                        ELSE -1.8712301290911784 END)
                                + (CASE WHEN trf_tipo_ingreso_dep = 'DEP'
                                        THEN  1.4307409240924087
                                        ELSE  1.12194919105907   END)
                                  * ln(GREATEST(LEAST(CAST(probabilidad AS DOUBLE),
                                                      1.0 - 1e-9), 1e-9))
                                - (CASE WHEN trf_tipo_ingreso_dep = 'DEP'
                                        THEN  0.11673242216482149
                                        ELSE  0.5587876581505312 END)
                                  * ln(1.0 - GREATEST(LEAST(CAST(probabilidad AS DOUBLE),
                                                            1.0 - 1e-9), 1e-9))
                                )))
                              , 1.0 - 1e-9), 1e-9))
                             + (CASE WHEN trf_tipo_ingreso_dep = 'DEP'
                                     THEN 0.061973725544583
                                     ELSE 0.10257577255744288 END)
                             + 0.034261721611022956)
                            - sqrt(0.038030115964094044) * 1.0 * CAST(trf_f_t AS DOUBLE))
                           / sqrt(1.0 - 0.038030115964094044))
                       , 1.0 - 1e-4), 1e-4)                                       AS prob_recalc
                  FROM d_perm_aws.scr_stk_ree_pp_cal_202607) r
         GROUP BY 1, 2) g
 ORDER BY 1, 2
