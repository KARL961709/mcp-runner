-- 30. DRIVERS -> ds_adm_bpe_bankbn_drivers
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_drivers AS
WITH universo_impulsa AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
        SUM(CASE WHEN a.tipo_credito IN ('01','02','03','04','05','06','07','08','09','10')
                 AND (a.cod_cuenta_rcc LIKE '81_95201%' OR a.cod_cuenta_rcc LIKE '81_95202%' OR a.cod_cuenta_rcc LIKE '81_95203%'
                   OR a.cod_cuenta_rcc LIKE '81_95204%' OR a.cod_cuenta_rcc LIKE '81_95205%' OR a.cod_cuenta_rcc LIKE '81_95206%'
                   OR a.cod_cuenta_rcc LIKE '81_95207%' OR a.cod_cuenta_rcc LIKE '81_95208%' OR a.cod_cuenta_rcc LIKE '81_95209%'
                   OR a.cod_cuenta_rcc LIKE '81_95210%')
            THEN a.saldo ELSE NULL END) AS SLDIMPULSA
    FROM e_perm_aws.t_fact_report_rcc_rsk a
    INNER JOIN disc_model_owner.ds_adm_bpe_bankbn_po b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    GROUP BY 1,2,3
),
sld_impulsa AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
        SUM(CASE WHEN CAST(b.codmes AS INT) = CAST(a.codmes AS INT) THEN b.SLDIMPULSA ELSE NULL END) AS SLD_IMPULSA_X0,
        SUM(CASE WHEN CAST(b.codmes AS INT) BETWEEN
                 CAST(DATE_FORMAT(DATE_ADD('month',1, DATE_PARSE(CAST(a.codmes AS VARCHAR),'%Y%m')),'%Y%m') AS INT) AND
                 CAST(DATE_FORMAT(DATE_ADD('month',12,DATE_PARSE(CAST(a.codmes AS VARCHAR),'%Y%m')),'%Y%m') AS INT)
            THEN b.SLDIMPULSA ELSE NULL END) AS SLD_IMPULSA_12UM
    FROM disc_model_owner.ds_adm_bpe_bankbn_po a
    LEFT JOIN universo_impulsa b ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    GROUP BY 1,2,3
)
SELECT
    m.*,
    CASE WHEN i.SLD_IMPULSA_X0  > 0 THEN 1 ELSE 0 END AS flg_impulsa,
    CASE WHEN i.SLD_IMPULSA_12UM> 0 THEN 1 ELSE 0 END AS flg_impulsa_u12m,
    CASE WHEN m.tip_doc = '2' THEN 1 ELSE 0 END       AS flg_ppjj
FROM disc_model_owner.ds_adm_bpe_bankbn_mad m
LEFT JOIN sld_impulsa i ON m.codmes = i.codmes AND m.tip_doc = i.tip_doc AND m.key_value = i.key_value
;
