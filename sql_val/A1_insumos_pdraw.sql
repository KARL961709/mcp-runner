-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : A_insumo/A1_insumos_pdraw.sql
--   origen  : ~\mcp-runner\sql\A1_insumos_pdraw.sql
--   sha256  : 8a5ff77e63b5   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : grano y rango de probabilidad
-- =====================================================================================
-- =====================================================================================
-- A1 | INSUMO pd_raw — sanidad de la fuente
-- e_perm_aws.scr_admbankbpe_rsk campo `probabilidad`. Es el unico insumo del modelo.
--
-- CRITERIO DE APROBACION
--   * dup_clientes = 0        (el grano debe ser tip_doc+key_value+p_codmes)
--   * pd_min > 0 y pd_max < 1 (si hay 0 o 1 exactos, ln() revienta la cadena)
--   * n_clientes estable mes a mes; una caida brusca = particion incompleta
-- READ-ONLY.
-- =====================================================================================


SELECT cast(p_codmes AS int) AS p_codmes,
       count(*)                                   AS n_filas,
       count(DISTINCT tip_doc || '|' || key_value) AS n_clientes,
       count(*) - count(DISTINCT tip_doc || '|' || key_value) AS dup_clientes,
       count_if(probabilidad IS NULL)             AS pd_nulos,
       min(probabilidad)                          AS pd_min,
       max(probabilidad)                          AS pd_max,
       avg(probabilidad)                          AS pd_prom
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE p_codmes BETWEEN '202206' AND '202607'
GROUP BY 1
ORDER BY 1
