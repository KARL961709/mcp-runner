-- =====================================================================================
-- a2 | FRESCURA de la MADRE RAW de altas (monitoreo). READ-ONLY.
--   disc_monitorian.t_mrm_mongest_altas_pp_marcas: fuente mas anterior de la cadena
--   (01_desembolsos la consume). Confirmo que llega a jun/jul y los codigos de subproducto.
--   Llave del monitoreo = cif_key (luego 01 la mapea a key_value via t_mst_ctaibk_rsk).
-- =====================================================================================
SELECT cast(codmes_desembolso AS varchar)  AS codmes,
       subproducto,
       count(*)                            AS n,
       count(DISTINCT cif_key)             AS n_cli,
       round(sum(desembolso), 0)           AS monto
FROM disc_monitorian.t_mrm_mongest_altas_pp_marcas
WHERE cast(codmes_desembolso AS varchar) IN ('202605', '202606', '202607', '202608')
GROUP BY cast(codmes_desembolso AS varchar), subproducto
ORDER BY 1, 2
