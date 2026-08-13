-- ============================================================================
-- V12. PASIVOS - NUESTRO NUMERO CON EL CORTE EXACTO DEL CSV
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal, entidad 00002 en [202410,202504]
--   ancla: el 17.5 se midio sobre 28 meses de flg_clean = 1. El csv son 7 meses de IBK
--          con la cascada COMPLETA (BUENO 14,450 MALO 1,121 INSUFICIENTE 1,696
--          INDETERMINADO 1,397) y da 26.08 de pasivos sobre 18,664, 56.7 de plinero,
--          16.9 de cuenta sueldo y 47.1 de f1. Si al igualar el corte convergemos, la
--          brecha era poblacion. Si no, difiere la definicion y la unica causa que
--          queda es que saldo_fdp_tot_pas_sin_cts de datalab no sea pasivo menos cts
-- ============================================================================
SELECT CASE WHEN GROUPING(flg_clean) = 1 THEN '9.TODO (comparable al csv)'
            WHEN flg_clean = 99 THEN '3.fuera de alcance'
            WHEN flg_clean = 1  THEN '1.clean'
            ELSE                     '2.dirty' END                                      AS corte,
       count(*)                                                                         AS n,
       round(100.0 * avg(CAST(flag_pasivos_afp_f AS DOUBLE)), 3)                        AS pct_pasivo,
       round(100.0 * avg(CAST(ctrl_retiro_afp    AS DOUBLE)), 3)                        AS pct_retiro_afp,
       round(100.0 * avg(CAST(ctrl_sin_360       AS DOUBLE)), 3)                        AS pct_sin_360,
       round(100.0 * avg(CAST(flg_cs_v2          AS DOUBLE)), 3)                        AS pct_cs,
       round(100.0 * avg(CAST(flg_plinero_u3m    AS DOUBLE)), 3)                        AS pct_plinero,
       round(100.0 * avg(CAST(flg_plin_f1        AS DOUBLE)), 3)                        AS pct_f1,
       round(100.0 * avg(CAST(flg_plin_f2        AS DOUBLE)), 3)                        AS pct_f2,
       round(100.0 * avg(CASE WHEN nodo_final = 'N1' THEN 1.0 ELSE 0.0 END), 3)         AS pct_n1,
       round(100.0 * avg(CASE WHEN nodo_final = 'N2' THEN 1.0 ELSE 0.0 END), 3)         AS pct_n2,
       round(100.0 * avg(CASE WHEN nodo_final = 'N3' THEN 1.0 ELSE 0.0 END), 3)         AS pct_n3
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE entidad = '00002'
  AND codmes_mrm BETWEEN '202410' AND '202504'
GROUP BY GROUPING SETS ((flg_clean), ())
ORDER BY corte
