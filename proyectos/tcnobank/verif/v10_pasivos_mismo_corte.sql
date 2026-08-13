-- ============================================================================
-- V10. PASIVOS - NUESTRO NUMERO CON EL CORTE EXACTO DEL CSV
--   scan: __T___cal, entidad 00002 en [202410,202504]
--   ancla: los 17.3 por ciento se midieron sobre 28 meses de flg_clean = 1. El csv son
--          7 meses con la cascada COMPLETA: BUENO 14,450, MALO 1,121, INSUFICIENTE
--          1,696 e INDETERMINADO 1,397, o sea 26.08 por ciento de pasivos sobre 18,664.
--          Si al recortar a la misma ventana y al mismo alcance subimos a 26, la
--          brecha era el corte. Si nos quedamos en 17, la definicion difiere
-- ============================================================================
SELECT CASE WHEN flg_clean = 99 THEN '4.fuera de alcance'
            WHEN flg_clean = 1  THEN '1.clean'
            ELSE                     '2.dirty' END                                      AS corte,
       count(*)                                                                         AS n,
       sum(CASE WHEN flg_calib = 1 THEN 1 ELSE 0 END)                                   AS n_calib,
       round(100.0 * avg(CAST(flag_pasivos_afp_f AS DOUBLE)), 3)                        AS pct_pasivo,
       round(100.0 * avg(CAST(ctrl_retiro_afp    AS DOUBLE)), 3)                        AS pct_retiro_afp,
       round(100.0 * avg(CAST(ctrl_sin_360       AS DOUBLE)), 3)                        AS pct_sin_360,
       round(100.0 * avg(CAST(flg_cs_v2          AS DOUBLE)), 3)                        AS pct_cs,
       round(100.0 * avg(CAST(flg_plinero_u3m    AS DOUBLE)), 3)                        AS pct_plinero,
       round(100.0 * avg(CAST(flg_plin_f1        AS DOUBLE)), 3)                        AS pct_f1,
       round(100.0 * avg(CAST(flg_plin_f2        AS DOUBLE)), 3)                        AS pct_f2
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE entidad = '00002'
  AND codmes_mrm BETWEEN '202410' AND '202504'
GROUP BY GROUPING SETS (
    (CASE WHEN flg_clean = 99 THEN '4.fuera de alcance'
          WHEN flg_clean = 1  THEN '1.clean'
          ELSE                     '2.dirty' END),
    ())
ORDER BY corte
