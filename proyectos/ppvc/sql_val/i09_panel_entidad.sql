-- ============================================================================
-- i09. PANEL SEPARADO: n y RD12 por entidad x codmes (5 entidades), clean+dirty.
--   Pivot de entidades en columnas para caber en el resumen. Insumo del ciclo
--   (efectos de tiempo con FE de entidad). READ-ONLY.
-- ============================================================================
SELECT codmes,
  sum(CASE WHEN cod_instit_financiera = '00001' AND flg_clean <> 99 THEN 1 ELSE 0 END) AS n_01,
  sum(CASE WHEN cod_instit_financiera = '00002' AND flg_clean <> 99 THEN 1 ELSE 0 END) AS n_02,
  sum(CASE WHEN cod_instit_financiera = '00004' AND flg_clean <> 99 THEN 1 ELSE 0 END) AS n_04,
  sum(CASE WHEN cod_instit_financiera = '00006' AND flg_clean <> 99 THEN 1 ELSE 0 END) AS n_06,
  sum(CASE WHEN cod_instit_financiera = '00142' AND flg_clean <> 99 THEN 1 ELSE 0 END) AS n_142,
  round(100.0 * avg(CASE WHEN cod_instit_financiera = '00001' AND flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 3) AS rd_01,
  round(100.0 * avg(CASE WHEN cod_instit_financiera = '00002' AND flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 3) AS rd_02,
  round(100.0 * avg(CASE WHEN cod_instit_financiera = '00004' AND flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 3) AS rd_04,
  round(100.0 * avg(CASE WHEN cod_instit_financiera = '00006' AND flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 3) AS rd_06,
  round(100.0 * avg(CASE WHEN cod_instit_financiera = '00142' AND flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 3) AS rd_142
FROM disc_model_owner.ds_adm_pp_cdpp_cal
WHERE target_12m IS NOT NULL
GROUP BY codmes
ORDER BY codmes
