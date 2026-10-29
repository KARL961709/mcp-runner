-- ============================================================================
-- v35. QUE STAGING DEL BUILD SIGUE VIVO, Y CON QUE COLUMNAS
--   Antes de consultar ds_stk_ree_pp_10_po o _50_pd hay que saber si existen:
--   son intermedias de un build que corre con DROP TABLE IF EXISTS, asi que su
--   presencia no se asume. 10_po es donde se FABRICAN codmes_mrm y codmes_scr,
--   y 50_pd es el cruce de la pd sin nada downstream encima: si estan vivas, el
--   ancla se mide ahi sin pasar por la tabla gobernada.
-- ============================================================================
SELECT table_schema,
       table_name,
       COUNT(*)                                                             AS n_columnas,
       SUM(CASE WHEN column_name = 'codmes_mrm' THEN 1 ELSE 0 END)          AS tiene_codmes_mrm,
       SUM(CASE WHEN column_name = 'codmes_scr' THEN 1 ELSE 0 END)          AS tiene_codmes_scr,
       SUM(CASE WHEN column_name = 'pd_raw' THEN 1 ELSE 0 END)              AS tiene_pd_raw,
       SUM(CASE WHEN column_name = 'flg_ree_v4' THEN 1 ELSE 0 END)          AS tiene_flg_ree_v4,
       SUM(CASE WHEN column_name IN ('tip_doc', 'cod_tip_doc') THEN 1 ELSE 0 END) AS tiene_tipdoc,
       SUM(CASE WHEN column_name IN ('id_value', 'key_value') THEN 1 ELSE 0 END)  AS tiene_llave
FROM information_schema.columns
WHERE table_schema IN ('disc_model_owner', 'disc_riesgos', 'e_perm_aws', 'd_perm_aws')
  AND (table_name LIKE 'ds_stk_ree_pp%'
       OR table_name LIKE '%scr_stockpp_itc_reen%'
       OR table_name LIKE '%fact_rsk_desembolsos_pp%'
       OR table_name LIKE '%compppibk_rsk%')
GROUP BY table_schema, table_name
ORDER BY 1, 2
