-- ============================================================================
-- 12. LINEA DE CREDITO EN EL MES DEL ALTA
--   scan: e_perm_aws.t_fact_report_rcc_rsk en codmes_mrm, solo cuenta 81-923
--   ancla: k=0. La po arranca en 201902 y e_perm cubre desde 201901, asi que no hay
--          rama d_perm. saldo_tc de 05_rcc_agg ya suma 14-x de TC mas 81-923, asi que
--          el usado sale por resta y no hace falta releer las subcuentas de TC
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_12_saldo_perfil AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value, entidad
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                 AND substr(a.cod_cuenta_rcc,4,3) = '923' THEN a.saldo ELSE 0 END)      AS sld_linea,
       p.codmes_mrm
FROM po p
INNER JOIN e_perm_aws.t_fact_report_rcc_rsk a
       ON a.tip_doc = p.tip_doc AND a.key_value = p.id_value
      AND ltrim(rtrim(a.cod_instit_financiera)) = p.entidad
      AND a.p_codmes = p.codmes_mrm
WHERE a.p_codmes BETWEEN '201902' AND '202606'
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm
