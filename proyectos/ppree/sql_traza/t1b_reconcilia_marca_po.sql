-- T1b. RECONCILIA 119,255 llaves de marca vs 119,254 filas del maestro
-- CORRIGE T1: 11_marca tiene (id_value, codmes_mrm) SIN tip_doc -- no existe
-- columna 'codmes'. El join contra la PO va por esas dos llaves.
SELECT
  (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_11_marca)                    AS n_marca,
  (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_cal WHERE flg_scope_ree = 1) AS n_cal_scope,
  (SELECT COUNT(*) FROM (
      SELECT DISTINCT id_value, codmes_mrm
        FROM disc_model_owner.ds_stk_ree_pp_cal WHERE flg_scope_ree = 1))           AS n_cal_sin_tipdoc,
  (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_11_marca m
     LEFT JOIN (SELECT DISTINCT id_value, codmes_mrm
                  FROM disc_model_owner.ds_stk_ree_pp_10_po) p
            ON p.id_value = m.id_value AND p.codmes_mrm = m.codmes_mrm
    WHERE p.id_value IS NULL)                                                       AS marca_sin_po,
  (SELECT COUNT(*) FROM (
      SELECT id_value, codmes_mrm
        FROM disc_model_owner.ds_stk_ree_pp_cal WHERE flg_scope_ree = 1
       GROUP BY id_value, codmes_mrm HAVING COUNT(DISTINCT tip_doc) > 1))           AS cal_con_dos_tipdoc
