-- ============================================================================
-- Q02. MATRIZ 2x2 - EL VC TIENE QUE CONTENER AL TC
--   Medido contra el original en sql_val_vc: solo_tc = 0 en los 25 meses
--   maduros. Si aqui aparece solo_tc > 0 el build esta mal, porque la pata
--   dura es la MISMA en los dos targets y dm_sf contiene a dm_tc por
--   construccion -mismo cliente, mismo mes, superconjunto de cuentas-.
-- ============================================================================
SELECT codmes_mrm                                                               AS codmes,
       count(*)                                                                 AS n,
       sum(target_12m)                                                          AS n_tc,
       sum(target_vc_12m)                                                       AS n_vc,
       sum(CASE WHEN target_vc_12m = 1 AND target_12m = 1 THEN 1 ELSE 0 END)    AS ambos,
       sum(CASE WHEN target_vc_12m = 1 AND target_12m = 0 THEN 1 ELSE 0 END)    AS solo_vc,
       sum(CASE WHEN target_vc_12m = 0 AND target_12m = 1 THEN 1 ELSE 0 END)    AS solo_tc,
       sum(CASE WHEN target_vc_12m = 0 AND target_12m = 0 THEN 1 ELSE 0 END)    AS ninguno
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal_vc
 WHERE flg_calib = 1 AND flg_clean = 1
 GROUP BY codmes_mrm
 ORDER BY codmes_mrm
