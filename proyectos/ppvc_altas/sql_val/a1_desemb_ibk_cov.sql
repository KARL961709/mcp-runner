-- =====================================================================================
-- a1 | COBERTURA de la fuente madre de ALTAS IBK por mes x subproducto. READ-ONLY.
--   disc_model_owner.pp_vc_desembolsos, codempresa '00002' (IBK), meses 202605-202608.
--   Confirma: que llega fresca a jun/jul/ago, el tamano real (~miles P.FACIL/mes) y
--   los codigos de subproducto para el cruce con la tabla calibrada del universo.
-- =====================================================================================
SELECT cast(codmes AS varchar)     AS codmes,
       subproducto,
       count(*)                    AS n_altas,
       count(DISTINCT key_value)   AS n_cli,
       round(sum(desembolso), 0)   AS monto_desemb
FROM disc_model_owner.pp_vc_desembolsos
WHERE codempresa = '00002'
  AND cast(codmes AS varchar) IN ('202605', '202606', '202607', '202608')
GROUP BY cast(codmes AS varchar), subproducto
ORDER BY 1, 2
