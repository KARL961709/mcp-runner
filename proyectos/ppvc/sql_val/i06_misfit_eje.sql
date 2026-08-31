-- ============================================================================
-- i06. DESAJUSTE por eje: mean(pd_raw) vs RD12 por tipo_ingreso, por nodo y por
--   tipo_ingreso x nodo (IBK, clean, scoreado+maduro). Justifica el segmento
--   (rango de desajuste por eje). GROUPING SETS en una sola pasada. READ-ONLY.
-- ============================================================================
SELECT
  tipo_ingreso,
  nodo,
  count(*)                                                              AS n,
  round(avg(pd_raw), 6)                                                 AS pdraw_medio,
  round(avg(CAST(target_12m AS DOUBLE)), 6)                             AS rd12,
  round(avg(pd_raw) / nullif(avg(CAST(target_12m AS DOUBLE)), 0) - 1, 4) AS desajuste_rel
FROM disc_model_owner.ds_adm_pp_cdpp_cal
WHERE flg_ibk = 1 AND flg_clean = 1 AND flg_pd_raw = 1 AND target_12m IS NOT NULL
GROUP BY GROUPING SETS ((tipo_ingreso), (nodo), (tipo_ingreso, nodo))
ORDER BY tipo_ingreso, nodo
