-- 1t6_b_tag.sql | claves de alta por entidad | escribe 202502-202606 lee 202502-202606
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_tag_t6 AS
SELECT codmes, tip_doc, key_value, cod_instit_financiera,
       max(CASE WHEN saldo > 0 THEN 1 ELSE 0 END) AS flg_saldo_pos
FROM (
    SELECT a.codmes, a.tip_doc, a.key_value, a.cod_instit_financiera, a.saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN cast(a.tipo_credito AS int) BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                            ELSE 'RESTO DD NEGOCIO'
                        END
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE WHEN cast(a.tipo_credito AS int) BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                            WHEN (cast(a.tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                            ELSE 'RESTO LC NEGOCIO'
                        END
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN a.cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada
    FROM (
            SELECT codmes, tip_doc, key_value, tipo_credito, cod_cuenta_rcc, cod_instit_financiera, saldo
            FROM e_perm_aws.t_fact_report_rcc_rsk
            WHERE p_codmes BETWEEN '202502' AND '202606'
              AND codmes   BETWEEN '202502' AND '202606'
    ) a
) t
WHERE tag IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO')
  AND ent_honrada = 0
GROUP BY 1,2,3,4
