-- ============================================================================
-- 99. COBERTURA DE LA CAPA AGREGADA - SIN HUECO NI SOLAPE
-- ============================================================================
SELECT 'G9' AS gate, chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM (
    SELECT 'meses esperados sin filas en la capa agregada' AS chk,
           114 - count(DISTINCT codmes) AS n_viol,
           count(DISTINCT codmes) AS n_magnitud
    FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg WHERE codmes BETWEEN '201701' AND '202606'
    UNION ALL
    SELECT 'llaves duplicadas dentro de un mes',
           (SELECT count(*) FROM (SELECT codmes, tip_doc, key_value, entidad
                                  FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg GROUP BY 1,2,3,4 HAVING count(*) > 1) d),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
) y
