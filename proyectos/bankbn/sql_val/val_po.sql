-- ============================================================================
-- VAL PO ALTAS (read-only): conteos de la logica de PO para codmes=202405
-- ============================================================================
SELECT
    COUNT(*)                                    AS n_filas,
    COUNT(DISTINCT concat(tip_doc,key_value))   AS clientes,
    COUNT(DISTINCT codmes)                       AS meses,
    SUM(CASE WHEN max_saldo > 0 THEN 1 ELSE 0 END) AS con_maxsaldo
FROM (
with morigbk_tag as (--de todo el rcc saca la información de clientes y genera algunas marcas
    select codmes,tip_doc,key_value,condicion,tipo_credito,cod_cuenta_rcc,cod_instit_financiera,cod_clasificacion_deudor,
saldo,
        case 
            when substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('1','3','4','5','6') then --14: Valores y títulos de disponibilidad restringida
                case when cast(tipo_credito as int) between 8 and 10 then 
                        case
                            when (cast(tipo_credito as int) between 8 and 10) and substr(a.cod_cuenta_rcc,7,2)='05' then 'DESCUENTOS'
                            when (cast(tipo_credito as int) between 8 and 10) and substr(a.cod_cuenta_rcc,7,2)='10' then 'FACTORING'
                            when (cast(tipo_credito as int) between 8 and 10) and substr(a.cod_cuenta_rcc,7,2)='04' then 'SOBREGIRO' 
                            when (cast(tipo_credito as int) between 8 and 10) and substr(a.cod_cuenta_rcc,7,2)='01' then 'AVANCE CC'
                            else 'RESTO DD NEGOCIO'
                        end
                    else 'RESTO DD'
                end 
            when substr(a.cod_cuenta_rcc,1,2)='72' and substr(a.cod_cuenta_rcc,4,1)='5' then --72 contigente acreedoras --5 : RESPONSABILIDAD POR LÖNEAS DE CRÉDITO NO UTILIZADAS Y CRÉDITOS CONCEDIDOS NO DESEMBOLSADOS
                case when cast(tipo_credito as int) between 8 and 10 then 
                        case 
                            when (cast(tipo_credito as int) between 8 and 10) and substr(a.cod_cuenta_rcc,5,2)='02' then 'LC DESCUENTO'
                            when (cast(tipo_credito as int) between 8 and 10) and substr(a.cod_cuenta_rcc,5,2) in ('03','06','08','09') then 'LC NO UTILIZADA' 
                            else 'RESTO LC NEGOCIO' 
                        end
                    else 'RESTO LC'
                end
        else 'OTROS' end as tag,
        case when cod_instit_financiera in ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') then 1 else 0 end as ent_honrada -- entidad honrada ??
    from (select codmes,tip_doc,key_value,condicion,tipo_credito,cod_cuenta_rcc,cod_instit_financiera,cod_clasificacion_deudor,
saldo  from e_perm_aws.t_fact_report_rcc_rsk  ) a  -- fuente aws: RCC
    where codmes='202405' --FECHA
),
morigbk_rcc as ( -- se queda solo con tag in ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA', 'LC DESCUENTO') y con ent_honrada=0
                 -- busca historia en el rcc para sacar garantía, ent_honrada otra vez, garantía, tipo de credito , y datos rcc (saldo, cuenta rcc, etc)
select distinct a.codmes,
a.tip_doc,
a.key_value,
a.condicion,
a.tipo_credito,
a.cod_cuenta_rcc,
a.cod_instit_financiera,
a.cod_clasificacion_deudor,
a.saldo,
        case 
            when substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('1','3','4','5','6') then   
                case
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='05' then 'DESCUENTOS'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='10' then 'FACTORING'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='04' then 'SOBREGIRO' 
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='01' then 'AVANCE CC'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,4,1)='4' then 'REFINANCIADOS'
                    else 'RESTO DD'
                end
            when substr(a.cod_cuenta_rcc,1,2)='72' and substr(a.cod_cuenta_rcc,4,1)='5' then 
                case 
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,5,2)='02' then 'LC DESCUENTO'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,5,2) in ('03','06','08','09') then 'LC NO UTILIZADA' 
                    else 'RESTO LC' 
                end
        else 'OTROS' end as tag,
        case when a.cod_instit_financiera in ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') then 1 else 0 end as ent_honrada,
        case when regexp_like(cod_cuenta_rcc, '^84.40[12345]') then 'gar_p'
        when regexp_like(cod_cuenta_rcc, '^84.4(09|10)') then 'gar_np'
        else 'Sin Garantia' end garantia,
        case
    when tipo_credito in ('01','02','03','04','05') then 'ins'
    when tipo_credito in ('06','07','08','09','10') then 'neg'
    when tipo_credito in ('11','12','13')           then 'con'
    else 'otro'
end flg_tipo_credito
    from (select * from e_perm_aws.t_fact_report_rcc_rsk where codmes between '202305' and '202405')a  -- fuente aws: reporte rcc 
    inner join (select  tip_doc, key_value from morigbk_tag 
    where tag in ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA', 'LC DESCUENTO') and ent_honrada=0
    group by 1,2) b -- fuente propia: initial PO
    on a.tip_doc = b.tip_doc and a.key_value = b.key_value ---- and a.cod_instit_financiera=b.cod_instit_financiera 
    -- and a.codmes>='202002' --FECHA --Se acuerdo con isma colocar el mes M-12 Ejem: para 202405 M-12 es 202305
    -- and a.codmes>='202305'
    -- and codmes between '202305' and '202405'--Se acuerdo con isma colocar el mes M-12 Ejem: para 202405 M-12 es 202305 v2: se acomta már los meses a consultar se coloca en sub consulta para optimizar
    
    /*between cast(date_format(date_parse(cast(b.codmes as varchar),'%Y%m') - interval '13' month,'%Y%m') as int) 
    and cast(date_format(date_parse(cast(b.codmes as varchar),'%Y%m') - interval '0' month, '%Y%m') as int*/
),
morigbk_saldo_hist as ( 
with data_rcc as (  -- saca diferentes tipos de saldo utilizando marcas distintas agrupando por mes, cliente, tip_cred, entidad
    select codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera,
            max(case when cast(tipo_credito as int) between 1 and 10 and tag in ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA', 'LC DESCUENTO') then condicion else null end) as dm,
            sum(case when cast(tipo_credito as int) between 1 and 10 and tag in ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA', 'LC DESCUENTO') then saldo else 0 end) as saldo_mo,
            sum(case when cast(tipo_credito as int) between 8 and 10 and tag in ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA', 'LC DESCUENTO') and ent_honrada=0 then saldo else 0 end) as saldo_m0_entidad,
            sum(case when garantia='gar_p' then saldo else null end )saldo_gar_p,
            sum(case when garantia='gar_np' then saldo else null end )saldo_gar_np,
            sum(case when garantia='Sin Garantia' then saldo else null end )saldo_sg,
            sum(case when flg_tipo_credito = 'ins' and  regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)')  then saldo else 0 end) deuda_ins,
            sum(case when flg_tipo_credito = 'neg'   and  regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)')     then saldo else 0 end) deuda_neg,
            sum(case when flg_tipo_credito = 'con'   and  regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)')  then saldo else 0 end) deuda_con
    from (select distinct * from morigbk_rcc) a 
    group by codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera
),
info_consolid as (
    select distinct a.codmes, a.tip_doc, a.key_value, b.cod_instit_financiera, 
            -- Dias de mora en cada mes en los últimos 12 meses
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '0' month,'%Y%m') as int) then dm else 0 end) as dm_m0,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '1' month,'%Y%m') as int) then dm else 0 end) as dm_m1,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '2' month,'%Y%m') as int) then dm else 0 end) as dm_m2,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '0' month,'%Y%m') as int) then saldo_gar_p   else 0 end) as gar_p,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '0' month,'%Y%m') as int) then saldo_gar_np else 0 end) as gar_np ,         
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '3' month,'%Y%m') as int) then dm else 0 end) as dm_m3,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '4' month,'%Y%m') as int) then dm else 0 end) as dm_m4,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '5' month,'%Y%m') as int) then dm else 0 end) as dm_m5,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '6' month,'%Y%m') as int) then dm else 0 end) as dm_m6,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '7' month,'%Y%m') as int) then dm else 0 end) as dm_m7,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '8' month,'%Y%m') as int) then dm else 0 end) as dm_m8,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '9' month,'%Y%m') as int) then dm else 0 end) as dm_m9,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '10' month,'%Y%m') as int) then dm else 0 end) as dm_m10,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '11' month,'%Y%m') as int) then dm else 0 end) as dm_m11,
            max(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '12' month,'%Y%m') as int) then dm else 0 end) as dm_m12,
            min(case when cast(b.tipo_credito as int) between 8 and 10 then b.tipo_credito end) as tipo_credito,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '0' month,'%Y%m') as int) then saldo_m0_entidad else 0 end) as saldo_m0,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '1' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m1,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '2' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m2,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '3' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m3,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '4' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m4,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '5' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m5,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '6' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m6,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '7' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m7,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '8' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m8,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '9' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m9,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '10' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m10,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '11' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m11,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '12' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m12,
            SUM(CASE  WHEN CAST(b.codmes AS INT)>=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '12' MONTH, '%Y%m') AS INT) AND CAST(b.codmes AS INT)<=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '1' MONTH, '%Y%m') AS INT) THEN deuda_ins ELSE NULL END) AS deuda_ins_u12m,
            SUM(CASE  WHEN CAST(b.codmes AS INT)>=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '12' MONTH, '%Y%m') AS INT) AND CAST(b.codmes AS INT)<=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '1' MONTH, '%Y%m') AS INT) THEN deuda_neg ELSE NULL END) AS deuda_neg_u12m,
            SUM(CASE  WHEN CAST(b.codmes AS INT)>=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '12' MONTH, '%Y%m') AS INT) AND CAST(b.codmes AS INT)<=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '1' MONTH, '%Y%m') AS INT) THEN deuda_con ELSE NULL END) AS deuda_con_u12m,
            SUM(CASE  WHEN CAST(b.codmes AS INT)>=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '13' MONTH, '%Y%m') AS INT) AND CAST(b.codmes AS INT)<=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '2' MONTH, '%Y%m') AS INT) THEN deuda_ins ELSE NULL END) AS deuda_ins_u12m_v2,
            SUM(CASE  WHEN CAST(b.codmes AS INT)>=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '13' MONTH, '%Y%m') AS INT) AND CAST(b.codmes AS INT)<=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '2' MONTH, '%Y%m') AS INT) THEN deuda_neg ELSE NULL END) AS deuda_neg_u12m_v2,
            SUM(CASE  WHEN CAST(b.codmes AS INT)>=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '13' MONTH, '%Y%m') AS INT) AND CAST(b.codmes AS INT)<=CAST(DATE_FORMAT(DATE_PARSE(CAST(a.codmes AS VARCHAR), '%Y%m') - INTERVAL '2' MONTH, '%Y%m') AS INT) THEN deuda_con ELSE NULL END) AS deuda_con_u12m_v2
    from (select  codmes, tip_doc, key_value,cod_instit_financiera from morigbk_tag where saldo>0 
    and tag in ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA', 'LC DESCUENTO') and ent_honrada=0
   group by 1,2,3,4 ) a
    left join (select distinct * from data_rcc) b
    on a.key_value=b.key_value and a.tip_doc=b.tip_doc and a.cod_instit_financiera=b.cod_instit_financiera
    -- where cast(b.tipo_credito as int) between 8 and 10 --Agregado optimización x
    group by a.codmes, a.tip_doc, a.key_value, b.cod_instit_financiera
    

), 
-- Maximo saldo en el histórico
max_saldo as (
    select a.*,
        greatest(saldo_m1,saldo_m2,saldo_m3,saldo_m4,saldo_m5,saldo_m6,saldo_m7,saldo_m8,saldo_m9,saldo_m10,saldo_m11,saldo_m12) as max_saldo
    from (select * from info_consolid where cast(tipo_credito as int) between 8 and 10) a
    -- from info_consolid a  --Modificado optimización x
), 
-- Tag para indicar si es un cliente que tiene el perfil que buscamos
marca_perfil as ( ---AL PARECER NO SE USAR EVALUAR SI SE SaAA
    select a.*, 
            case 
                when tipo_credito='08' and (max_saldo<=1000000) then 1                              -- Mediana
                when tipo_credito='09' and (max_saldo<=1000000) then 1                              -- Pequeña
                when tipo_credito='10' and (max_saldo > 10000  and max_saldo<=1000000) then 1       -- Micro
                else 0
            end as filtro_saldo
    from max_saldo a
)--, 
-- Generamos los saldos acumulados, para luego determinar las altas
-- saldo_acumulado as (
    select a.*, 
        saldo_m1 as saldo_mo_u1m,
        saldo_m1 + saldo_m2 as saldo_mo_u2m,
        saldo_m1 + saldo_m2 + saldo_m3 as saldo_mo_u3m, 
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4  as saldo_mo_u4m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 as saldo_mo_u5m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 as saldo_mo_u6m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 as saldo_mo_u7m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 as saldo_mo_u8m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 as saldo_mo_u9m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 + saldo_m10 as saldo_mo_u10m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 + saldo_m10 + saldo_m11 as saldo_mo_u11m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 + saldo_m10 + saldo_m11 + saldo_m12 as saldo_mo_u1a,
        case when gar_p>2 then '01.1 Garantia Preferida'
        when gar_np>2 then '01. Garantia NoPreferida'
        else '02. Sin Garantia' end flg_garantia
    from marca_perfil a
-- ) select * from saldo_acumulado 
),
--------------------
-- Altas
morigbk_altas as (
with data_altas as ( 
    select a.*,
            case when tipo_credito in ('08','09','10') and saldo_m0>0 then
                case
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m + saldo_mo_u10m + saldo_mo_u11m + saldo_mo_u1a) = 0 then 'A-12' 
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m + saldo_mo_u10m + saldo_mo_u11m) = 0 then 'A-11' 
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m + saldo_mo_u10m) = 0 then 'A-10'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m) = 0 then 'A-09'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m) = 0 then 'A-08'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m) = 0 then 'A-07'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m) = 0 then 'A-06'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m) = 0 then 'A-05'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m) = 0 then 'A-04'
                    when (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m) = 0 then 'A-03'
                    when (saldo_mo_u1m + saldo_mo_u2m) = 0 then 'A-02'
                    when (saldo_mo_u1m) = 0 then 'A-01'
                    else 'A-00'  -- Saldo continuo en los ultimos 12 meses
                end 
            else 'A-otro' end as altas   -- Saldo m0= 0
            
    from (select * from morigbk_saldo_hist ---where filtro_saldo=1
    ) a 
), 

marca_entidades as (
    select a.*,
        case when cod_instit_financiera='00002' then 'IBK' else 'OTRO' end as marca_entidad
    from data_altas a
), 
-- Marcamos las altas 12 y 6
marca_altas as (
    select a.*,
        case when altas='A-12' then 1 else 0 end as alta12,
        case when altas in ('A-06','A-07','A-08','A-09','A-10','A-11','A-12') then 1 else 0 end as alta6,
        
        --case when altas in ('A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') then 1 else 0 end as alta5,
        --case when altas in ('A-04','A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') then 1 else 0 end as alta4,
        --case when altas in ('A-03','A-04','A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') then 1 else 0 end as alta3,
        case when altas in ('A-02','A-03','A-04','A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') then 1 else 0 end as alta2
    from marca_entidades a
) select codmes,
tip_doc,
key_value,
cod_instit_financiera,
gar_p,
gar_np,
tipo_credito,
flg_garantia,
alta12,
alta6,
alta2,
dm_m0,max_saldo,filtro_saldo,saldo_m0,
deuda_ins_u12m,deuda_neg_u12m,deuda_con_u12m,deuda_ins_u12m_v2,deuda_neg_u12m_v2,deuda_con_u12m_v2
 from marca_altas ---where alta2=1 --select * from marca_altas where alta6=1

),
-- select *from morigbk_altas











morigbk_rcc_bank as (
    select distinct a.codmes,
a.tip_doc,
a.key_value,
a.condicion,
a.tipo_credito,
a.cod_cuenta_rcc,
a.cod_instit_financiera,
a.cod_clasificacion_deudor,
a.saldo,
        case 
            when substr(a.cod_cuenta_rcc,1,2)='14' and substr(a.cod_cuenta_rcc,4,1) in ('1','3','4','5','6') then   
                case
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='05' then 'DESCUENTOS'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='10' then 'FACTORING'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='04' then 'SOBREGIRO' 
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,7,2)='01' then 'AVANCE CC'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,4,1)='4' then 'REFINANCIADOS'
                    else 'RESTO DD'
                end
            when substr(a.cod_cuenta_rcc,1,2)='72' and substr(a.cod_cuenta_rcc,4,1)='5' then 
                case 
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,5,2)='02' then 'LC DESCUENTO'
                    when (cast(a.tipo_credito as int) between 1 and 10) and substr(a.cod_cuenta_rcc,5,2) in ('03','06','08','09') then 'LC NO UTILIZADA' 
                    else 'RESTO LC' 
                end
        else 'OTROS' end as tag,
        case when a.cod_instit_financiera in ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') then 1 else 0 end as ent_honrada,
        case when regexp_like(cod_cuenta_rcc, '^84.40[12345]') then 'gar_p' --Garanttías preferidas 
        when regexp_like(cod_cuenta_rcc, '^84.4(09|10)') then 'gar_np' --Garantías no preferidas
        else 'Sin Garantia' end garantia,
        case
    when tipo_credito in ('01','02','03','04','05') then 'ins'
    when tipo_credito in ('06','07','08','09','10') then 'neg'
    when tipo_credito in ('11','12','13')           then 'con'
    else 'otro'
end flg_tipo_credito
    from (select * from e_perm_aws.t_fact_report_rcc_rsk where  codmes between '202305' and '202405') a  -- fuente aws: reporte rcc 
    -- inner join (select tip_doc, key_value from   d_mdl_riesgos_disc.PO_PREVIA_AD_202305  where alta2=1 --filtara las altas a nivel de entidad, sólo saca la pobalción
    inner join (select tip_doc, key_value from   morigbk_altas  where alta2=1 --filtara las altas a nivel de entidad, sólo saca la pobalción
    group by 1,2) b -- fuente propia: initial PO
    on a.tip_doc = b.tip_doc and a.key_value = b.key_value 
    -- and codmes>='202305' --Se acuerdo con isma colocar el mes M-12 Ejem: para 202405 M-12 es 202305
    -- and codmes between '202305' and '202405'--Se acuerdo con isma colocar el mes M-12 Ejem: para 202405 M-12 es 202305 v2: se acomta már los meses a consultar, se coloca como sub consulta para optimizar
),
morigbk_saldo_hist_bank as (
with data_rcc_bank as ( 
    select codmes, tip_doc, key_value,
            sum(case when cast(tipo_credito as int) between 1 and 10   --and REGEXP_LIKE(COD_CUENTA_RCC, '^14.[13456]|^81.(925|302)')  
            then saldo else 0 end) as saldo_mo
    from (select distinct * from morigbk_rcc_bank) a 
    group by codmes, tip_doc, key_value--, tipo_credito, cod_instit_financiera
),
info_consolid_bank as (
    select distinct a.codmes, a.tip_doc, a.key_value,--, b.cod_instit_financiera, 
            -- Dias de mora en cada mes en los últimos 12 meses
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '0' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m0,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '1' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m1,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '2' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m2,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '3' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m3,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '4' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m4,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '5' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m5,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '6' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m6,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '7' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m7,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '8' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m8,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '9' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m9,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '10' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m10,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '11' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m11,
            sum(case when cast(b.codmes as int) = cast(date_format(date_parse(cast(a.codmes as varchar),'%Y%m') - interval '12' month,'%Y%m') as int) then saldo_mo else 0 end) as saldo_m12
    -- from (select codmes,tip_doc, key_value  from d_mdl_riesgos_disc.PO_PREVIA_AD_202305 where alta2=1 
    from (select codmes,tip_doc, key_value  from morigbk_altas where alta2=1 group by 1,2,3) a

    left join (select distinct * from data_rcc_bank) b
    on a.key_value=b.key_value and a.tip_doc=b.tip_doc
    group by a.codmes, a.tip_doc, a.key_value----, b.cod_instit_financiera
), 
-- Maximo saldo en el histórico
max_saldo_bank as (
    select a.*,
        greatest(saldo_m1,saldo_m2,saldo_m3,saldo_m4,saldo_m5,saldo_m6,saldo_m7,saldo_m8,saldo_m9,saldo_m10,saldo_m11,saldo_m12) as max_saldo---,saldo_m0
    from info_consolid_bank  a    --where cast(tipo_credito as int) between 8 and 10) a
)select * from max_saldo_bank)
, base_altas_cliente as (
select 
    a.*,
    b.cod_instit_financiera,
    c.nombre_instit_financiera, 
    RANK() OVER (PARTITION BY a.tip_doc, a.key_value ORDER BY c.cod_instit_financiera asc) AS rank
    -- a.codmes as p_codmes 
from    
    morigbk_saldo_hist_bank a 
left join 
    (select * from morigbk_altas where alta2 = 1) b on a.key_value=b.key_value and a.tip_doc=b.tip_doc --Se vuelve a consultar esta base para sacar la entidad financiera, no se hace antes por que se necesita agrupar sin entidad financiera
left join 
    e_perm_aws.t_dim_inst_fin_rsk c on c.cod_instit_financiera = b.cod_instit_financiera
where a.max_saldo>0  --max saldo de lo últimos 12 meses --filtro para ver que es bank
    and c.nombre_instit_financiera not in ('BANCO AGROPECUARIO' ,'BANCO DE LA NACION','BBVA CONSUMER FINANCE ENT. DESARROLLO PEQUEÑA Y MICROEMPRESA','CAJA RURAL DE AHORRO Y CREDITO SIPAN S A','LEASING TOTAL S A','VALOR NO ENVIADO POR IBK')
-- select count(1) from morigbk_saldo_hist_bank where max_saldo>0  --max saldo de lo últimos 12 meses --filtro para ver que es bank
-- select codmes,count(distinct concat(tip_doc,key_value)),sum(max_saldo) from morigbk_saldo_hist_bank where max_saldo>0 group by 1 --max saldo de lo últimos 12 meses --filtro para ver que es bank
)
select *, codmes as p_codmes from base_altas_cliente where rank =1

) t
;
