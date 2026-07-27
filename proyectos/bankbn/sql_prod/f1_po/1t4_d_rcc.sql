-- 1t4_d_rcc.sql | historia rcc agregada por entidad | escribe 202106-202305 lee 202005-202305
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc_t4 AS
SELECT codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera,
    max(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') THEN condicion ELSE null END) AS dm,
    sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') THEN saldo ELSE 0 END) AS saldo_mo,
    sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') AND ent_honrada=0 THEN saldo ELSE 0 END) AS saldo_m0_entidad,
    sum(CASE WHEN garantia='gar_p'        THEN saldo ELSE null END) AS saldo_gar_p,
    sum(CASE WHEN garantia='gar_np'       THEN saldo ELSE null END) AS saldo_gar_np,
    sum(CASE WHEN garantia='Sin Garantia' THEN saldo ELSE null END) AS saldo_sg,
    sum(CASE WHEN flg_tipo_credito='ins' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_ins,
    sum(CASE WHEN flg_tipo_credito='neg' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_neg,
    sum(CASE WHEN flg_tipo_credito='con' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_con
FROM (
    SELECT DISTINCT a.codmes, a.tip_doc, a.key_value, a.condicion, a.tipo_credito, a.cod_cuenta_rcc,
           a.cod_instit_financiera, a.cod_clasificacion_deudor, a.saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,4,1)='4' THEN 'REFINANCIADOS'
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN a.cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada,
        CASE WHEN regexp_like(a.cod_cuenta_rcc, '^84.40[12345]') THEN 'gar_p'
             WHEN regexp_like(a.cod_cuenta_rcc, '^84.4(09|10)') THEN 'gar_np'
             ELSE 'Sin Garantia' END AS garantia,
        CASE
            WHEN a.tipo_credito IN ('01','02','03','04','05') THEN 'ins'
            WHEN a.tipo_credito IN ('06','07','08','09','10') THEN 'neg'
            WHEN a.tipo_credito IN ('11','12','13')           THEN 'con'
            ELSE 'otro'
        END AS flg_tipo_credito
    FROM (
        SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
               cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202005' AND '202305'
          AND codmes   BETWEEN '202005' AND '202305'
    ) a
    INNER JOIN (
        SELECT tip_doc, key_value
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_tag_t4
        GROUP BY 1,2
    ) b
    ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
) r
GROUP BY 1,2,3,4,5
