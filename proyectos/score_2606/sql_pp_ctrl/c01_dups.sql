-- c01 garantia SIN duplicados: grano (codmes, cod_tip_doc, key_value) unico por mes. d_dups debe ser 0 en los 32 meses.
SELECT codmes,
       COUNT(*) AS n,
       COUNT(DISTINCT key_value) AS n_dni,
       COUNT(*) - COUNT(DISTINCT CAST(cod_tip_doc AS varchar) || '|' || key_value) AS d_dups
FROM disc_model_owner.scr_admvc_pp_cal_202401_202608
GROUP BY codmes
ORDER BY codmes
