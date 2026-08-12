-- ============================================================================
-- 65. DEDUP - PRELACION CON ORDEN TOTAL DETERMINISTA
--   scan: disc_model_owner.ds_adm_vcnbank_tc_60_filtros
--   ancla: ninguna prelacion mira el target. Orden total, entidad desempata
--   sld ordena por saldo USADO. saldo_tc_ori sumaba deuda y linea disponible en el mismo
--   campo, asi que ordenaba por una magnitud sin lectura de riesgo
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_65_dedup AS
SELECT tip_doc,
       id_value,
       entidad,
       CAST(row_number() OVER (PARTITION BY codmes_mrm, tip_doc, id_value
                               ORDER BY entidad ASC) AS INTEGER)                       AS prelacion_cod,
       CAST(row_number() OVER (PARTITION BY codmes_mrm, tip_doc, id_value
                               ORDER BY sld_usado DESC, entidad ASC) AS INTEGER)       AS prelacion_sld,
       codmes_mrm
FROM disc_model_owner.ds_adm_vcnbank_tc_60_filtros
