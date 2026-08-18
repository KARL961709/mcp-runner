-- ============================================================================
-- 51. MORA DEL SISTEMA FINANCIERO - TRAMO 1 DE 3 (202402 A 202412)
--   scan: e_perm_aws.t_fact_report_rcc_rsk [202402, 202412], solo las llaves de la PO
--         con cohorte >= 202401
--   dm_sf es la mora del recibido 02.TARGET_kat.sql:224. Sin filtro de entidad
--   y sin filtro de tipo_credito: esos dos son los que lo hacen Vision Cliente
--   La ventana total [202402, 202606] cubre las cohortes [202401, 202605] a 12m
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_51_dmsf
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      partitioned_by = ARRAY['codmes']) AS
SELECT a.tip_doc,
       a.key_value,
       max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) IN ('14')
                 AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                 AND a.cod_clasificacion_deudor <> '8' THEN a.condicion END)            AS dm_sf,
       a.p_codmes                                                                       AS codmes
FROM e_perm_aws.t_fact_report_rcc_rsk a
JOIN ( SELECT DISTINCT tip_doc, id_value
         FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
        WHERE codmes_mrm >= '202401' ) k
  ON k.tip_doc = a.tip_doc AND k.id_value = a.key_value
WHERE a.p_codmes BETWEEN '202402' AND '202412'
GROUP BY a.tip_doc, a.key_value, a.p_codmes
