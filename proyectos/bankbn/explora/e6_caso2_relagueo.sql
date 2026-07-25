-- e6 CASO2: exclusiones de origen medidas a m0 (202405) vs m2 (202403) -> impacto del relagueo
WITH po AS (SELECT DISTINCT tip_doc, key_value FROM disc_model_owner.ds_adm_bpe_bankbn_po),
rcc AS (
    SELECT r.codmes,
        MAX(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='81' AND substr(r.cod_cuenta_rcc,4,3) IN ('302','925') THEN 1 ELSE 0 END) AS castigo,
        MAX(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='6' THEN 1 ELSE 0 END) AS judicial,
        MAX(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='4' THEN 1 ELSE 0 END) AS refi,
        MAX(CASE WHEN r.cod_clasificacion_deudor <> '0' THEN 1 ELSE 0 END) AS no_normal,
        r.tip_doc, r.key_value
    FROM e_perm_aws.t_fact_report_rcc_rsk r
    INNER JOIN po ON r.tip_doc=po.tip_doc AND r.key_value=po.key_value
    WHERE r.codmes IN ('202405','202403')
    GROUP BY r.codmes, r.tip_doc, r.key_value
)
SELECT codmes,
    SUM(castigo) AS n_castigo, SUM(judicial) AS n_judicial, SUM(refi) AS n_refi, SUM(no_normal) AS n_no_normal,
    SUM(CASE WHEN castigo+judicial+refi+no_normal>0 THEN 1 ELSE 0 END) AS n_algun_origen
FROM rcc GROUP BY codmes ORDER BY codmes
