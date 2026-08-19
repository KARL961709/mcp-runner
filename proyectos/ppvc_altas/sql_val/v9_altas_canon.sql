-- =====================================================================================
-- v9 | POBLACION canonica de ALTAS IBK por mes x subproducto. READ-ONLY.
--   pp_vc_altas (02_altas.sql) = universo de desembolsos; IBK = codempresa 00002.
--   Confirma el tamano real (~miles P.FACIL/mes) y los codigos de subproducto,
--   para anclar la poblacion del build final independientemente de las *_cal.
-- =====================================================================================
SELECT cast(codmes AS varchar) AS codmes,
       subproducto,
       count(*)                  AS n_altas,
       count(DISTINCT key_value) AS n_cli
FROM disc_model_owner.pp_vc_altas
WHERE cast(codmes AS varchar) IN ('202605', '202606')
  AND codempresa = '00002'
GROUP BY cast(codmes AS varchar), subproducto
ORDER BY 1, 2
