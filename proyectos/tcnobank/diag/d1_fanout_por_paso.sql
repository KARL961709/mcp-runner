-- ============================================================================
-- D1. EN QUE PASO APARECE EL DUPLICADO
-- ============================================================================
SELECT paso, llaves_duplicadas, filas_extra
FROM (
    SELECT 'a. 11_po_key'  AS paso, count(*) AS llaves_duplicadas, sum(n - 1) AS filas_extra
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key GROUP BY 1,2,3,4 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'b. 20_rcc_base', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_20_rcc_base GROUP BY 1,2,3,4 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'c. 21_rcc_flags', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_21_rcc_flags GROUP BY 1,2,3,4 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'd. 50_targets', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_50_targets GROUP BY 1,2,3,4 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'e. 30_drivers (cliente-mes)', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_30_drivers GROUP BY 1,2,3 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'f. 40_pdraw (cliente-mes)', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_40_pdraw GROUP BY 1,2,3 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'g. 60_filtros', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_60_filtros GROUP BY 1,2,3,4 HAVING count(*) > 1) x
    UNION ALL
    SELECT 'h. cal', count(*), sum(n - 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad, count(*) AS n
          FROM disc_model_owner.ds_adm_vcnbank_tc_cal GROUP BY 1,2,3,4 HAVING count(*) > 1) x
) y
ORDER BY paso
