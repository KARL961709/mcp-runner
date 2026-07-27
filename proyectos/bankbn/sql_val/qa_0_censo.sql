-- qa_0_censo.sql | que build quedo en las tablas: presencia de columnas nuevas vs viejas. Solo metadata, costo cero
SELECT table_name,
       count(1)                                                                   AS n_columnas,
       max(CASE WHEN column_name = 'flg_calib'       THEN 1 ELSE 0 END)           AS tiene_flg_calib,
       max(CASE WHEN column_name = 'flg_clean'       THEN 1 ELSE 0 END)           AS tiene_flg_clean,
       max(CASE WHEN column_name = 'entidad'         THEN 1 ELSE 0 END)           AS tiene_entidad,
       max(CASE WHEN column_name = 'score_p_codmes'  THEN 1 ELSE 0 END)           AS tiene_score_pcodmes,
       max(CASE WHEN column_name = 'target_01m'      THEN 1 ELSE 0 END)           AS tiene_target_01m,
       max(CASE WHEN column_name = 'target_12m'      THEN 1 ELSE 0 END)           AS tiene_target_12m,
       sum(CASE WHEN column_name LIKE 'target__m' OR column_name LIKE 'target___m' THEN 1 ELSE 0 END) AS n_targets
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name LIKE 'ds_adm_bpe_bankbn%'
GROUP BY table_name
ORDER BY table_name
