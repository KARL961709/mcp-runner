-- 06. MATCH DE LAS 5 BANDERAS CONTRA EL CSV RECIBIDO
--   La misma comparacion que Programas/analisis/match_nodos.py, pero en SQL,
--   que es el lenguaje en el que corre el despliegue.
--
--   FLG_PLINERO_U3M del csv es CATEGORICO -00.NO_PLIN y variantes son el cero-,
--   no un 0/1. Compararlo directo contra nuestro entero daria 0 por ciento y
--   pareceria un error del nodo cuando es de formato.
--
--   El join va por las tres llaves. El csv no distingue entidad porque solo
--   trae la 2, asi que el filtro de entidad va del lado nuestro.
SELECT COUNT(*)                                                                  AS n_cruzan,
       SUM(CASE WHEN d.flag_pasivos_afp_f = CAST(TRY_CAST(c.flag_pasivos_afp_f AS INTEGER) AS INTEGER)
                THEN 1 ELSE 0 END)                                               AS ok_pasivos,
       SUM(CASE WHEN d.flg_cs_v2 = CAST(TRY_CAST(c.flg_cs_v2 AS INTEGER) AS INTEGER)
                THEN 1 ELSE 0 END)                                               AS ok_cta_sueldo,
       SUM(CASE WHEN d.flg_plinero_u3m
                   = CASE WHEN substr(c.flg_plinero_u3m, 1, 3) = '00.' THEN 0 ELSE 1 END
                THEN 1 ELSE 0 END)                                               AS ok_plinero,
       SUM(CASE WHEN d.flg_plin_f1 = CAST(TRY_CAST(c.flg_plin_f1 AS INTEGER) AS INTEGER)
                THEN 1 ELSE 0 END)                                               AS ok_plin_f1,
       SUM(CASE WHEN d.flg_plin_f2 = CAST(TRY_CAST(c.flg_plin_f2 AS INTEGER) AS INTEGER)
                THEN 1 ELSE 0 END)                                               AS ok_plin_f2,
       SUM(CASE WHEN d.nodo_final = c.nodo_final THEN 1 ELSE 0 END)               AS ok_nodo
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal d
  INNER JOIN disc_model_owner.aux_nodos_recibido c
          ON c.tip_doc   = d.tip_doc
         AND c.key_value = d.id_value
         AND c.codmes    = d.codmes_mrm
 WHERE d.entidad = '00002'
