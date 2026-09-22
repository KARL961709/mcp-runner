-- d2_98. Matriz de confusion mi flg_clean vs maestro (ds_adm). master 0/1/99 x mine 0/1.
--        Acuerdo clean/dirty = diag / total(master in 0,1). Ver como cae el 99 (scope-out) en mine.
SELECT d.flg_clean AS master, m.flg_clean AS mine, COUNT(*) AS n
FROM disc_model_owner.drv_clean_ppvc m
JOIN disc_model_owner.ds_adm_pp_cdpp_cal d
  ON CAST(m.codmes AS integer) = CAST(d.codmes AS integer)
 AND m.key_value = d.key_value
 AND TRY_CAST(m.tip_doc AS integer) = TRY_CAST(d.tip_doc AS integer)
GROUP BY d.flg_clean, m.flg_clean
ORDER BY 1, 2