-- 3b_drivers.sql | impulsa m0/u12m, ppjj, reactiva, entidad | lee mad completa
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_drivers AS
WITH uni AS (
    SELECT DISTINCT
        CAST(codmes AS VARCHAR) AS codmes,
        tip_doc,
        key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_mad
),
rcc_impulsa AS (
    SELECT
        CAST(a.codmes AS VARCHAR) AS codmes,
        a.tip_doc,
        a.key_value,
        SUM(a.saldo) AS sld_impulsa
    FROM (
        SELECT DISTINCT codmes, tip_doc, key_value, saldo, tipo_credito, cod_cuenta_rcc
        FROM (
            SELECT codmes, tip_doc, key_value, saldo, tipo_credito, cod_cuenta_rcc
            FROM e_perm_aws.t_fact_report_rcc_rsk
            WHERE p_codmes BETWEEN '201901' AND '202606'
            UNION ALL
            SELECT codmes, tip_doc, key_value, saldo, tipo_credito, cod_cuenta_rcc
            FROM d_perm_aws.t_fact_report_rcc_rsk
            WHERE p_codmes BETWEEN '201701' AND '201812'
        ) u
    ) a
    INNER JOIN (SELECT DISTINCT tip_doc, key_value FROM uni) b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    WHERE a.codmes BETWEEN '201802' AND '202606'
      AND a.tipo_credito IN ('01','02','03','04','05','06','07','08','09','10')
      AND (   a.cod_cuenta_rcc LIKE '81_95201%'
           OR a.cod_cuenta_rcc LIKE '81_95202%'
           OR a.cod_cuenta_rcc LIKE '81_95203%'
           OR a.cod_cuenta_rcc LIKE '81_95204%'
           OR a.cod_cuenta_rcc LIKE '81_95205%'
           OR a.cod_cuenta_rcc LIKE '81_95206%'
           OR a.cod_cuenta_rcc LIKE '81_95207%'
           OR a.cod_cuenta_rcc LIKE '81_95208%'
           OR a.cod_cuenta_rcc LIKE '81_95209%'
           OR a.cod_cuenta_rcc LIKE '81_95210%')
    GROUP BY 1,2,3
),
impulsa AS (
    SELECT
        u.codmes,
        u.tip_doc,
        u.key_value,
        SUM(CASE WHEN r.codmes = u.codmes THEN r.sld_impulsa END) AS sld_impulsa_m0,
        SUM(CASE WHEN r.codmes BETWEEN DATE_FORMAT(DATE_PARSE(u.codmes,'%Y%m') + INTERVAL '1' MONTH,'%Y%m')
                                   AND DATE_FORMAT(DATE_PARSE(u.codmes,'%Y%m') + INTERVAL '12' MONTH,'%Y%m')
                 THEN r.sld_impulsa END) AS sld_impulsa_u12m
    FROM uni u
    LEFT JOIN rcc_impulsa r
        ON r.tip_doc = u.tip_doc AND r.key_value = u.key_value
       AND r.codmes BETWEEN u.codmes AND DATE_FORMAT(DATE_PARSE(u.codmes,'%Y%m') + INTERVAL '12' MONTH,'%Y%m')
    GROUP BY 1,2,3
)
SELECT
    m.*,
    i.sld_impulsa_m0,
    i.sld_impulsa_u12m,
    CASE WHEN i.sld_impulsa_m0   > 0 THEN 1 ELSE 0 END AS flg_impulsa,
    CASE WHEN i.sld_impulsa_u12m > 0 THEN 1 ELSE 0 END AS flg_impulsa_u12m,
    CASE WHEN m.tip_doc = '2' THEN 1 ELSE 0 END AS flg_ppjj,
    CASE WHEN CAST(m.codmes AS VARCHAR) NOT BETWEEN '202206' AND '202506' THEN 1 ELSE 0 END AS falla_codmes_fuera_ventana,
    CASE WHEN m.cod_instit_financiera IS NULL OR TRIM(m.cod_instit_financiera) = '' THEN 1 ELSE 0 END AS falla_sin_entidad,
    CASE WHEN m.tip_doc IS NULL OR TRIM(m.tip_doc) = '' THEN 1 ELSE 0 END AS falla_sin_tip_doc,
    CASE WHEN m.segmento_reactiva IS NULL THEN 1 ELSE 0 END AS falla_sin_segmento_reactiva,
    CASE WHEN DATE_FORMAT(DATE_PARSE(CAST(m.codmes AS VARCHAR),'%Y%m') + INTERVAL '12' MONTH,'%Y%m') > '202606'
         THEN 1 ELSE 0 END AS falla_impulsa_u12m_inmaduro
FROM disc_model_owner.ds_adm_bpe_bankbn_mad m
LEFT JOIN impulsa i
    ON CAST(m.codmes AS VARCHAR) = i.codmes
   AND m.tip_doc = i.tip_doc
   AND m.key_value = i.key_value
