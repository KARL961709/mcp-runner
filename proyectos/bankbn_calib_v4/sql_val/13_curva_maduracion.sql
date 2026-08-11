-- 13_curva_maduracion.sql | curva de maduracion del target por trimestre y poblacion. Mismo target de calibracion a 1, 2, 3, 6, 9 y 12 meses, para ver a que horizonte aparece senal y comparar tendencia sin cambiar de metrica
SELECT pob,
       trimestre,
       count(*)                                                                    AS n,
       round(100.0 * avg(pd_raw), 4)                                               AS pd_raw,
       round(100.0 * avg(pd_pit_vig), 4)                                           AS pd_pit,
       round(100.0 * avg(TRY_CAST(target_01m AS DOUBLE)), 4)                       AS rd_01m,
       round(100.0 * avg(TRY_CAST(target_02m AS DOUBLE)), 4)                       AS rd_02m,
       round(100.0 * avg(TRY_CAST(target_03m AS DOUBLE)), 4)                       AS rd_03m,
       round(100.0 * avg(TRY_CAST(target_06m AS DOUBLE)), 4)                       AS rd_06m,
       round(100.0 * avg(TRY_CAST(target_09m AS DOUBLE)), 4)                       AS rd_09m,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 4)                       AS rd_12m,
       count(target_03m)                                                           AS n_ev_03m,
       count(target_12m)                                                           AS n_ev_12m
FROM disc_model_owner.ds_adm_bpe_insumo_calib_v4
WHERE flg_clean = 1
GROUP BY pob, trimestre
ORDER BY pob, trimestre
