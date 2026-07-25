-- ============================================================================
-- 20. TARGET + FILTROS + SCORE (MaduracionV9 completo) -> ds_adm_bpe_bankbn_mad
-- Fuente=_po (D1). fix target_12m (+12). desfase +1. <CODMES>=T0 <CODMES_FWD>=T0+12 <CODMES_M12>=T0-12
-- ============================================================================
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_mad;

CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_mad AS
with morigbk_rcc as (SELECT DISTINCT 
        a.codmes,
        a.tip_doc,
        a.key_value,
        a.condicion,
        a.tipo_credito,
        a.cod_cuenta_rcc,
        a.cod_instit_financiera,
        a.cod_clasificacion_deudor,
        a.saldo,
        CASE 
            WHEN SUBSTR(a.cod_cuenta_rcc, 1, 2) = '14' AND SUBSTR(a.cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6') THEN   
                CASE
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 7, 2) = '05' THEN 'DESCUENTOS'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 7, 2) = '10' THEN 'FACTORING'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 7, 2) = '04' THEN 'SOBREGIRO'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 7, 2) = '01' THEN 'AVANCE CC'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 4, 1) = '4' THEN 'REFINANCIADOS'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 4, 1) = '5' THEN 'VENCIDOS'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 4, 1) = '6' THEN 'JUDICIALES'
                    ELSE 'RESTO DD'
                END
            WHEN SUBSTR(a.cod_cuenta_rcc, 1, 2) = '72' AND SUBSTR(a.cod_cuenta_rcc, 4, 1) = '5' THEN 
                CASE 
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 5, 2) = '02' THEN 'LC DESCUENTO'
                    WHEN (CAST(a.tipo_credito AS INT) BETWEEN 1 AND 10) AND SUBSTR(a.cod_cuenta_rcc, 5, 2) IN ('03', '06', '08', '09') THEN 'LC NO UTILIZADA'
                    ELSE 'RESTO LC'
                END
            ELSE 'OTROS' 
        END AS tag,
        CASE 
            WHEN a.cod_instit_financiera IN ('00469', '00470', '00472', '00477', '00478', '00497', '00498', '00499', '00500', '00508',
                                              '00509', '00510', '00512', '00513', '00514', '00516', '00517', '00518', '00519', 
                                              '00580', '00581', '00582', '00583', '00587', '00588', '00589', '00592', '00593', 
                                              '00594', '00596', '00598', '00599', '00600') 
            THEN 1 
            ELSE 0 
        END AS ent_honrada,
        CASE 
            WHEN REGEXP_LIKE(cod_cuenta_rcc, '^84.40[12345]') THEN 'gar_p'
            WHEN REGEXP_LIKE(cod_cuenta_rcc, '^84.4(09|10)') THEN 'gar_np'
            ELSE 'Sin Garantia' 
        END AS garantia,
        CASE
            WHEN tipo_credito IN ('01', '02', '03', '04', '05') THEN 'ins'
            WHEN tipo_credito IN ('06', '07', '08', '09', '10') THEN 'neg'
            WHEN tipo_credito IN ('11', '12', '13') THEN 'con'
            ELSE 'otro'
        END AS flg_tipo_credito
    -- FROM (where e_perm_aws.t_fact_report_rcc_rsk WHERE codmes >= '202306') a  -- fuente aws: reporte rcc 
    -- FROM (where e_perm_aws.t_fact_report_rcc_rsk WHERE codmes BETWEEN '202306' and '202406') a  -- fuente aws: reporte rcc 
    FROM (select * from e_perm_aws.t_fact_report_rcc_rsk WHERE codmes BETWEEN '<CODMES>' and '<CODMES_FWD>') a  -- fuente aws: reporte rcc 
    INNER JOIN (
        SELECT 
            tip_doc, 
            key_value 
        -- FROM d_mdl_riesgos_disc.PO_PREVIA_AD_BANK_FINAL_202306 
        FROM disc_model_owner.ds_adm_bpe_bankbn_po 
        -- WHERE ((30000 <= max_saldo AND (saldo_m0 >= 10000 AND saldo_m0 < 30000)) OR (saldo_m0 >= 30000)) and codmes='202306' 
        WHERE ((30000 <= max_saldo AND (saldo_m0 >= 10000 AND saldo_m0 < 30000)) OR (saldo_m0 >= 30000)) and codmes='<CODMES>' 
        GROUP BY 1, 2
    ) b -- fuente propia: initial PO
    ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value 
    
    ),
    morigbk_saldo_hist as (
    with data_rcc as ( 
        select codmes, tip_doc, key_value,
                sum(case when cast(tipo_credito as int) between 1 and 10  and (substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('1','3','4','5','6')) --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else 0 end) as saldo_mo,
                sum(case when cast(tipo_credito as int) between 1 and 10  AND ((SUBSTR(a.COD_CUENTA_RCC,1,2)='14' AND SUBSTR(a.COD_CUENTA_RCC,4,1) in ('1','3','4','5','6') )
                 OR (SUBSTR(a.COD_CUENTA_RCC,1,2)='81' AND SUBSTR(a.COD_CUENTA_RCC,4,3) in ('302','925')))
                then saldo else null end) as saldo_total,
                sum(case when cast(tipo_credito as int) between 1 and 10  and (substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('4')) --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else null end) as sald_ref_mo,
                 sum(case when cast(tipo_credito as int) between 11 and 13 then saldo else null end) as sld_cons,
                  sum(case when cast(tipo_credito as int) between 1 and 10  and (substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('6')) --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else null end) as sald_jud_mo,
                sum(case when cast(tipo_credito as int) between 1 and 10  and (substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('3')) --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else null end) as sald_rest_mo,
                 sum(case when cast(tipo_credito as int) between 1 and 10  and substr(cod_cuenta_rcc,1,2)='81' and (substr(cod_cuenta_rcc,4,3)='302' or substr(cod_cuenta_rcc,4,3)='925') --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else null end) as sald_cast_mo,
                 -- 810925 Créditos castigados que vienen siendo amortizados
                 -- 810302 Créditos castigados
                 max(case when cast(tipo_credito as int) between 1 and 10   and (substr(COD_CUENTA_RCC,1,2)='14'and substr(cod_cuenta_rcc,7,2) not in ('01','04') and substr(COD_CUENTA_RCC,4,1) in ('1','3','4','5','6')) 
                then cod_clasificacion_deudor else null end) as clasif_mo,
                max(case when (cast(tipo_credito as int) between 1 and 10 and (substr(COD_CUENTA_RCC,1,2)='14'and substr(cod_cuenta_rcc,7,2) not in ('01','04') and substr(COD_CUENTA_RCC,4,1) in ('1','3','4','5','6')) or (substr(cod_cuenta_rcc,1,2)='81' and (cast(tipo_credito as int) between 1 and 10) and substr(cod_cuenta_rcc,4,3)='925')--castigados
                 or (substr(cod_cuenta_rcc,1,2)='81' and (cast(tipo_credito as int) between 1 and 10) and substr(cod_cuenta_rcc,4,3)='302'))  then condicion else null end) as dm,
                sum(case when cast(tipo_credito as int) between 1 and 10  and regexp_like(cod_cuenta_rcc, '^84.40[12345]') --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else 0 end) as garp_p,
                sum(case when cast(tipo_credito as int) between 1 and 10  and regexp_like(cod_cuenta_rcc, '^84.4(09|10)')--and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
                then saldo else 0 end) as garp_np,
               MAX(case when SUBSTR(COD_CUENTA_RCC,1,2)='14' AND substr(COD_CUENTA_RCC,4,1)='3' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END ) AS FLAG_REF_REE,
            
            MAX(case when SUBSTR(COD_CUENTA_RCC,1,2)='14' AND substr(COD_CUENTA_RCC,4,1)='4' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END ) AS FLAG_REF,
            
            MAX(case when SUBSTR(COD_CUENTA_RCC,1,2)='14' AND substr(COD_CUENTA_RCC,4,1)='5' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END ) AS FLAG_VEN,
            
            MAX(case when SUBSTR(COD_CUENTA_RCC,1,2)='14' AND substr(COD_CUENTA_RCC,4,1)='6' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END ) AS FLAG_JUD,
            MAX(case when ((SUBSTR(COD_CUENTA_RCC,1,2)='81' AND SUBSTR(COD_CUENTA_RCC,4,3)='302') or (SUBSTR(COD_CUENTA_RCC,1,2)='81' AND SUBSTR(COD_CUENTA_RCC,4,3)='925')) and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END  ) AS FLAG_CAST,
            sum(case when substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,1)='8' and substr(cod_cuenta_rcc,6,1) in ('1','3','4','5','6') then saldo else 0 end) as sld_reactiva
        from (select distinct * from morigbk_rcc) a 
        group by codmes, tip_doc, key_value--, tipo_credito, cod_instit_financiera
    ),
    info_consolid as (
        select distinct a.codmes, a.tip_doc, a.key_value,--, b.cod_instit_financiera, 
                -- Dias de mora en cada mes en los Ãºltimos 12 meses
                sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_vig_m0,
                sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then sld_cons else 0 end) as sld_cons_m0,
                sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then sald_ref_mo else null end) as saldo_ref_m0,
                  sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then sald_jud_mo else null end) as saldo_jud_mo,
                  sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then sald_cast_mo else null end) as saldo_cast_mo,  
                   sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then sald_rest_mo else null end) as saldo_rest_mo,
                  sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then garp_p else 0 end) as saldo_gar_p,
                  sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then garp_np else 0 end) as saldo_gar_np,
                max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') +interval '0' month,'%Y%m') as int) then clasif_mo  else null end) as clasificacion_m0,

                 max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then dm else 0 end) as dm_fm0,

                  max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) then dm else 0 end) as dm_fm1,
                 max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '2' month,'%Y%m') as int) then dm else 0 end) as dm_fm2,
                 max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '3' month,'%Y%m') as int) then dm else 0 end) as dm_fm3,
                 max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '4' month,'%Y%m') as int) then dm else 0 end) as dm_fm4,
                  max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '5' month,'%Y%m') as int) then dm else 0 end) as dm_fm5,
                  max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then dm else 0 end) as dm_fm6,
                  max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '7' month,'%Y%m') as int) then dm else 0 end) as dm_fm7,
                  max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '8' month,'%Y%m') as int) then dm else 0 end) as dm_fm8,
                  max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then dm else 0 end) as dm_fm9,
                     max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '10' month,'%Y%m') as int) then dm else 0 end) as dm_fm10,
                        max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '11' month,'%Y%m') as int) then dm else 0 end) as dm_fm11,
                           max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then dm else 0 end) as dm_fm12,
                        max(case when (b.codmes between date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                           and date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m'))
                           then dm 
             else Null end) dias_atraso_12m,
             max(case when (b.codmes between date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                           and date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m'))
                           then dm 
             else Null end) dias_atraso_6m,
             max(case when (b.codmes between date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                           and date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m'))
                           then dm 
             else Null end) dias_atraso_9m,
             max(case when cast(b.codmes as int) between 
                  cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                  cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then FLAG_JUD else null end) as jud_12um,
             max(case when cast(b.codmes as int) between 
                  cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                  cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then FLAG_JUD else null end) as jud_09um,
             max(case when cast(b.codmes as int) between 
                  cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                  cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then FLAG_JUD else null end) as jud_06um,

       max(case when cast(b.codmes as int) between 
             cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then FLAG_CAST else null end) as cast_12um,
       max(case when cast(b.codmes as int) between 
             cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then FLAG_CAST else null end) as cast_09um,
       max(case when cast(b.codmes as int) between 
             cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then FLAG_CAST else null end) as cast_06um,

        max(case when cast(b.codmes as int) between 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then FLAG_REF_REE else null end) as ree_12um,
        max(case when cast(b.codmes as int) between 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then FLAG_REF_REE else null end) as ree_09um,
        max(case when cast(b.codmes as int) between 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then FLAG_REF_REE else null end) as ree_06um,


    max(case when cast(b.codmes as int) between 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then FLAG_REF else null end) as ref_12um,
    max(case when cast(b.codmes as int) between 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then FLAG_REF else null end) as ref_09um,
    max(case when cast(b.codmes as int) between 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then FLAG_REF else null end) as ref_06um,


    max(case when cast(b.codmes as int) between cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then FLAG_VEN else null end) as ven_12um,
    max(case when cast(b.codmes as int) between cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then FLAG_VEN else null end) as ven_09um,
    max(case when cast(b.codmes as int) between cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) and 
                     cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then FLAG_VEN else null end) as ven_06um,


    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as int) then saldo_total else null end) as SLD_M1, 
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '2' month,'%Y%m') as int) then saldo_total else null end) as SLD_M2,   
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '3' month,'%Y%m') as int) then saldo_total else null end) as SLD_M3,   
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '4' month,'%Y%m') as int) then saldo_total else null end) as SLD_M4, 
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '5' month,'%Y%m') as int) then saldo_total else null end) as SLD_M5,   
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '6' month,'%Y%m') as int) then saldo_total else null end) as SLD_M6,   
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '7' month,'%Y%m') as int) then saldo_total else null end) as SLD_M7,   
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '8' month,'%Y%m') as int) then saldo_total else null end) as SLD_M8,   
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '9' month,'%Y%m') as int) then saldo_total else null end) as SLD_M9, 
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '10' month,'%Y%m') as int) then saldo_total else null end) as SLD_M10, 
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '11' month,'%Y%m') as int) then saldo_total else null end) as SLD_M11, 
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '12' month,'%Y%m') as int) then saldo_total else null end) as SLD_M12,
    sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') + interval '0' month,'%Y%m') as int) then sld_reactiva else 0 end) as sld_reactiva
        -- from (select codmes,tip_doc, key_value   from d_mdl_riesgos_disc.PO_PREVIA_AD_BANK_FINAL_202306  where
        from (select codmes,tip_doc, key_value   from disc_model_owner.ds_adm_bpe_bankbn_po  where
                                     -- ((30000<=max_saldo and (saldo_m0 >= 10000 AND saldo_m0 < 30000)) or  (saldo_m0 >=30000)) and codmes='202306' 
                                     ((30000<=max_saldo and (saldo_m0 >= 10000 AND saldo_m0 < 30000)) or  (saldo_m0 >=30000)) and codmes='<CODMES>'  --Verificar si en la talba final se cumple esta condiicones del saldo
        group by 1,2,3) a

        left join (select distinct * from data_rcc) b
        on a.key_value=b.key_value and a.tip_doc=b.tip_doc
        group by a.codmes, a.tip_doc, a.key_value----, b.cod_instit_financiera
    )select *, 
          (CASE WHEN SLD_M1 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M2 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M3 IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN SLD_M4 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M5 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M6 IS NULL THEN 1 ELSE 0 END) AS NRO_MISS06,

          (CASE WHEN SLD_M1 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M2 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M3 IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN SLD_M4 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M5 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M6 IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN SLD_M7 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M8 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M9 IS NULL THEN 1 ELSE 0 END) AS NRO_MISS09,

          (CASE WHEN SLD_M1 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M2 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M3 IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN SLD_M4 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M5 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M6 IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN SLD_M7 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M8 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M9 IS NULL THEN 1 ELSE 0 END) +
          (CASE WHEN SLD_M10 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M11 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN SLD_M12 IS NULL THEN 1 ELSE 0 END) AS NRO_MISS12,
                case when saldo_gar_p>2 then  '01.1 Garantia Preferida'
                when saldo_gar_np>2  then '01. Garantia NoPreferida'
                else '02. Sin Garantia'  end flg_garantia,
               case when saldo_vig_m0 <= sld_reactiva then 1 else 0 end as flg_solo_reactiva,
               case when sld_reactiva > 0 then 1 else 0 end as flg_reactiva,
               case when sld_cons_m0>0 then 1 else 0 end flag_cons
                from info_consolid    where saldo_vig_m0 >0  
  -----and  dm_fm0=0  and (saldo_ref_m0=0 or saldo_jud_mo=0 or saldo_cast_mo=0 and saldo_rest_mo=0 ) 
  ),
  uni_conyuge as (select a.codmes,a.key_value,a.tip_doc,
  b.tipdoc_conyugue,b.coddoc_conyugue,b.fec_nacimiento as fec_nacimiento
  from (select  codmes ,tip_doc,key_value from morigbk_saldo_hist  where tip_doc!='2') a
  left join e_perm_aws.t_mst_reniec_rsk b
  on a.key_value=b.key_value and a.tip_doc =b.tip_doc
  ),
  fea_rcc as (select b.codmes,b.key_value,b.tip_doc,
  sum(case when (substr(COD_CUENTA_RCC,1,2)='14'and substr(cod_cuenta_rcc,7,2) not in ('01','04')) and substr(COD_CUENTA_RCC,4,1) in ('3','4','5','6') and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') then saldo else null end) as saldo_novig_neg,
  sum(case when (substr(COD_CUENTA_RCC,1,2)='14'and substr(cod_cuenta_rcc,7,2) not in ('01','04')) and substr(COD_CUENTA_RCC,4,1) in ('3','4','5','6') 
  ---and tipo_credito in ('01','02','03','04','05','06','07','08','09','10')  
  and cod_instit_financiera ='00002' then saldo else null end) as 
  saldo_novig_neg_ibk,
  sum( case when (substr(COD_CUENTA_RCC,1,2)='14') and substr(COD_CUENTA_RCC,4,1) in ('1','3','4','5','6') and  cod_clasificacion_deudor<>'0' and substr(cod_cuenta_rcc,7,2) not in ('01','04') then saldo else null end ) as sld_no_normal
  ---sum( case when (((substr(COD_CUENTA_RCC,1,2)='14') and substr(COD_CUENTA_RCC,4,1) in ('1','3','4','5','6')) or ((substr(COD_CUENTA_RCC,1,2)='81') and substr(COD_CUENTA_RCC,4,3) in ('302','925')) ) and  cod_clasificacion_deudor in ('2','3','4') then saldo else null end ) as sld_no_cpp,
  ---sum(case when ((SUBSTR(COD_CUENTA_RCC,1,2)='81' AND SUBSTR(COD_CUENTA_RCC,4,3)='302') or (SUBSTR(COD_CUENTA_RCC,1,2)='81' AND SUBSTR(COD_CUENTA_RCC,4,3)='925')) and   cod_instit_financiera ='00002' then saldo else null end) as sld_castigado_ibk
  from (select  codmes ,tip_doc,key_value from morigbk_saldo_hist   ) a
  -- inner join (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes>='202002'  and codmes<='202306'
  -- inner join (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes BETWEEN '202206' and '202306' --busca historia hacia atrás se acota a un año, en el código se ve que busca a un año (11 en realidad)
  inner join (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes BETWEEN '<CODMES_M12>' and '<CODMES>' 
  --and ---((substr(COD_CUENTA_RCC,1,2)='14'and substr(cod_cuenta_rcc,7,2) not in ('01','04'))  or (substr(COD_CUENTA_RCC,1,2)<>'14'))
  ) b
  on a.key_value=b.key_value and a.tip_doc=b.tip_doc
   group by b.codmes,b.key_value,b.tip_doc),
    rcc_titular as (
   select A.codmes,A.tip_doc,A.key_value,
   sum(case when date_format(date_parse(a.codmes,'%Y%m') - interval '11' month,'%Y%m')<=b.codmes and date_format(date_parse(a.codmes,'%Y%m') - interval '0' month,'%Y%m')>=b.codmes then saldo_novig_neg else null end) as saldo_novig_neg_12um, --??? 12 meses? considerando que inclye el origen, esta bien? 
    sum(case when  date_format(date_parse(a.codmes,'%Y%m') - interval '0' month,'%Y%m') = b.codmes then saldo_novig_neg else null end) as saldo_novig_neg_1um,
    sum(case when  date_format(date_parse(a.codmes,'%Y%m') - interval '0' month,'%Y%m') = b.codmes then sld_no_normal else null end) as saldo_Nonormal_1um
    ----sum(case when date_format(date_parse(a.codmes,'%Y%m') - interval '25' month,'%Y%m')<=b.codmes and date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m')>=b.codmes then sld_castigado_ibk else null end) as sld_castigado_ibk_24um,
     ---sum(case when date_format(date_parse(a.codmes,'%Y%m') - interval '14' month,'%Y%m')<=b.codmes and date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m')>=b.codmes then saldo_novig_neg_ibk  else null end) as sald_novig_neg_ibk_12um,
     ---sum(case when date_format(date_parse(a.codmes,'%Y%m') - interval '16' month,'%Y%m')<=b.codmes and date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m')>=b.codmes then sld_no_cpp  else null end) as sld_no_cpp_12um
    
   from (select  codmes ,tip_doc,key_value from morigbk_saldo_hist  )A 
   left join  fea_rcc B
   on
   a.key_value=b.key_value and a.tip_doc=b.tip_doc
  group by A.codmes,A.key_value,A.tip_doc),
  uni_rl as (select  b.codmes, b.key_value,b.tip_doc,a.key_value as nrodoc_rl,a.tip_doc as tipdoc_rl  --,c.fec_nacimiento fec_nacimiento_rl
  from e_perm_aws.t_mst_rep_legal_sunat_rsk a -- fuente aws: sunat
  inner join (select  codmes ,tip_doc,key_value from morigbk_saldo_hist    ) b -- fuente propia: cambiar base
  on a.ruc_value=b.key_value and cast(date_format(date_parse(cast(a.fec_vigencia as varchar),'%Y-%m-%d'), '%Y%m') as int) <= cast(b.codmes as int)
  --inner join e_perm_aws.t_mst_reniec_rsk c
  --on a.ruc_value=c.key_value
  group  by  b.codmes, b.key_value,b.tip_doc,a.key_value,a.tip_doc--,c.fec_nacimiento),
  ),
  nacimiento_rl as (select  a.codmes, a.key_value,a.tip_doc,min(c.fec_nacimiento) fec_nacimiento_rl_min,max(c.fec_nacimiento) fec_nacimiento_rl_max
  from uni_rl a -- fuente aws: sunat
  left join e_perm_aws.t_mst_reniec_rsk c
  on a.nrodoc_rl =c.key_value and a.tipdoc_rl =c.tip_doc
  group  by  1,2,3),
  fea_rcc_rl as (select b.codmes,a.nrodoc_rl,a.tipdoc_rl,
  sum(case when ((SUBSTR(COD_CUENTA_RCC,1,2)='81' AND SUBSTR(COD_CUENTA_RCC,4,3)='302') or (SUBSTR(COD_CUENTA_RCC,1,2)='81' AND SUBSTR(COD_CUENTA_RCC,4,3)='925')) then saldo else null end) as sld_castigado
  from uni_rl   a
  -- inner join (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes>='202002'  and codmes<='202306' --busca historia hacia atrás se acota a un año, en el código se ve que busca a un año (11 en realidad)
  -- inner join (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes BETWEEN '202206' and '202306' 
  inner join (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes BETWEEN '<CODMES_M12>' and '<CODMES>' 
  ---and ((substr(COD_CUENTA_RCC,1,2)='14'and substr(cod_cuenta_rcc,7,2) not in ('01','04'))  or (substr(COD_CUENTA_RCC,1,2)<>'14'))
  ) b
  on a.nrodoc_rl =b.key_value and a.tipdoc_rl=b.tip_doc
   group by b.codmes,a.nrodoc_rl,a.tipdoc_rl),
     rcc_rl as (
   select A.codmes,A.tipdoc_rl,A.nrodoc_rl,
    sum(case when date_format(date_parse(a.codmes,'%Y%m') - interval '11' month,'%Y%m')<=b.codmes and date_format(date_parse(a.codmes,'%Y%m') - interval '0' month,'%Y%m')>=b.codmes then sld_castigado else null end) as sld_castigado_12um_rl
   from uni_rl A
   left join  fea_rcc_rl B
   on
   a.nrodoc_rl=b.nrodoc_rl and a.tipdoc_rl=b.tipdoc_rl
  group by A.codmes,A.nrodoc_rl ,A.tipdoc_rl),
  rcc_rl_titular as (select a.codmes,a.tip_doc,a.key_value,
  sum(sld_castigado_12um_rl)sld_castigado_12um_rl
  from uni_rl  a 
  left join rcc_rl  b
  on 
  a.codmes=b.codmes and a.tipdoc_rl=b.tipdoc_rl and a.nrodoc_rl=b.nrodoc_rl
  group by a.codmes,a.tip_doc,a.key_value),
  filtro_sunat as (
  SELECT DISTINCT a.*

  FROM (
  SELECT a.*,RANK() OVER(PARTITION BY codmes,tip_doc,key_value 
            ORDER BY codmes,tip_doc,key_value, CL_ESTADO_num asc,fecalta2 desc) AS num

  FROM (  

  SELECT DISTINCT Y.*,

                     (CASE WHEN Y.TPOEMP IN ('01') THEN 'PPNNSN'
                 WHEN Y.TPOEMP IN ('02') THEN 'PPNNCN'
               WHEN Y.TPOEMP IN ('07') THEN 'EIRL'
                                                   WHEN Y.TPOEMP IN ('08') THEN 'SOCIEDAD CIVIL'
               WHEN Y.TPOEMP IN ('09') THEN 'SOCIEDAD IRREGULAR'
               WHEN Y.TPOEMP IN ('11') THEN 'ASOCIACION'
               WHEN Y.TPOEMP IN ('19') THEN 'CENTROS EDUCATIVO'
                     WHEN Y.TPOEMP IN ('26') THEN 'SA' 
                                                   WHEN Y.TPOEMP IN ('28') THEN 'SCRL'
               WHEN Y.TPOEMP IN ('39') THEN 'SAC'
               WHEN Y.TPOEMP IN ('43') THEN 'SMRL' ELSE 'OTROS' END ) AS CL_TPOEMP,

             
                     (CASE WHEN Y.ESTADO IN ('00')           THEN 'ACTIVO'
               WHEN Y.ESTADO IN ('01','02')      THEN 'BAJA PROV.'
                 WHEN Y.ESTADO IN ('03')           THEN 'SUSPENSION TEMP.'
                           WHEN Y.ESTADO IN ('04')           THEN 'ANUL.PROVI.-ACTO ILICITO'
               WHEN Y.ESTADO IN ('10','11','12') THEN 'CASERIO'
               WHEN Y.ESTADO IN ('21')           THEN 'OTROS OBLIG.' 
               WHEN Y.ESTADO IN ('22')           THEN 'INHABILITADO'
               WHEN Y.ESTADO IN ('30','31')      THEN 'ANULACION'
               WHEN Y.ESTADO IN ('32')           THEN 'PEND. INI. ACTIV.' ELSE 'MISSING' END ) AS CL_ESTADO,
              
           (CASE WHEN Y.ESTADO IN ('00') THEN 1 ELSE 0 END ) AS CL_ESTADO_num

    /*(CASE  WHEN Y.fecalta2 IN ('','11970611') THEN -99999 
           WHEN cast(Y.codmes as integer)<CAST(SUBSTR(Y.fecalta2,1,4) AS INTEGER) THEN -99999  
           WHEN (DATE_DIFF('year', date_parse(Y.fecalta2, '%Y%m%d'), date_parse(cast(cast(Y.codmes as INTEGER) as varchar(100)), '%Y%m')))<0 THEN -99999
                           ELSE (
    DATE_DIFF('month', date_parse(Y.fecalta2, '%Y%m%d'), date_parse(cast(cast(Y.codmes as INTEGER) as varchar(100)), '%Y%m'))) END ) AS ANT_NEGOCIO*/
                          
  FROM (
  SELECT DISTINCT X.codmes,X.tip_doc,X.key_value,
                (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.tipcontribuyente END) AS TPOEMP,
                (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.estadocontribuyente END) AS ESTADO,
                (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.UBIGEO END) AS UBIGEO,
                (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN '' ELSE Y.fecalta2 END) AS fecalta2,
                (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.CIIU END) AS CIIU
          
  FROM (select codmes ,tip_doc,key_value from morigbk_saldo_hist   group by 1,2,3 )  X
  LEFT JOIN (SELECT X.*,(CASE WHEN X.flg_ruc=10 THEN '1' 
                              WHEN (X.flg_ruc=15) THEN '1' 
                              WHEN (X.flg_ruc=17) THEN '1' ELSE '2' END) AS TIPDOC,
                        (CASE WHEN (X.flg_ruc=10 OR
                                    X.flg_ruc=15 OR
            X.flg_ruc=17 ) THEN Y.key_value ELSE X.ruc_value END) AS NRODOC
            
  FROM (select a.*,cast(extract(year from a.fecalta)*10000 + extract(month from a.fecalta)*100 + extract(day from a.fecalta) as varchar(8)) as fecalta2 from e_perm_aws.t_mst_princ_sunat_rsk a) X
  -- LEFT JOIN e_perm_aws.t_mst_sec_sunat_rsk Y ON (X.ruc_value=Y.ruc_value)
  LEFT JOIN (
              select * , 
              RANK() OVER (PARTITION BY tip_doc, key_value ORDER BY fecproceso, fecinicio, estadoregistro,ruc_value DESC) AS num
              from e_perm_aws.t_mst_sec_sunat_rsk) Y ON (X.ruc_value=Y.ruc_value) and y.num=1
  WHERE X.fecalta2<>'') Y 
  ON (X.tip_doc=Y.TIPDOC AND X.key_value=Y.NRODOC)

    ) Y
  ) a 
  -- WHERE a.CODMES=201810
  -- AND a.nrodoc LIKE '%67EC9D70279DA0479B598400A2FBF3B56DE3D0740BA42D%'
  -- ORDER BY a.rx6m12_micro DESC 
   ) a 

  WHERE a.num =1

  ),
  filtro_sunat2 as (select a.*,b.tpoemp,b.estado,b.fecalta2,b.ciiu,b.ubigeo,b.cl_tpoemp,b.cl_estado,b.cl_estado_num--,b.ant_negocio
  from (select codmes ,tip_doc,key_value from morigbk_saldo_hist  ) a
  left join filtro_sunat b
  on a.codmes=b.codmes and a.tip_doc=b.tip_doc and a.key_value=b.key_value),

  filtros_bpe as (select distinct a.*,
  case when tpoemp='01' then 'PPNN_SN' when tpoemp='02' then 'PPNN_CN' else 'PPJJ' end as tipo_personeria,
  case when cl_estado= 'ACTIVO' AND tpoemp<>'01' AND Ubigeo_restringido<>1 AND Giro_restringido<>1 and 
  (trim(ubigeo) not in  ('SIN_DATO','')) THEN 1 ELSE 0 END AS flag_bpe_v1,
  case when cl_estado= 'ACTIVO' AND Ubigeo_restringido<>1 AND Giro_restringido<>1 and (trim(ubigeo) not in  ('SIN_DATO','')) 
  THEN 1 ELSE 0 END AS flag_bpe_v2
  -- from (select a.*,case when c.flag_aceptanuevos='0' then 1 
  --                 when c.flag_aceptanuevos='1' then 0 else -1 end Giro_restringido,
  from (select a.*,case when c.flag_aceptanuevos='Restringido' then 1 
                when c.flag_aceptanuevos='Atendido' then 0 else -1 end Giro_restringido,
  -- case when d.Flag_ZonaBpe=1 then 0 
  --     when d.Flag_ZonaBpe=0 then 1
  case when d.Flag_ZonaBpe='Atendido' then 0 
       when d.Flag_ZonaBpe='Restringido' then 1
      else -1  end Ubigeo_restringido

  from filtro_sunat2 a
  -- left join d_mdl_riesgos_disc.moa_Giro_restringido_BPE c on a.ciiu=c.cod_actividadeconomica_t
  -- left join d_perm_aws.moa_Fuente_Catalogo_Ubigeos2 d on a.ubigeo =d.cod_ubigeo
  left join (select codigoacteconomica,max(flag_aceptanuevos) as flag_aceptanuevos from e_perm_aws.t_mst_bpe_giros_restringidos group by 1) c on a.ciiu=c.codigoacteconomica
left join (select cod_ubigeo,max(Flag_ZonaBpe) as Flag_ZonaBpe from e_perm_aws.t_mst_bpe_ubigeos_restringidos group by 1) d on a.ubigeo =d.cod_ubigeo
-- left join d_perm_aws.t_mst_bpe_ubigeos_restringidos d on a.ubigeo =d.cod_ubigeo
  ) a
  )
    -- select codmes, count(1), count(distinct concat(tip_doc,key_value)) from   morigbk_saldo_hist group by 1 si cuadra 
  ,flag_bpe as (
  select A.*
      ,case when  saldo_novig_neg_1um>0 then '01. Titular con Saldo Comercial No Vigente RCC (Ultimo mes)'
             when saldo_novig_neg_12um>0 then  '02. Titular con Saldo Comercial No Vigente RCC (Ultimos 12 meses)'
             when saldo_Nonormal_1um>0 then  '03. Titular con Calificacion SBS diferente a 100% Normal'
             when  sld_castigado_12um_rl>0 then  '09. RRLL con Saldo RCC en Castigo (Ultimos 12 meses)'
            when  (COALESCE(CAST(SUBSTRING(a.codmes, 1, 4) AS INT) - cast(EXTRACT(YEAR FROM fec_nacimiento) as int), 30) <= 25) OR (COALESCE(CAST(SUBSTRING(a.codmes, 1, 4) AS INT) - cast(EXTRACT(YEAR FROM fec_nacimiento) as int), 30) >= 75) then  '17. Titular >= 75 o < 25 anos'
            when  (COALESCE(CAST(SUBSTRING(a.codmes, 1, 4) AS INT) - cast(EXTRACT(YEAR FROM fec_nacimiento_rl_max) as int), 30)<=25) OR (COALESCE(CAST(SUBSTRING(a.codmes, 1, 4) AS INT) - cast(EXTRACT(YEAR FROM fec_nacimiento_rl_min) as int), 30) >= 75) then  '18. RRLL >= 75 o < 25 anos'
             when tipo_personeria='PPNN_SN' then '19. PNSN'
              when ESTADO not in ('00','03') then '20. Estado Diferente A' 
         when Giro_restringido=1 then  '22. Giro Restringido'
         when Ubigeo_restringido=1 then  '23. Ubigeo Restringido'
         else '99. Sin Caida'  end flag_bpe_parcial
  from  morigbk_saldo_hist A

  left join rcc_rl_titular B
  on 
  A.key_value=B.key_value and A.tip_doc=B.tip_doc and A.codmes=B.codmes
  ---left join 
   ----rcc_cony C
   ---on 
  ---A.key_value=C.key_value and A.tip_doc=C.tip_doc
  left join 
  uni_conyuge  D
  on 
  A.key_value=D.key_value and A.tip_doc=D.tip_doc and A.codmes=D.codmes
  left join 
  nacimiento_rl   F
  on 
  A.key_value=F.key_value and A.tip_doc=F.tip_doc  and A.codmes=F.codmes

  left join 
   rcc_titular  H
  on 
  A.key_value=H.key_value and A.tip_doc=H.tip_doc and A.codmes=H.codmes
  left join 
  filtros_bpe J
  on 
  A.key_value=J.key_value and A.tip_doc=J.tip_doc   and A.codmes=J.codmes
  ),
  especiales as (

    SELECT  
    a.cliente_id, 
    a.fecha_dt,
    case when a.fecha_dt ='' then null else substring(a.fecha_dt, 1, 10) end as fechaingreso,
    case when a.fecha_habilita_dt = '' then null else substring(a.fecha_habilita_dt, 1, 10) end as FechaHabilita,
    -- a.fecha_habilita_dt,
    b.cod_tipo_doc_val as tip_doc,
    b.num_doc_val as key_value,
    -- b.cod_unico_val as cod_cuc, 
    CASE a.cod_tipo_val
      WHEN '1' THEN 'Negativo'
      WHEN '2' THEN 'Sobreendeudamiento'
      WHEN '3' THEN 'Vigilancia Especial'
    ELSE 'Error'
    END as TipoIngreso
    FROM (select cliente_id,fecha_dt,fecha_habilita_dt,cod_tipo_val from  e_perm_aws.T_REL_VPC_MYP_CLIENTENEGATIVO group by 1,2,3,4) a
    JOIN (select cliente_id,cod_tipo_doc_val,num_doc_val from  e_PERM_AWS.T_MST_VPC_MYP_CLIENTE_ACTUAL group by 1,2,3) b 
    ON a.cliente_id = b.cliente_id

    )  --CRUCE CON BASES ESPECIALES
  ,cruce_titular AS ( --Cruce de titualres con base especiales
    SELECT
        -- A.codmes,
        -- A.tip_doc,
        -- A.key_value,
        A.*,
        CASE WHEN B.tip_doc IS NOT NULL AND B.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS FlagCruce,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value ORDER BY a.codmes, a.tip_doc, a.key_value, b.fecha_dt DESC) AS num
    FROM
        -- (SELECT * FROM d_mdl_riesgos_disc.PO_PREVIA_AD_BANK_FINAL_202306) A  
        flag_bpe A
    LEFT JOIN (
        SELECT
            *,
            DATE_FORMAT(DATE_TRUNC('MONTH', COALESCE(CAST(FechaHabilita AS DATE), CURRENT_DATE)), '%Y%m') AS Considerar_hasta,
            DATE_FORMAT(DATE_TRUNC('MONTH', CAST(fechaingreso AS DATE)), '%Y%m') AS codmesfechaingreso 
        FROM 
            -- discovery_riesgos_retail.BASE_ESPECIALES 
            -- disc_monitorian.t_dan_mrm_base_especiales 
            especiales 
        WHERE 
            TipoIngreso IN ('Vigilancia Especial', 'Sobreendeudamiento', 'Negativo')
    ) B ON
        A.tip_doc = B.tip_doc
        AND A.key_value = B.key_value
        AND (A.codmes < B.Considerar_hasta AND A.codmes >= B.codmesfechaingreso)


)
-- select codmes, count(1), count(distinct concat(tip_doc,key_value)) from   cruce_titular  group by 1 --
-- select codmes, count(1), count(distinct concat(tip_doc,key_value)) from   cruce_titular where num=1  group by 1 --
-- select * from cruce_titular where key_value in (select key_value from (select tip_doc,key_value,count(1) from   cruce_titular where num=1 group by 1,2 having count(1) >1)) order by key_value
,base_cny AS ( --Obtención de ID de conyuges
    SELECT 
        a.codmes,
        a.key_value,
        a.tip_doc,
        -- a.*,
        b.tipdoc_conyugue,
        b.coddoc_conyugue,
        b.fec_inscripcion,
        RANK() OVER (PARTITION BY a.codmes, b.tipdoc_conyugue, b.coddoc_conyugue ORDER BY a.codmes, b.tipdoc_conyugue, b.coddoc_conyugue, fec_inscripcion DESC) AS num
    FROM 
        -- (SELECT codmes, tip_doc, key_value FROM d_mdl_riesgos_disc.PO_PREVIA_AD_BANK_FINAL_202306 WHERE tip_doc <> '2') a
        -- (SELECT * FROM cruce_titular WHERE tip_doc <> '2') a
        (SELECT * FROM cruce_titular WHERE tip_doc <> '2' and num=1) a
    INNER JOIN 
        e_perm_aws.t_mst_reniec_rsk b ON 
        a.key_value = b.key_value 
        AND CAST(CAST(a.tip_doc AS INT) AS VARCHAR) = b.tip_doc
    WHERE 
        TRIM(b.tipdoc_conyugue) <> '' 
        AND TRIM(b.coddoc_conyugue) <> ''
),
especial_cny AS (--Cruce de ID Conyuge con bases especiales
    SELECT
        -- A.*
        A.codmes,
        A.tipdoc_conyugue,
        A.coddoc_conyugue,
        a.key_value,
        a.tip_doc,
        CASE WHEN B.tip_doc IS NOT NULL AND B.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS FlagCruce_cny,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value ORDER BY a.codmes, a.tip_doc, a.key_value, b.fecha_dt DESC) AS num
    FROM 
        (SELECT * FROM base_cny WHERE num = 1) A
    LEFT JOIN (
        SELECT
            *,
            DATE_FORMAT(DATE_TRUNC('MONTH', COALESCE(CAST(FechaHabilita AS DATE), CURRENT_DATE)), '%Y%m') AS Considerar_hasta,
            DATE_FORMAT(DATE_TRUNC('MONTH', CAST(fechaingreso AS DATE)), '%Y%m') AS codmesfechaingreso 
        FROM 
            -- discovery_riesgos_retail.BASE_ESPECIALES 
            -- disc_monitorian.t_dan_mrm_base_especiales
            especiales
        WHERE 
            TipoIngreso IN ('Vigilancia Especial', 'Sobreendeudamiento', 'Negativo')
    ) B ON
        A.tipdoc_conyugue = B.tip_doc
        AND A.coddoc_conyugue = B.key_value
        AND (A.codmes < B.Considerar_hasta AND A.codmes >= B.codmesfechaingreso)
),
base_flag_cny AS (
    SELECT 
        A.*,
        -- A.codmes,
        -- A.tip_doc,
        -- A.key_value,
        -- CASE WHEN B.tip_doc IS NOT NULL AND B.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS FlagCruce_cny
        B.FlagCruce_cny
    FROM 
        -- (SELECT * FROM d_mdl_riesgos_disc.PO_PREVIA_AD_BANK_FINAL_202306) A 
        -- cruce_titular A --volvemos a cruzar con la base toral por que para sacar los conyuges excluimos el tip_doc 2
        (select * from cruce_titular where num=1) A 
    LEFT JOIN 
        (select * from especial_cny where num =1) B ON
        A.codmes = B.codmes 
        -- AND A.tip_doc = B.tipdoc_conyugue 
        -- AND A.key_value = B.coddoc_conyugue
        AND A.tip_doc = B.tip_doc 
        AND A.key_value = B.key_value
)
-- select codmes, count(1), count(distinct concat(tip_doc,key_value)) from   base_flag_cny  group by 1 --
-- select * from base_flag_cny where key_value in (select key_value from (select tip_doc,key_value,count(1) from   base_flag_cny  group by 1,2 having count(1) >1)) order by key_value
-- select * from filtros_bpe where key_value in (select key_value from (select tip_doc,key_value,count(1) from   filtros_bpe  group by 1,2 having count(1) >1)) order by key_value
-- select * from filtros_bpe where key_value=''

  select  
  a.codmes ,
  a.tip_doc,
  a.key_value,--dm_fm1

  b.puntuacion,



  b.woe_beta_sldoppcomer,
  b.woe_prm_decresldo12m,
  b.woe_nro_decresldo12m,
  b.woe_beta_nroenti,
  b.woe_max_nrocredsldo06m,
  b.woe_prm_porcsldoimpa12m,
  b.woe_peor_clasicony09m,
  b.woe_prm_decresldopp12m,
  b.woe_prm_usotcfueraibk12m,
  b.woe_prm_decresldotc12m,
  b.woe_beta_sldopp12m,
  b.woe_max_dismsldonoprinc12m,
  b.woe_max_nroentinegocny06m,
  b.woe_nro_mesesatrasmay8dias09m,
  b.woe_max_dismsldoretail03m,
  b.woe_beta_sldotc12m,
  b.woe_rat_sldo09msobre12mrl,
  b.woe_max_diasatras09mrl,
  b.woe_nro_dismsaldonormal12mcny,
  b.woe_max_dismsldo12rl,
  b.woe_nro_mesesdismsldoretail12m,
  b.woe_rat_sldonormal3msobre12mrl,
  b.woe_porc_messldogiro06m,
  b.woe_prm_ratdispefect03m,
  b.woe_nro_mesesdicmsldoprinc12m,
  b.woe_prm_valorexpimp12m,
  b.woe_min_sldopasi06m,
  b.woe_cant_entireportsisnoreg,
  b.woe_prm_deudatelco12m,
  b.woe_cant_vehi,
  b.woe_anti_negmeses,
  b.woe_prm_nrotrxcashout06m,
  b.woe_nro_mesescastin06m,
  b.woe_edad,
  b.woe_dpt_grupo_v2,
  b.woe_ciiu_grupo_v2,
  b.rat_promsldnegdecreprin3y6m,
  b.rat_promsldnegdecre03y06m,
  b.woe_avg_porcsald_otrasent12m,

  a.dm_fm1,
  a.dm_fm2,
  a.dm_fm3,
  a.dm_fm4,
  a.dm_fm5,
  a.dm_fm6,
  a.dm_fm7,
  a.dm_fm8,
  a.dm_fm9,
  a.dm_fm10,
  a.dm_fm11,
  a.dm_fm12,

  a.SLD_M1,
  a.SLD_M2,
  a.SLD_M3,
  a.SLD_M4,
  a.SLD_M5,
  a.SLD_M6,
  a.SLD_M7,
  a.SLD_M8,
  a.SLD_M9,
  a.SLD_M10,
  a.SLD_M11,
  a.SLD_M12,

  a.clasificacion_m0,  
  a.dm_fm0,
  a.saldo_ref_m0,
  a.saldo_jud_mo, 
  a.saldo_cast_mo, 
  a.saldo_rest_mo,
  a.dias_atraso_6m,
  a.dias_atraso_9m,
  a.dias_atraso_12m,  

  CASE WHEN dias_atraso_6m > 90 OR jud_06um = 1 OR cast_06um = 1 OR ref_06um = 1 OR ree_06um = 1 THEN 1 ELSE 0 END target_06m,
  CASE WHEN dias_atraso_9m > 90 OR jud_09um = 1 OR cast_09um = 1 OR ref_09um = 1 OR ree_09um = 1 THEN 1 ELSE 0 END target_09m,
  CASE WHEN dias_atraso_12m > 90 OR jud_12um = 1 OR cast_12um = 1 OR ref_12um = 1 OR ree_12um = 1 THEN 1 ELSE 0 END target_12m,


  a.flg_garantia,
  CASE 
      WHEN flg_reactiva = 0 AND flg_solo_reactiva = 0 THEN 'SOLO NEGOCIO'
      WHEN flg_reactiva = 1 AND flg_solo_reactiva = 0 THEN 'MIXTO'
      WHEN flg_reactiva = 1 AND flg_solo_reactiva = 1 THEN 'REACTIVA'
      ELSE 'SIN DEUDA' 
  END AS segmento_reactiva,
  a.flag_cons,
  -- 'bpe_parcial' as "flag_bpe_parcial",
  a.flag_bpe_parcial,
  a.FlagCruce_cny,
  a.FlagCruce,

  CASE 
      WHEN saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN' -- OK (5) Filtro Origen 
      WHEN saldo_jud_mo IS NOT NULL THEN 'JUDICIAL_ORIGEN' -- OK (6) Filtro Origen 
      WHEN saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN' -- OK (8) Filtro Origen --Ver lógica
      WHEN saldo_ref_m0 IS NOT NULL THEN 'REFINANCIADO_ORIGEN' -- OK (7) Filtro Origen --Ver lógica
      WHEN clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL' -- OK (X) Filtro Origen
      WHEN flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN' -- OK (2) Filtro Origen
      WHEN FlagCruce ='Cruce' OR FlagCruce_cny ='Cruce' THEN 'ESPECIALES'
      WHEN NRO_MISS06 = 6 THEN 'SIN_INFORMACION' -- OK (3) Filtro Target
      WHEN NRO_MISS06 > 3 THEN 'INSUFICIENTE'  -- OK (4) Filtro Target
      WHEN dias_atraso_6m > 90 OR jud_06um = 1 OR cast_06um = 1 OR ref_06um = 1 OR ree_06um = 1 THEN 'MALO'
      WHEN dias_atraso_6m <= 90 AND dias_atraso_6m > 30 THEN 'INDETERMINADO' -- OK (1) Filtro Target
      ELSE 'BUENO' 
  END AS flag_malo_06m,
  CASE 
      WHEN saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN' -- OK (5) Filtro Origen 
      WHEN saldo_jud_mo IS NOT NULL THEN 'JUDICIAL_ORIGEN' -- OK (6) Filtro Origen 
      WHEN saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN' -- OK (8) Filtro Origen --Ver lógica
      WHEN saldo_ref_m0 IS NOT NULL THEN 'REFINANCIADO_ORIGEN' -- OK (7) Filtro Origen --Ver lógica
      WHEN clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL' -- OK (X) Filtro Origen
      WHEN flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN' -- OK (2) Filtro Origen
      WHEN FlagCruce ='Cruce' OR FlagCruce_cny ='Cruce' THEN 'ESPECIALES'
      WHEN NRO_MISS09 = 9 THEN 'SIN_INFORMACION' -- OK (3) Filtro Target
      WHEN NRO_MISS09 > 4 THEN 'INSUFICIENTE'  -- OK (4) Filtro Target
      WHEN dias_atraso_9m > 90 OR jud_09um = 1 OR cast_09um = 1 OR ref_09um = 1 OR ree_09um = 1 THEN 'MALO'
      WHEN dias_atraso_9m <= 90 AND dias_atraso_9m > 30 THEN 'INDETERMINADO' -- OK (1) Filtro Target
      ELSE 'BUENO' 
  END AS flag_malo_09m,

  CASE 
      WHEN saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN' -- OK (5) Filtro Origen 
      WHEN saldo_jud_mo IS NOT NULL THEN 'JUDICIAL_ORIGEN' -- OK (6) Filtro Origen 
      WHEN saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN' -- OK (8) Filtro Origen --Ver lógica
      WHEN saldo_ref_m0 IS NOT NULL THEN 'REFINANCIADO_ORIGEN' -- OK (7) Filtro Origen --Ver lógica
      WHEN clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL' -- OK (X) Filtro Origen
      WHEN flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN' -- OK (2) Filtro Origen
      WHEN FlagCruce ='Cruce' OR FlagCruce_cny ='Cruce' THEN 'ESPECIALES'
      WHEN NRO_MISS12 = 12 THEN 'SIN_INFORMACION' -- OK (3) Filtro Target
      WHEN NRO_MISS12 > 6 THEN 'INSUFICIENTE'  -- OK (4) Filtro Target
      WHEN dias_atraso_12m > 90 OR jud_12um = 1 OR cast_12um = 1 OR ref_12um = 1 OR ree_12um = 1 THEN 'MALO'
      WHEN dias_atraso_12m <= 90 AND dias_atraso_12m > 30 THEN 'INDETERMINADO' -- OK (1) Filtro Target
      ELSE 'BUENO'  
  END AS flag_malo_12m,
  a.codmes as p_codmes

      --Falta agregar la marca bpe esta aparte en el notebook FiltroBPE (HECHO)
    -- • Nivel de Endeudamiento y Monto de Alta : se aplica al momento de sacar las altas de la tabla previa (Hecho)
    -- • Especiales (Sobre endeudamiento, vigilancia especial y negativo : Base de caídas especiales
      -- Nos quedamos con los que no cruzan (los que no están en sebreendeudados, negativos y vigilacia espacial) (Hecho)
    -- • Exclusión de Entidades : 
      -- HAy unabase de entidades que se deben excluir: Se coloca al final de la primera tabla de altas ((Pendiente d terminar las consideraciones duplicados))
    -- • Saldo vigente en el origen: Se aplica al moneto de generar la subconsulta  "morigbk_saldo_hist"



  from 
    base_flag_cny a
  inner join 
    e_perm_aws.scr_admbankbpe_rsk b on a.tip_doc=b.tip_doc and a.key_value=b.key_value 
    -- and a.codmes=b.p_codmes -- Se coloca el p_codmes por que en la tabla automatizada el p_codmes es fecha de campaña y el codmes es periodo RCC

    and a.codmes=cast(date_format(date_parse(cast(b.p_codmes as varchar),'%Y%m') + interval '1' month,'%Y%m') as varchar)
    -- and a.codmes=b.codmes -- test para ver  formato de tabla de flags
  -- where a.num=1  

