-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : A_insumo/A2_desfase_m2.sql
--   origen  : ~\mcp-runner\sql\A2_desfase_m2.sql
--   sha256  : 0e53fbaad0af   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : p_codmes = codmes_alta - 1
-- =====================================================================================
-- =====================================================================================
-- A2 | DESFASE TEMPORAL — el score que decidio el alta
-- Convencion: p_codmes = codmes_alta - 1. Si no se cumple, el modelo usa un score
-- que al decidir aun no existia (look-ahead). El notebook original tenia ese defecto.
--
-- CRITERIO DE APROBACION
--   * meses_ok = meses_totales  (todos los meses deben cumplir la biyeccion)
--   * cobertura_pct alta y estable; un mes bajo = particion faltante en scr
-- READ-ONLY.
-- =====================================================================================


WITH a AS (
  SELECT cast(codmes AS int) AS codmes, cast(tip_doc AS varchar) AS tip_doc, key_value
  FROM disc_model_owner.bnbpe_ibk_altas_src
  WHERE top4_entidad='TOP4' AND cast(codmes AS int) BETWEEN 202207 AND 202604
  GROUP BY 1,2,3
),
p AS (
  SELECT cast(p_codmes AS int) AS p_codmes, cast(tip_doc AS varchar) AS tip_doc, key_value
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202604'
  GROUP BY 1,2,3
)
SELECT a.codmes,
       count(*) AS n_altas,
       count_if(p.key_value IS NOT NULL) AS con_score_m1,
       round(100.0*count_if(p.key_value IS NOT NULL)/count(*), 2) AS cobertura_pct
FROM a
LEFT JOIN p ON p.tip_doc=a.tip_doc AND p.key_value=a.key_value
           AND p.p_codmes = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m')
                                             - interval '1' month,'%Y%m') AS int)
GROUP BY a.codmes
ORDER BY a.codmes
