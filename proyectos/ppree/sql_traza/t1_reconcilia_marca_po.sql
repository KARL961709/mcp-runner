-- T1. RECONCILIA 119,255 llaves de marca vs 119,254 filas del maestro
-- Hipotesis a distinguir: (a) llave de marca sin fila en la PO, (b) un cliente
-- con dos tip_doc que colapsa a una fila. Devuelve 1 fila con los dos conteos.
SELECT
  (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_11_marca)                       AS n_marca,
  (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_cal WHERE flg_scope_ree = 1)    AS n_cal_scope,
  (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_11_marca m
     LEFT JOIN disc_model_owner.ds_stk_ree_pp_10_po p
            ON p.id_value = m.id_value AND p.codmes_mrm = m.codmes
    WHERE p.id_value IS NULL)                                                          AS marca_sin_po,
  (SELECT COUNT(*) FROM (
      SELECT id_value, codmes FROM disc_model_owner.ds_stk_ree_pp_11_marca
      GROUP BY id_value, codmes HAVING COUNT(DISTINCT 1) > 1))                          AS marca_dup_grano
