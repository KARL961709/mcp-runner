-- =====================================================================================
-- d_altas_fix | Por que v9 (pp_vc_altas) volvio 0. READ-ONLY.
--   Reviso meses recientes y valores de codempresa, para saber si la tabla de altas
--   llega a 202605/202606 y con que formato de codempresa (para el join que da el
--   subproducto de mayo, que scr_vc_orig_bank_calrcc_2_cal no tiene).
-- =====================================================================================
SELECT cast(codmes AS varchar)     AS codmes,
       codempresa,
       count(*)                    AS n,
       count(DISTINCT subproducto) AS n_subprod
FROM disc_model_owner.pp_vc_altas
WHERE cast(codmes AS varchar) BETWEEN '202603' AND '202606'
GROUP BY cast(codmes AS varchar), codempresa
ORDER BY 1, 2
