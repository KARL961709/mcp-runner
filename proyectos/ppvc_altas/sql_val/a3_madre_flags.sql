-- =====================================================================================
-- a3 | Madre raw: desglose por subproducto x flg_swap x flg_cima (jun/jul). READ-ONLY.
--   Confirma: codigos reales de subproducto, y los VALORES de flg_swap/flg_cima
--   ('1'/'0'? 'S'/'N'? null?) para que la exclusion de f2 sea exacta, no adivinada.
-- =====================================================================================
SELECT cast(codmes_desembolso AS varchar) AS codmes,
       subproducto,
       cast(flg_swap AS varchar)          AS flg_swap,
       cast(flg_cima AS varchar)          AS flg_cima,
       count(*)                           AS n,
       count(DISTINCT cif_key)            AS n_cli
FROM disc_monitorian.t_mrm_mongest_altas_pp_marcas
WHERE cast(codmes_desembolso AS varchar) IN ('202606', '202607')
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4
