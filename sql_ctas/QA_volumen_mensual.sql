-- =====================================================================================
-- QA_volumen_mensual.sql | volumen y composicion mes a mes de la tabla final
--
-- b46029_po_scoring_v1v2 esta particionada por p_codmes, asi que este agregado se
-- resuelve por metadata de particion: es barato.
--
-- QUE MIRAR
--   * n_filas estable mes a mes. Un salto o una caida brusca = particion incompleta
--     en scr_admbankbpe_rsk, no un cambio real de poblacion.
--   * pct_clean: se espera que suba con el tiempo. La poblacion mejoro (el pd_raw
--     medio cayo de 10.5% en 2024 a 5.6% en 2025), asi que deberia haber mas clean
--     en los meses recientes.
--   * n_filas = n_clientes: la tabla es una fila por cliente-mes. Si difieren, hay
--     duplicados y el JOIN de PO_4 tiene un problema de grano.
--
-- 30 filas. READ-ONLY.
-- =====================================================================================

SELECT
  p_codmes,
  count(*)                                                    AS n_filas,
  count(DISTINCT tip_doc || '|' || key_value)                 AS n_clientes,
  count_if(flg_clean = 1)                                     AS clean,
  count_if(flg_clean = 0)                                     AS dirty,
  round(100.0 * count_if(flg_clean = 1) / count(*), 1)        AS pct_clean,
  round(100.0 * avg(prob_modelo_cal_v2), 2)                   AS pd_v2_prom_pct,
  count_if(grupos_cal_v2 = 'G1')                              AS v2_g1,
  count_if(grupos_cal_v2 = 'G5')                              AS v2_g5
FROM disc_model_owner.b46029_po_scoring_v1v2
GROUP BY p_codmes
ORDER BY p_codmes
