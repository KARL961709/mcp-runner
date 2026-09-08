-- Construye el ds cppibkren 202606 (CTAS del inference.sql) para probar/poblar data/202606/
CREATE TABLE disc_model_owner.ds_cppibkren_cal
WITH (format='PARQUET', external_location='s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/CPPIBKREN_CAL/data/202606/') AS
with wrk_dim_tiempo as (
  select 
  codmes, 
  year(calendar_date) anioactual,
  date_format(date_add('month', 0, calendar_date),'%Y%m') lcodmesM00,
  date_format(date_add('month', -1, calendar_date),'%Y%m') lcodmesM01,
  date_format(date_add('month', -2, calendar_date),'%Y%m') lcodmesM02,
  date_format(date_add('month', -3, calendar_date),'%Y%m') lcodmesM03, 
  date_format(date_add('month', -4, calendar_date),'%Y%m') lcodmesM04, 
  date_format(date_add('month', -5, calendar_date),'%Y%m') lcodmesM05, 
  date_format(date_add('month', -6, calendar_date),'%Y%m') lcodmesM06, 
  date_format(date_add('month', -7, calendar_date),'%Y%m') lcodmesM07, 
  date_format(date_add('month', -8, calendar_date),'%Y%m') lcodmesM08, 
  date_format(date_add('month', -09, calendar_date),'%Y%m') lcodmesM09, 
  date_format(date_add('month', -10, calendar_date),'%Y%m') lcodmesM10, 
  date_format(date_add('month', -11, calendar_date),'%Y%m') lcodmesM11, 
  date_format(date_add('month', -12, calendar_date),'%Y%m') lcodmesM12, 
  date_format(date_add('month', -13, calendar_date),'%Y%m') lcodmesM13, 
  date_format(date_add('month', -14, calendar_date),'%Y%m') lcodmesM14, 
  date_format(date_add('month', -24, calendar_date),'%Y%m') lcodmesM24,
  date_format(date_add('month', -25, calendar_date),'%Y%m') lcodmesM25,
  date_format(date_add('month', -32, calendar_date),'%Y%m') lcodmesM32, 
  date_format(date_add('month', -56, calendar_date),'%Y%m') lcodmesM56, 
  date_format(date_add('month', 1, calendar_date),'%Y%m') lcodmesM1,
  date_format(date_add('month', 1, calendar_date),'%Y%m%d') nfecdia01, 
  date_format(date_add('month', 0, calendar_date),'%Y%m%d') lfecdia00, 
  date_format(date_add('month', -1, calendar_date),'%Y%m%d') lfecdia01,
  date_format(date_add('month', -03, calendar_date),'%Y%m%d') lfecdia03,
  date_format(date_add('month', -04, calendar_date),'%Y%m%d') lfecdia04,
  date_format(date_add('month', -05, calendar_date),'%Y%m%d') lfecdia05,
  date_format(date_add('month', -12, calendar_date),'%Y%m%d') lfecdia12,
  cast(date_format(date_add('month', 0, calendar_date),'%Y%m') as integer) lcodmesm00_int,
  cast(date_format(date_add('month', -1, calendar_date),'%Y%m') as integer) lcodmesm01_int,
  cast(date_format(date_add('month', -12, calendar_date),'%Y%m') as integer) lcodmesm12_int  
  from( select date_format(date_parse(calendar_date,'%Y-%m-%d'),'%Y%m') codmes, 
  date_parse(calendar_date,'%Y-%m-%d') calendar_date,
  Row_Number() Over(PARTITION BY substr(calendar_date,1,7)
  ORDER BY calendar_date DESC) rnk
  from e_perm_aws.t_calendar_summary
  where calendar_date = date_format(date_parse('202606','%Y%m'),'%Y-%m-%d'))Y
  where y.rnk = 1
),  
wrk_base_bkp_cierre_mensual as (
   select 
   a.codmes,
   a.cuc,
   a.tip_doc,
   a.key_value,
   a.prod,
   a.subprod,
   a.clasif_ib,
   a.aplicativo,
   a.vig,
   a.dm,
   a.deuda_vig_sol,
   a.deuda_vig_dol,
   a.deuda_ven_sol,
   a.deuda_ven_dol,
   a.deuda_jud_sol,
   a.deuda_jud_dol,
   a.castigado,   
   a.p_codmes
   FROM e_perm_aws.t_rsk_bkp_cierre_mensual a
   inner join wrk_dim_tiempo t on 1=1
   where a.p_codmes between t.lcodmesM13 and t.lcodmesM01
),
wrk_base_po_rsk as (
  select 
  a.codmes,
  a.cuc as cod_cuc,
  a.tip_doc,
  a.key_value,
  date_parse(t.codmes || '01', '%Y%m%d') AS codmesdd
  from wrk_base_bkp_cierre_mensual a
  inner join wrk_dim_tiempo t on 1 = 1 
  where a.p_codmes = t.lcodmesM01
  and a.prod like '06%' and (a.subprod is null or a.subprod<>'Cre.Efec.GH')
  and a.aplicativo = 'HPC'
  group by 1,2,3,4,5 
),
wrk_tipo_cambio_rsk as ( 
   select 
   codmes, 
   cod_moneda_origen, 
   cod_moneda_destino, 
   tipocambio_dia, 
   tipocambio_prm 
   from (select date_format(a.fecha_cambio,'%Y%m') codmes, 
   a.cod_moneda_origen, 
   a.cod_moneda_destino, 
   round(a.tipo_cambio,4) tipocambio_dia, 
   round(a.tipo_cambio_prom,4) tipocambio_prm, 
   row_number() over(partition by date_format(a.fecha_cambio,'%Y%m') order by a.fecha_cambio desc) as rnk 
   from e_perm_aws.t_dim_tipo_cambio_rsk a   
   inner join wrk_dim_tiempo as t on 1=1   
   where substr(a.fecha_val,1,6) between t.lcodmesM14 and t.lcodmesM01 
   and a.cod_moneda_origen = 'USD' and a.cod_moneda_destino = 'PEN' and a.cod_tipo_cambio= '1002' 
   ) 
   where rnk =1 
), 
wrk_fem_all_rsk as ( 
   select  
   a.codmes, 
   a.cod_cuc,  
   a.iso_currency_cd, 
   a.cur_book_bal, 
   a.avg_book_bal, 
   a.common_coa_id, 
   cast(a.common_coa_id as varchar(50)) as common_coa_id_char, 
   a.p_codmes   
   from e_perm_aws.t_fem_all_instr_rsk a 
   inner join wrk_dim_tiempo as t on 1=1   
   where a.p_codmes between t.lcodmesM14 and t.lcodmesM02 
),
wrk_dim_jerarquia_productos as ( 
   select 
   a.producto_fnte_cd,
   a.nivel8_dsc,
   a.nivel1_dsc
   from e_perm_aws.t_dim_jerarquia_productos a
),
wrk_pasivos_rsk as ( 
   SELECT 
   fem.codmes, 
   fem.COD_CUC,   
   sum(case when fem.iso_currency_cd='USD' then fem.cur_book_bal * c.tipocambio_dia else fem.cur_book_bal end)filter(where d.nivel8_dsc = 'PASIVOS' ) as cur_book_bal_pasivos 
   from wrk_base_po_rsk po  
   inner join wrk_dim_tiempo as t on 1=1  
   inner join wrk_fem_all_rsk as fem on (fem.cod_cuc = po.cod_cuc and fem.p_codmes = t.lcodmesm02) 
   left join wrk_tipo_cambio_rsk as c on fem.codmes = c.codmes 
   left join wrk_dim_jerarquia_productos d on fem.common_coa_id_char  = d.producto_fnte_cd 
   where not (fem.avg_book_bal < 0 and d.nivel8_dsc = 'PASIVOS') 
   and d.nivel8_dsc in ('PASIVOS', 'ACTIVO') 
   group by 1,2 
),
wrk_pasivos_rsk_2 as ( 
   select 
   codmes,
   cod_cuc, 
   max(case when cur_book_bal_pasivos>100 then 1 else 0 end) flg_pasivos_ibk  
   from wrk_pasivos_rsk 
   group by 1,2
),
wrk_prepasivos_rsk as ( 
   select 
   b.codmes,   
   date_format(date_parse(b.codmes,'%Y%m'),'%Y%m%d') mes_formato, 
   b.cod_cuc,  
   sum(case when b.iso_currency_cd='USD' then b.avg_book_bal * c.tipocambio_dia else b.avg_book_bal end)filter(where d.nivel8_dsc = 'PASIVOS' ) AS AVG_BOOK_BAL_PASIVOS, 
   sum(case when b.iso_currency_cd='USD' then b.cur_book_bal * c.tipocambio_dia else b.cur_book_bal end)filter(where d.nivel8_dsc = 'PASIVOS' ) AS CUR_BOOK_BAL_PASIVOS, 
   sum(avg_book_bal)filter(where nivel8_dsc = 'ACTIVO') as avg_book_bal_activos, 
   sum(case when b.iso_currency_cd='USD' then b.avg_book_bal * c.tipocambio_dia else b.avg_book_bal end)filter(where d.nivel1_dsc = 'CUENTA SUELDO') AS AVG_BOOK_BAL_CUENTA_SUELDO 
   from wrk_base_po_rsk a  
   inner join wrk_dim_tiempo as t on 1 = 1 
   inner join wrk_fem_all_rsk b on b.cod_cuc = a.cod_cuc   
   left join wrk_tipo_cambio_rsk c on b.codmes = c.codmes 
   left join wrk_dim_jerarquia_productos d on cast(b.common_coa_id as varchar(50)) = d.producto_fnte_cd  
   where b.p_codmes between  t.lcodmesM14 and t.lcodmesM02 
   and not (b.avg_book_bal < 0 and d.nivel8_dsc = 'PASIVOS') 
   and d.nivel8_dsc in ('PASIVOS', 'ACTIVO') 
   group by 1,2,3 
), 
wrk_pasivos2_rsk as ( 
   select 
   a.codmes, 
   a.cod_cuc,   
   min(case when (b.codmes between t.lcodmesM14 and t.lcodmesM03) then b.avg_book_bal_cuenta_sueldo  else null end) as min_pas_ctsld_12m, 
   avg(case when (b.codmes between t.lcodmesM05 and t.lcodmesM03) and b.avg_book_bal_pasivos is null then null 
            when (b.codmes between t.lcodmesM05 and t.lcodmesM03) and (coalesce(b.avg_book_bal_pasivos,0) > 1 and coalesce(b.avg_book_bal_activos,0) > 1) 
       then (1.0*b.avg_book_bal_activos)/(1.0*b.avg_book_bal_pasivos) else null end ) as ratio_act_pas_tot_3m
   from wrk_prepasivos_rsk a 
   inner join wrk_dim_tiempo as t on 1=1 
   left join wrk_prepasivos_rsk as b on a.cod_cuc = b.cod_cuc  
   where a.codmes = t.lcodmesM02 
   group by 1,2 
),
wrk_base_bkp_compp_rsk as ( 
   select 
   a.codmes, 
   a.cuc as cod_cuc, 
   max(case when a.prod='06 Cred efectivo' or (a.prod='08 Refinanciados' and a.subprod ='06 Cred efectivo')  
   then a.clasif_ib else null end) clsf_bkp_ibk, 
   max(a.deuda_vig_sol) deuda_vig_sol, 
   max(a.deuda_vig_dol) deuda_vig_dol, 
   max(a.deuda_ven_sol) deuda_ven_sol, 
   max(a.deuda_ven_dol) deuda_ven_dol, 
   max(a.deuda_jud_sol) deuda_jud_sol, 
   max(a.deuda_jud_dol) deuda_jud_dol, 
   max(a.castigado) castigado, 
   max(case when a.prod='06 Cred efectivo' then a.dm else null end) dm_pp_ibk 
   from wrk_base_po_rsk as b 
   inner join wrk_dim_tiempo t on 1 = 1  
   inner join wrk_base_bkp_cierre_mensual a on a.cuc = b.cod_cuc   
   where a.p_codmes between t.lcodmesM11 and t.lcodmesM01 
   and a.prod='06 Cred efectivo' or (a.prod='08 Refinanciados' and a.subprod ='06 Cred efectivo') 
   group by 1,2 
 ), 
wrk_vars_clasifibk_rsk  as ( 
   select 
   a.codmes, 
   a.cod_cuc, 
   max(case when b.codmes between t.lcodmesM05 and t.lcodmesM01 then cast(b.clsf_bkp_ibk as decimal(10,3)) else 0 end) max_clfibk06m 
   from wrk_base_bkp_compp_rsk a  
   inner join wrk_dim_tiempo t on 1 = 1  
   left join wrk_base_bkp_compp_rsk b on a.cod_cuc=b.cod_cuc and b.codmes between t.lcodmesM05 and t.lcodmesM01 
   where a.codmes= t.lcodmesM01  
   group by 1,2 
 ),
wrk_var_mora0_rsk as ( 
   select 
   a.codmes, 
   a.cod_cuc, 
   max(a.dm_pp_ibk) dm_pp_ibk 
   from wrk_base_bkp_compp_rsk a 
   inner join wrk_dim_tiempo t on 1 = 1  
   group by 1,2 
), 
wrk_var_mora_rsk as ( 
   select 
   a.codmes, 
   a.cod_cuc, 
   avg(case when b.codmes between t.lcodmesM11 and  t.lcodmesM01 then cast(b.dm_pp_ibk as decimal(10,3)) end )prm_diamoraptmult12m 
   from wrk_var_mora0_rsk a  
   inner join wrk_dim_tiempo t on 1 = 1  
   left join wrk_var_mora0_rsk b on a.cod_cuc=b.cod_cuc  
   and b.codmes between t.lcodmesM11 and t.lcodmesM01 
   where a.codmes = t.lcodmesM01 
   group by 1,2 
), 
wrk_vars_mdl_rcc_sldo as ( 
   select 
   a.coddoc,
   a.tipdoc,
   a.beta_entidades_dist_rd_u6m,
   a.beta_saldo_p_u1a,
   a.beta_entidades_dist_rd_u1a,
   a.desv_datraso_rd_u1a,
   a.avg_pct_uso_tctot_u1a,
   a.p_codmes
   from e_perm_aws.t_rsk_vars_mdl_rcc_sldo a
   inner join wrk_dim_tiempo t on 1 = 1 
   where a.p_codmes = t.lcodmesm00
 ), 
wrk_vars_rcc_sldo as ( 
   select   
   a.codmes, 
   a.tip_doc, 
   a.key_value, 
   case when ee.beta_entidades_dist_rd_u6m <0 then 0 else cast(ee.beta_entidades_dist_rd_u6m as decimal(18,3)) end ctd_entsldrsg06m, 
   case when b.meses_desde_peor_normal_u1a = 0 then null else cast(b.meses_desde_peor_normal_u1a as decimal(18,3)) end ctd_mespeornor12m 
   from wrk_base_po_rsk a   
   inner join wrk_dim_tiempo t on 1 = 1  
   left join wrk_vars_mdl_rcc_sldo ee on a.key_value=ee.coddoc and a.tip_doc=ee.tipdoc 
   inner join e_perm_aws.t_rsk_vars_mdl_rcc_prdsitu b on a.key_value=b.coddoc and a.tip_doc=b.tipdoc   
   where ee.p_codmes=t.lcodmesM00 and b.p_codmes=t.lcodmesM00 
),
wrk_pasivos_vista_rsk as ( 
   select 
   a.codmes, 
   a.cod_cuc,  
   max(case when a.iso_currency_cd='USD' and  a.cur_book_bal>=0 
   then a.cur_book_bal*b.tipocambio_dia else a.cur_book_bal end) cur_book_bal_pasivos 
   from wrk_fem_all_rsk a 
   inner join wrk_dim_tiempo as t on 1=1  
   left join wrk_tipo_cambio_rsk b on a.codmes = b.codmes 
   left join wrk_dim_jerarquia_productos c on a.common_coa_id_char = c.producto_fnte_cd 
   where a.codmes between t.lcodmesM04 and t.lcodmesM02 
   and not (a.cur_book_bal <0 and c.nivel8_dsc = 'PASIVOS') 
   and c.nivel8_dsc IN ('PASIVOS') 
   and a.common_coa_id not in (701010999,701011199) 
   group by 1,2 
 ), 
wrk_saldo_pp_rsk as ( 
   select 
   codmes,
   cod_cuc,
   sum(saldo_vig+saldo_ven+saldo_jud+castigado) saldo_pp_ibk 
   from (select date_format(date_parse(a.codmes,'%Y%m') - interval '1' month,'%Y%m') as codmes, 
   a.cod_cuc,  
   a.deuda_vig_sol + a.deuda_vig_dol*b.tipocambio_prm saldo_vig, 
   a.deuda_ven_sol + a.deuda_ven_dol*b.tipocambio_prm saldo_ven, 
   a.deuda_jud_sol + a.deuda_jud_sol*b.tipocambio_prm saldo_jud, 
   a.castigado*b.tipocambio_prm castigado 
   from wrk_base_bkp_compp_rsk a 
   inner join wrk_dim_tiempo t on 1 = 1  
   left join wrk_tipo_cambio_rsk b on a.codmes=b.codmes 
   where a.codmes between t.lcodmesM03 and t.lcodmesM01 
   ) group by 1, 2 
), 
wrk_pp_pasivos_rsk as ( 
   select 
   a.codmes, 
   a.cod_cuc, 
   b.saldo_pp_ibk, 
   a.cur_book_bal_pasivos 
   from wrk_pasivos_vista_rsk a 
   left join wrk_saldo_pp_rsk b on a.cod_cuc=b.cod_cuc and a.codmes=b.codmes 
   group by a.codmes,a.cod_cuc,b.saldo_pp_ibk,a.cur_book_bal_pasivos 
), 
wrk_vars_saldo_pp_rat_rsk as ( 
   select 
   a.codmes,
   a.cod_cuc, 
   cast(max(case when b.codmes between t.lcodmesM04 and t.lcodmesM02  and b.cur_book_bal_pasivos<>0 then b.saldo_pp_ibk/b.cur_book_bal_pasivos else null end) as decimal(18,3)) max_rtosldppibk03m 
   from wrk_pp_pasivos_rsk a  
   inner join wrk_dim_tiempo as t on 1=1  
   left join wrk_pp_pasivos_rsk b on a.cod_cuc=b.cod_cuc 
   and b.codmes between t.lcodmesM04 and t.lcodmesM02  
   where a.codmes=t.lcodmesM02 
   group by 1,2 
), 
wrk_saldo_pp_rat_rsk as ( 
   select 
   codmes,
   cod_cuc, 
   case when max_rtosldppibk03m> 2000 then 2000 else max_rtosldppibk03m end max_rtosldppibk03m 
   from wrk_vars_saldo_pp_rat_rsk 
),   
wrk_vars_compp_rsk as ( 
   select 
   a.codmes, 
   a.cod_cuc, 
   a.tip_doc, 
   b.flg_pasivos_ibk,
   f.min_pas_ctsld_12m, 
   f.ratio_act_pas_tot_3m, 
   k.max_clfibk06m, 
   m.prm_diamoraptmult12m, 
   n.ctd_entsldrsg06m,  
   n.ctd_mespeornor12m, 
   q.max_rtosldppibk03m   
   from wrk_base_po_rsk a  
   inner join wrk_dim_tiempo t on 1=1 
   left join wrk_pasivos_rsk_2 b on a.cod_cuc=b.cod_cuc 
   left join wrk_pasivos2_rsk f on a.cod_cuc=f.cod_cuc  
   left join wrk_vars_clasifibk_rsk k on a.codmes=k.codmes and a.cod_cuc=k.cod_cuc 
   left join wrk_var_mora_rsk m on a.codmes=m.codmes and a.cod_cuc=m.cod_cuc 
   left join wrk_vars_rcc_sldo n on a.key_value=n.key_value and a.tip_doc=n.tip_doc 
   left join wrk_saldo_pp_rat_rsk q on a.cod_cuc=q.cod_cuc  
),
wrk_base_dependiente_rsk as ( 
   select 
   a.codmes,
   a.tip_doc,
   a.key_value, 
   case when a.flag_dependiente = 'DEPENDIENTE'then 1 else 0 end as flag_dependiente  
   from e_perm_aws.t_agg_dependiente_hist_rsk a 
   inner join wrk_dim_tiempo as t on 1=1  
   where a.p_codmes= t.lcodmesM01 and a.flag_dependiente <> '' 
   group by 1,2,3,4
),  
wrk_mst_reniec_rsk as (  
   select  
   t.lcodmesm00 as codmes, 
   a.tip_doc,  
   a.key_value,	 
   substr(to_char(a.fec_nacimiento,'yyyymmdd'),1,6) periodo_nac,
   case when substr(to_char(a.fec_nacimiento,'yyyymmdd'),1,6) is not null then cast((cast(t.lcodmesm00_int/100 AS INT)*12+t.lcodmesm00_int%100 - (cast(cast(substr(to_char(a.fec_nacimiento,'yyyymmdd'),1,6) as int)/100 as int)*12+cast(substr(to_char(a.fec_nacimiento,'yyyymmdd'),1,6) as int)%100))*1.0/12 as int) else null end edad 
   from e_perm_aws.t_mst_reniec_rsk  a 
   INNER JOIN wrk_dim_tiempo AS t ON 1=1 
),
wrk_base_sunarp AS (
  SELECT
  tip_doc,
  key_value,
  placa,
  carroceria,
  asientos,
  codmesbase,
  MAX(codmesbase) OVER () AS max_codmesbase
  FROM e_perm_aws.t_mst_sunarp_rsk
),
wrk_vehiculos AS (
  SELECT
  tip_doc,
  key_value,
  COUNT(DISTINCT placa) AS nro_vehiculos,
  SUM(CASE WHEN (carroceria IN ('SEMIREMOLQUE', 'MICROBUS', 'CAMION', 'OMNIBUS', 'TRACTO CAMION/REMOLCADOR', 'REMOLQUE', 'REMOLCADOR', 'EQUIPOS Y MAQUINARIA') OR (carroceria = 'S/C' AND asientos > 8)) THEN 1 ELSE 0 END) AS vehiculo_pesado
  FROM wrk_base_sunarp
  WHERE codmesbase = max_codmesbase
  GROUP BY 1,2
),
wrk_base_datraso_median_rsk AS ( 
   select 
   a.codmes, 
   a.tip_doc, 
   a.key_value, 
   a.mdn_sld_sa_hip_3i_6m,
   a.sbs_value,
   a.mdn_dec_sld_tarj_3i_6m,
   a.p_codmes  
   from e_perm_aws.ds_iinc_flg_datraso_median_rsk a 
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes = t.lcodmesm00
),
wrk_iinc_datraso_rsk AS ( 
   select 
   a.codmes, 
   a.tip_doc, 
   a.key_value, 
   max(mdn_sld_sa_hip_3i_6m) as mdn_sld_sa_hip_3i_6m 
   from wrk_base_datraso_median_rsk a
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes = t.lcodmesm00 and tip_doc='1' 
   group by 1,2,3
),
wrk_feature_infingnc_rsk as ( 
   select  
   po.codmes, 
   po.tip_doc,
   po.key_value, 
   b.mdn_sld_sa_hip_3i_6m, 
   d.prm_ratdispefpnj_u1a, 
   d.ctd_dectctotal_12m, 
   d.ratio_comparacion_u1m_u12m, 
   d.ratio_saldo_rt_t1_t12, 
   d.prm_pct_sld_rd_6m, 
   f.rat_miemsup2r 
   from wrk_base_po_rsk po 
   inner join wrk_dim_tiempo t on 1 = 1 
   left join wrk_iinc_datraso_rsk b on po.tip_doc = b.tip_doc and po.key_value = b.key_value 
   left join e_perm_aws.ds_iinc_tcbk_tcnobk_pp_rsk d on po.tip_doc = d.tip_doc and po.key_value = d.key_value and d.p_codmes = t.lcodmesm00  
   left join e_perm_aws.ds_iinc_sociodemograf_rsk f  on po.tip_doc = f.tip_doc and po.key_value = f.key_value and f.p_codmes = t.lcodmesm00  
),
wrk_pre_base_inicial_rsk as (  
   select 
   a.codmes, 
   a.tip_doc,
   a.cod_cuc, 
   a.key_value, 
   a.sbs_value, 
   a.antig_profesional,  
   a.nro_titulo_prof,  
   a.num_inmuebles,   
   a.mnt_totalrec06m,    
   a.prm_trxtot12m,  
   Row_Number() over(partition by a.key_value order by a.cod_cuc desc) rnk 
   from e_perm_aws.ds_cls_inginfibk_rsk a  
   inner join wrk_dim_tiempo t on a.p_codmes = t.codmes  
),  
wrk_base_inicial_rsk as (  
   select 
   a.codmes, 
   a.tip_doc,
   a.cod_cuc, 
   a.key_value, 
   a.sbs_value, 
   a.antig_profesional,  
   a.nro_titulo_prof,  
   a.num_inmuebles,  
   a.mnt_totalrec06m,  
   a.prm_trxtot12m   
   from wrk_pre_base_inicial_rsk a 
   where rnk=1 
), 
wrk_base_fact_report_rcc_rsk as (  
   select 
   a.codmes,  
   a.tip_doc, 
   a.key_value, 
   a.sbs_value,
   a.saldo,
   a.cod_instit_financiera,
   a.tipo_credito,
   a.cod_cuenta_rcc,
   a.condicion,
   a.cod_clasificacion_deudor,
   a.p_codmes   
   from e_perm_aws.t_fact_report_rcc_rsk a  
   inner join wrk_dim_tiempo t on 1=1
   where a.p_codmes between t.lcodmesm24 and t.lcodmesm02 
), 
wrk_base_mst_ctarcc_rsk as (  
   select 
   a.sbs_value,  
   a.tip_doc, 
   a.key_value, 
   a.tip_persona  
   from e_perm_aws.t_mst_ctarcc_rsk a   
),  
wrk_pre_rcc_7_rsk as (  
   select 
   t.codmes, 
   a.codmes as codmes_rcc,  
   b.tip_doc, 
   b.key_value,  
   sum(saldo) as sldtot  
   from wrk_base_fact_report_rcc_rsk a   
   inner join wrk_dim_tiempo t on a.p_codmes between t.lcodmesm14 and t.lcodmesm02  
   inner join wrk_base_mst_ctarcc_rsk b on a.sbs_value = b.sbs_value and b.tip_persona = '1'  
   inner join wrk_base_inicial_rsk c on a.key_value=c.key_value and a.tip_doc=c.tip_doc 
   where cod_cuenta_rcc like '14_1%' or cod_cuenta_rcc like '14_3%' or cod_cuenta_rcc like '14_4%' or cod_cuenta_rcc like '14_5%' or cod_cuenta_rcc like '14_6%'  
   group by 1,2,3,4  
),  
wrk_pre_rcc_8_rsk as (  
   select 
   tip_doc, 
   key_value,  
   sum(case when a.codmes_rcc = t.lcodmesm02 then a.sldtot end) as msaltot01,  
   sum(case when a.codmes_rcc = t.lcodmesm03 then a.sldtot end) as msaltot02,  
   sum(case when a.codmes_rcc = t.lcodmesm04 then a.sldtot end) as msaltot03,  
   sum(case when a.codmes_rcc = t.lcodmesm05 then a.sldtot end) as msaltot04,  
   sum(case when a.codmes_rcc = t.lcodmesm06 then a.sldtot end) as msaltot05,  
   sum(case when a.codmes_rcc = t.lcodmesm07 then a.sldtot end) as msaltot06,  
   sum(case when a.codmes_rcc = t.lcodmesm08 then a.sldtot end) as msaltot07,  
   sum(case when a.codmes_rcc = t.lcodmesm09 then a.sldtot end) as msaltot08,  
   sum(case when a.codmes_rcc = t.lcodmesm10 then a.sldtot end) as msaltot09,  
   sum(case when a.codmes_rcc = t.lcodmesm11 then a.sldtot end) as msaltot10,  
   sum(case when a.codmes_rcc = t.lcodmesm12 then a.sldtot end) as msaltot11,  
   sum(case when a.codmes_rcc = t.lcodmesm13 then a.sldtot end) as msaltot12,  
   sum(case when a.codmes_rcc = t.lcodmesm14 then a.sldtot end) as msaltot13  
   from wrk_pre_rcc_7_rsk a  
   inner join wrk_dim_tiempo t on 1=1  
   group by 1, 2  
),  
wrk_pre_rcc_9_rsk as (  
   select 
   tip_doc, 
   key_value,  
   case when coalesce(msaltot01,0) - coalesce(msaltot02,0) < 0 then -(coalesce(msaltot01,0) - coalesce(msaltot02,0)) else null end as decre_sal_m01,  
   case when coalesce(msaltot02,0) - coalesce(msaltot03,0) < 0 then -(coalesce(msaltot02,0) - coalesce(msaltot03,0)) else null end as decre_sal_m02,  
   case when coalesce(msaltot03,0) - coalesce(msaltot04,0) < 0 then -(coalesce(msaltot03,0) - coalesce(msaltot04,0)) else null end as decre_sal_m03,  
   case when coalesce(msaltot04,0) - coalesce(msaltot05,0) < 0 then -(coalesce(msaltot04,0) - coalesce(msaltot05,0)) else null end as decre_sal_m04,  
   case when coalesce(msaltot05,0) - coalesce(msaltot06,0) < 0 then -(coalesce(msaltot05,0) - coalesce(msaltot06,0)) else null end as decre_sal_m05,  
   case when coalesce(msaltot06,0) - coalesce(msaltot07,0) < 0 then -(coalesce(msaltot06,0) - coalesce(msaltot07,0)) else null end as decre_sal_m06,  
   case when coalesce(msaltot07,0) - coalesce(msaltot08,0) < 0 then -(coalesce(msaltot07,0) - coalesce(msaltot08,0)) else null end as decre_sal_m07,  
   case when coalesce(msaltot08,0) - coalesce(msaltot09,0) < 0 then -(coalesce(msaltot08,0) - coalesce(msaltot09,0)) else null end as decre_sal_m08,  
   case when coalesce(msaltot09,0) - coalesce(msaltot10,0) < 0 then -(coalesce(msaltot09,0) - coalesce(msaltot10,0)) else null end as decre_sal_m09,  
   case when coalesce(msaltot10,0) - coalesce(msaltot11,0) < 0 then -(coalesce(msaltot10,0) - coalesce(msaltot11,0)) else null end as decre_sal_m10,  
   case when coalesce(msaltot11,0) - coalesce(msaltot12,0) < 0 then -(coalesce(msaltot11,0) - coalesce(msaltot12,0)) else null end as decre_sal_m11,  
   case when coalesce(msaltot12,0) - coalesce(msaltot13,0) < 0 then -(coalesce(msaltot12,0) - coalesce(msaltot13,0)) else null end as decre_sal_m12  
   from wrk_pre_rcc_8_rsk  
),  
wrk_pre_rcc_10_rsk as (  
   select 
   tip_doc, 
   key_value,  
   case when cuenta_decre_12m >=1 then least(  
   coalesce(decre_sal_m01,9999999999999999),  
   coalesce(decre_sal_m02,9999999999999999),  
   coalesce(decre_sal_m03,9999999999999999),  
   coalesce(decre_sal_m04,9999999999999999),  
   coalesce(decre_sal_m05,9999999999999999),  
   coalesce(decre_sal_m06,9999999999999999),  
   coalesce(decre_sal_m07,9999999999999999),  
   coalesce(decre_sal_m08,9999999999999999),  
   coalesce(decre_sal_m09,9999999999999999),  
   coalesce(decre_sal_m10,9999999999999999),  
   coalesce(decre_sal_m11,9999999999999999),  
   coalesce(decre_sal_m12,9999999999999999)  
   ) end as min_decrem_12m,  
   case when cuenta_decre_12m >=1 then greatest(  
   coalesce(decre_sal_m01,-9999999999999999),  
   coalesce(decre_sal_m02,-9999999999999999),  
   coalesce(decre_sal_m03,-9999999999999999),  
   coalesce(decre_sal_m04,-9999999999999999),  
   coalesce(decre_sal_m05,-9999999999999999),  
   coalesce(decre_sal_m06,-9999999999999999),  
   coalesce(decre_sal_m07,-9999999999999999),  
   coalesce(decre_sal_m08,-9999999999999999),  
   coalesce(decre_sal_m09,-9999999999999999),  
   coalesce(decre_sal_m10,-9999999999999999),  
   coalesce(decre_sal_m11,-9999999999999999),  
   coalesce(decre_sal_m12,-9999999999999999)  
   ) end as max_decrem_12m, tot_decre_sal_m12, cuenta_decre_12m   
   from (  
   select tip_doc, key_value,  
   decre_sal_m01, decre_sal_m02, decre_sal_m03, decre_sal_m04, decre_sal_m05, decre_sal_m06,  
   decre_sal_m07, decre_sal_m08, decre_sal_m09, decre_sal_m10, decre_sal_m11, decre_sal_m12,  
   (coalesce(decre_sal_m01,0) + coalesce(decre_sal_m02,0) + coalesce(decre_sal_m03,0) + coalesce(decre_sal_m04,0) + coalesce(decre_sal_m05,0) + coalesce(decre_sal_m06,0) +  
   coalesce(decre_sal_m07,0) + coalesce(decre_sal_m08,0) + coalesce(decre_sal_m09,0) + coalesce(decre_sal_m10,0) + coalesce(decre_sal_m11,0) + coalesce(decre_sal_m12,0)) as tot_decre_sal_m12,  
   case when (  
   case when decre_sal_m01 > 0 then 1 else 0 end +  
   case when decre_sal_m02 > 0 then 1 else 0 end +  
   case when decre_sal_m03 > 0 then 1 else 0 end +  
   case when decre_sal_m04 > 0 then 1 else 0 end +  
   case when decre_sal_m05 > 0 then 1 else 0 end +  
   case when decre_sal_m06 > 0 then 1 else 0 end +  
   case when decre_sal_m07 > 0 then 1 else 0 end +  
   case when decre_sal_m08 > 0 then 1 else 0 end +  
   case when decre_sal_m09 > 0 then 1 else 0 end +  
   case when decre_sal_m10 > 0 then 1 else 0 end +  
   case when decre_sal_m11 > 0 then 1 else 0 end +  
   case when decre_sal_m12 > 0 then 1 else 0 end  
   ) = 0 then 0 
   else  
   (case when decre_sal_m01 > 0 then 1 else 0 end +  
   case when decre_sal_m02 > 0 then 1 else 0 end +  
   case when decre_sal_m03 > 0 then 1 else 0 end +  
   case when decre_sal_m04 > 0 then 1 else 0 end +  
   case when decre_sal_m05 > 0 then 1 else 0 end +  
   case when decre_sal_m06 > 0 then 1 else 0 end +  
   case when decre_sal_m07 > 0 then 1 else 0 end +  
   case when decre_sal_m08 > 0 then 1 else 0 end +  
   case when decre_sal_m09 > 0 then 1 else 0 end +  
   case when decre_sal_m10 > 0 then 1 else 0 end +  
   case when decre_sal_m11 > 0 then 1 else 0 end +  
   case when decre_sal_m12 > 0 then 1 else 0 end  
   )  
   end as cuenta_decre_12m  
   from wrk_pre_rcc_9_rsk  
   )  
),
wrk_rcc_3_rsk as (  
   select 
   tip_doc, 
   key_value,  
   case when cuenta_decre_12m >= 3 then cast((coalesce(tot_decre_sal_m12,0)-coalesce(min_decrem_12m,0)-coalesce(max_decrem_12m,0))/nullif((cuenta_decre_12m-2),0) as decimal(18,6))  
        else 0 end as prm_decrsld12m, 
   cast(cuenta_decre_12m as integer) as nro_decrsld12m  
   from wrk_pre_rcc_10_rsk  
),  
wrk_rat_sldo_rcc as (  
   select 
   a.coddoc, 
   a.tipdoc, 
   a.ratio_saldo_pp_u1m_tc_ibk 
   from e_perm_aws.t_rsk_vars_mdl_rcc_ratsldo a  
   inner join wrk_dim_tiempo t on a.p_codmes = t.lcodmesm00  
   inner join wrk_base_inicial_rsk c on a.coddoc=c.key_value and a.tipdoc=c.tip_doc 
),
wrk_mst_profesiones_rsk as (  
 	select 
	t.codmes, 
	a.key_value,   
 	min(cast(date_parse(a.fecfin, '%Y-%m-%d') as date)) fecdiploma ,  
 	cast(count(a.fecfin) as integer) nro_titulo_prof  
 	from e_perm_aws.t_maestra_profesiones a  
 	inner join wrk_dim_tiempo as t on 1=1  
 	where trim(a.fecfin) not in ('')   
 	and substr(replace(a.fecfin,'-',''),1,6) < t.codmes  
 	group by 1,2  
),
wrk_rcc_sldo as (  
 	SELECT 
	coddoc as key_value,  
 	tipdoc as tip_doc,  
 	cast(beta_saldo_p_u1a as decimal(18,6)) as beta_saldo_p_u1a,  
 	cast(beta_entidades_dist_rd_u1a as decimal(18,6)) as beta_entidades_dist_rd_u1a
 	FROM wrk_vars_mdl_rcc_sldo a
 	inner join wrk_dim_tiempo as t on 1=1  
 	WHERE a.p_codmes=t.lcodmesm00 and a.tipdoc='1'  
),   
wrk_saldos_rsk as (  
 	SELECT 
	cod_cuc,   
 	nro_incsldtippas12m
 	FROM e_perm_aws.t_saldosibk_rsk a  
 	inner join wrk_dim_tiempo as t on 1=1  
 	WHERE a.p_codmes=t.lcodmesm02   
),
wrk_sentinel1_rsk as (  
   SELECT   
   key_value,  
   tip_doc,   
   prm_ddatelc12m,   
   mnt_ddaotremp12m  
   FROM e_perm_aws.t_sentinel_rsk a  
   inner join wrk_dim_tiempo as t on 1=1  
   WHERE a.p_codmes=t.lcodmesm01 and a.tip_doc='1'  
),   
wrk_flg_datraso_rsk as (  
   SELECT   
   key_value,  
   tip_doc,  
   sbs_value,  
   mdn_dec_sld_tarj_3i_6m  
   FROM wrk_base_datraso_median_rsk a  
   inner join wrk_dim_tiempo as t on 1=1  
   WHERE a.p_codmes=t.lcodmesm00 and a.tip_doc='1'  
),  
wrk_feature_visioncliente_rsk as (  
   select   
   p.codmes,  
   p.tip_doc,  
   p.key_value,
   p.cod_cuc,   
   c.prm_ddatelc12m,  
   d.beta_saldo_p_u1a,   
   try_cast(g.mdn_dec_sld_tarj_3i_6m  AS decimal(18,3)) as mdn_dec_sld_tarj_3i_6m,  
   d.beta_entidades_dist_rd_u1a,  
   c.mnt_ddaotremp12m,  
   m.nro_incsldtippas12m,
   row_number()over(partition by p.codmes, p.tip_doc, p.key_value order by p.tip_doc asc) as id    
   FROM wrk_base_po_rsk p  
   inner join wrk_dim_tiempo as t on 1=1        
   LEFT JOIN wrk_mst_profesiones_rsk b3 ON p.codmes = b3.codmes and p.key_value=b3.key_value   	  
   left join wrk_sentinel1_rsk c on p.key_value=c.key_value and p.tip_doc = c.tip_doc    
   LEFT JOIN wrk_rcc_sldo d ON p.tip_doc = d.tip_doc AND p.key_value = d.key_value   
   LEFT JOIN wrk_flg_datraso_rsk  g ON p.tip_doc = g.tip_doc AND p.key_value = g.key_value 
   LEFT JOIN wrk_saldos_rsk m ON p.cod_cuc = m.cod_cuc       
),  
wrk_feature_viscliest_rsk as (   
   select  
   a.codmes,  
   a.tip_doc,  
   a.key_value,  
   a.cod_cuc,   
   a.beta_saldo_p_u1a,  
   a.prm_ddatelc12m,   
   a.beta_entidades_dist_rd_u1a,  
   a.mnt_ddaotremp12m,  
   a.mdn_dec_sld_tarj_3i_6m,  
   a.nro_incsldtippas12m   
   from wrk_feature_visioncliente_rsk a  
   where id=1  
),
wrk_base_mst_ctaibk_rsk as ( 
   select  
   a.key_value, 
   a.tip_doc, 
   a.cod_cuc, 
   a.fch_priprd,
   a.fch_pricont
   from e_perm_aws.t_mst_ctaibk_rsk a
),
wrk_mst_ctaibk_rsk AS ( 
   SELECT  
   U.key_value, 
   U.tip_doc, 
   U.cod_cuc, 
   U.antig_primer_producto
   FROM ( 
   SELECT  
   a.key_value, 
   a.tip_doc, 
   a.cod_cuc, 
   CASE WHEN a.fch_priprd IS NOT NULL AND DATE_DIFF('month', DATE_PARSE(CAST(a.fch_priprd AS VARCHAR(10)), '%Y-%m-%d'), DATE_PARSE(CAST(b.lcodmesm00 AS VARCHAR(10)), '%Y%m')) >= 0  
        THEN DATE_DIFF('month', DATE_PARSE(CAST(a.fch_priprd AS VARCHAR(10)), '%Y-%m-%d'), DATE_PARSE(CAST(b.lcodmesm00 AS VARCHAR(10)), '%Y%m')) ELSE NULL 
   END AS antig_primer_producto, 
   ROW_NUMBER() OVER(PARTITION BY tip_doc, key_value ORDER BY cod_cuc DESC) row_num 
   FROM wrk_base_mst_ctaibk_rsk a
   inner join wrk_dim_tiempo b on 1 = 1 
   ) U 
   WHERE row_num = 1 and tip_doc = '1' 
),		 
wrk_feature_rcc_sldo_rsk as ( 
   select  
   tipdoc as tip_doc, 
   coddoc as key_value, 
   cast(desv_datraso_rd_u1a as decimal(18,6)) as desv_datraso_rd_u1a, 
   cast(avg_pct_uso_tctot_u1a as decimal(32,6)) as prm_pctusotctot_u1a
   from wrk_vars_mdl_rcc_sldo a  
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes = t.lcodmesm00 
),
wrk_feature_mdl_rcc_disef_rsk AS ( 
   SELECT   
   tipdoc as tip_doc, 
   coddoc as key_value, 
   cast(avg_saldo_disp_ef_pn_u6m as decimal(23,3)) as prm_slddispefpn_u6m 
   FROM e_perm_aws.t_rsk_vars_mdl_rcc_disef a 
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes = t.lcodmesm00 
), 
wrk_feature_rcc_decrsldo_rsk AS ( 
   SELECT   
   tipdoc as tip_doc, 
   coddoc as key_value, 
   cuenta_decre_12m_correg as cta_deccorreg_12m
   FROM e_perm_aws.t_rsk_vars_mdl_rcc_decrsldo a 
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes = t.lcodmesm00 
), 
wrk_feature_rcc_agg01_rsk as ( 
   SELECT  
   key_value, 
   trim(tip_doc) AS tip_doc, 
   rat_svotrppeallsfm03 as rat_svotrppeallsf_3m 
   FROM e_perm_aws.tbl_rcc_agg01_allsf_mdl as a 
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes = t.lcodmesm01 
), 
wrk_feature_gestion_rsk as ( 
   SELECT 
   m.key_value, 
   m.tip_doc, 
   f.cant_gestiones_m6 as ctd_gestiones_6m 
   FROM e_perm_aws.t_cob_feature_gestion f 
   inner join wrk_mst_ctaibk_rsk m on f.cu=m.cod_cuc 
   inner join wrk_dim_tiempo t on 1=1 
   where f.p_codmes = t.lcodmesm01 
),
wrk_base_rcc as ( 
   select 
   a.codmes as codmes_rcc, 
   a.tip_doc, 
   a.key_value,
   a.sbs_value, 
   cod_instit_financiera as codempresa, 
   tipo_credito, 
   cod_cuenta_rcc,
   saldo, 
   condicion, 
   cod_clasificacion_deudor, 
  (CASE WHEN(SUBSTR(cod_cuenta_rcc, 1, 10) IN ( 
   '1411030603', 
   '1414030603', 
   '1415030603', 
   '1416030603', 
   '1411031906', 
   '1414031906', 
   '1415031906', 
   '1416031906', 
   '1421030603', 
   '1424030603', 
   '1425030603', 
   '1426030603', 
   '1421031906', 
   '1424031906', 
   '1425031906', 
   '1426031906', 
   '1431030603', 
   '1434030603', 
   '1435030603', 
   '1436030603', 
   '1431031906', 
   '1434031906', 
   '1435031906', 
   '1436031906', 
   '1411030614', 
   '1414030614', 
   '1415030614', 
   '1416030614', 
   '1411030615', 
   '1414030615', 
   '1415030615', 
   '1416030615', 
   '1421030614', 
   '1424030614', 
   '1425030614', 
   '1426030614', 
   '1421030615', 
   '1424030615', 
   '1425030615', 
   '1426030615', 
   '1431030614', 
   '1434030614', 
   '1435030614', 
   '1436030614', 
   '1431030615', 
   '1434030615', 
   '1435030615', 
   '1436030615', 
   '1411030616', 
   '1414030616', 
   '1415030616', 
   '1416030616', 
   '1411039902', 
   '1414039902', 
   '1415039902', 
   '1416039902', 
   '1421030616', 
   '1424030616', 
   '1425030616', 
   '1426030616', 
   '1421039902', 
   '1424039902', 
   '1425039902', 
   '1426039902', 
   '1431030616', 
   '1434030616', 
   '1435030616', 
   '1436030616', 
   '1431039902', 
   '1434039902', 
   '1435039902', 
   '1436039902', 
   '1411031999', 
   '1414031999', 
   '1415031999', 
   '1416031999', 
   '1411030303', 
   '1414030303', 
   '1415030303', 
   '1416030303', 
   '1421031999', 
   '1424031999', 
   '1425031999', 
   '1426031999', 
   '1421030303', 
   '1424030303', 
   '1425030303', 
   '1426030303', 
   '1431031999', 
   '1434031999', 
   '1435031999', 
   '1436031999', 
   '1431030303', 
   '1434030303', 
   '1435030303', 
   '1436030303' )) 
   AND tipo_credito IN ('11', '12') AND cod_clasificacion_deudor <> '8' THEN saldo ELSE NULL END) AS sldpp2 
   from wrk_base_fact_report_rcc_rsk a 
   inner join wrk_dim_tiempo t on 1=1 
   where a.p_codmes BETWEEN t.lcodmesm24 and t.lcodmesm02 
 ), 
wrk_base_rcc_grupo as ( 
   select codmes_rcc, b.tip_doc, b.key_value, 
   max(case when substr(a.cod_cuenta_rcc, 1, 2) = ('14') 
       and substr(a.cod_cuenta_rcc, 4, 1) in ('1', '3', '4', '5', '6') 
       and a.cod_clasificacion_deudor <> '8' 
       and a.codempresa <> '00002' then a.condicion 
       else 0 end) as dm_t0, 
   SUM(sldpp2) as deuda_pp 
   from wrk_base_rcc a 
   inner join wrk_dim_tiempo t on 1=1 
   inner join wrk_base_mst_ctarcc_rsk b   
   on a.sbs_value = b.sbs_value 
   where a.codmes_rcc BETWEEN t.lcodmesm24 and t.lcodmesm02 
   group by 1,2,3  
), 
wrk_agg_rcc_deuda AS ( 
   select 
   a.codmes_rcc, 
   a.tip_doc, 
   a.key_value, 
   date_format(date_add('month', 1, date_parse(a.codmes_rcc,'%Y%m')),'%Y%m') as codmes_2, 
   case when a.deuda_pp is null and b.deuda_pp is null then null 
        else coalesce(a.deuda_pp, 0) /(coalesce(b.deuda_pp, 0) + 0.1) 
   end as ratio_deuda_pp 
   from wrk_base_rcc_grupo a 
   left join wrk_base_rcc_grupo b on a.key_value = b.key_value and a.tip_doc =  b.tip_doc 
   and a.codmes_rcc = date_format(date_add('month', 1, date_parse(b.codmes_rcc,'%Y%m')),'%Y%m') 
), 
wrk_feature_var_rcc_rsk as ( 
   select 
   a.tip_doc, 
   a.key_value, 
   max(case when a.codmes_rcc between t.lcodmesm04 and t.lcodmesm02 then a.dm_t0 end) as max_dias_atraso_no_ibk_cob_3m, 
   max(case when a.codmes_rcc between t.lcodmesm10 and t.lcodmesm02 then b.ratio_deuda_pp end) as max_dda_pp_rat_9m
   from wrk_base_rcc_grupo a 
   inner join wrk_dim_tiempo t on 1=1 
   left join wrk_agg_rcc_deuda b on a.key_value = b.key_value and a.tip_doc =  b.tip_doc and a.codmes_rcc = b.codmes_rcc 
   left join wrk_agg_rcc_deuda c on a.key_value = c.key_value and a.tip_doc =  c.tip_doc and c.codmes_rcc between t.lcodmesm25 and t.lcodmesm03 
   group by 1,2 
),
wrk_feature_admtcbank1_rsk as (  
 select  
   a.codmes, 
   a.tip_doc, 
   a.key_value, 
   a.cod_cuc, 
   b.antig_primer_producto, 
   h.cta_deccorreg_12m, 
   e.ctd_gestiones_6m, 
   c.desv_datraso_rd_u1a, 
   n.max_dda_pp_rat_9m, 
   n.max_dias_atraso_no_ibk_cob_3m, 
   c.prm_pctusotctot_u1a, 
   d.prm_slddispefpn_u6m, 
   s.rat_svotrppeallsf_3m 
 from wrk_base_po_rsk a 
 left join wrk_mst_ctaibk_rsk b on a.key_value=b.key_value and a.tip_doc=b.tip_doc 
 left join wrk_feature_rcc_sldo_rsk c on a.key_value=c.key_value and a.tip_doc=c.tip_doc 
 left join wrk_feature_mdl_rcc_disef_rsk d on a.key_value=d.key_value and a.tip_doc=d.tip_doc 
 left join wrk_feature_gestion_rsk e on a.key_value=e.key_value and a.tip_doc=e.tip_doc 
 left join wrk_feature_rcc_decrsldo_rsk h on a.key_value=h.key_value and a.tip_doc=h.tip_doc  
 left join wrk_feature_var_rcc_rsk n on a.key_value=n.key_value and a.tip_doc=n.tip_doc  
 left join wrk_feature_rcc_agg01_rsk s on a.key_value=s.key_value and a.tip_doc=s.tip_doc		    
),
wrk_base_calendario as (
   select 
   a.periodo,
   a.dia_habil,
   a.dia_calend as dia_calendario,
   a.dgestion as dia_gestion,
   a.tipo as tipo_dia,
   date(a.fecha) as fecha,
   cast(a.fec_inicial_habil as integer) as fec_inicial_habil,
   cast(a.fec_fin_habil as integer) as fec_fin_habil,
   a.codmes
   from e_perm_aws.t_mst_cob_calendario_her a
   inner join wrk_dim_tiempo t on 1 = 1
   where a.periodo between t.lcodmesm12_int and t.lcodmesm00_int
),
wrk_calendario as(
   select 
   cal1.periodo,
   cal1.fecha,
   cal1.tipo_dia,
   max(cal2.fecha) as fecha_habil_ant,
   to_char(max(cal2.fecha),'yyyymmdd') as fecha_habil_ant_txt,
   min(cal3.fecha) as fecha_habil,
   to_char(min(cal3.fecha),'yyyymmdd') as fecha_habil_txt
   from wrk_base_calendario cal1
   left join wrk_base_calendario cal2 on cal1.fecha > cal2.fecha and cal2.tipo_dia = 'O'
   left join wrk_base_calendario cal3 on cal1.fecha <= cal3.fecha and cal3.tipo_dia = 'O'
   group by 1,2,3
),
wrk_periodos_ejecucion as (
   select 
   a.periodo,
   b.periodo as periodo_inicio,
   date_diff('month',to_date(cast(b.periodo as varchar),'yyyymm'),to_date(cast(a.periodo as varchar),'yyyymm')) as meses
   from (select periodo, fecha from wrk_base_calendario where fec_inicial_habil = 1) a
   left join (select periodo,fecha from wrk_base_calendario where fec_inicial_habil = 1) b on a.periodo >= b.periodo
   where 1 = 1 and date_diff('month',to_date(cast(b.periodo as varchar),'yyyymm'),to_date(cast(a.periodo as varchar),'yyyymm')) <= 12
),
wrk_mst_ctaibk_rsk_2 AS ( 
   SELECT 
   MST.tip_doc, 
   MST.key_value, 
   MST.cod_cuc, 
   ROW_NUMBER() OVER (PARTITION BY MST.tip_doc, MST.key_value ORDER BY MST.cod_cuc DESC, MST.fch_pricont DESC) AS rnk 
   FROM wrk_base_mst_ctaibk_rsk MST
), 
wrk_base_maestra_clientes AS ( 
   select 
   bmc.cod_cuc, 
   bmc.tip_doc, 
   bmc.key_value 
   from wrk_mst_ctaibk_rsk_2 bmc 
   where bmc.rnk = 1 
),
wrk_po_ext as (
   select 
   re.tip_doc,
   re.key_value,
   cuc.cod_cuc as cuc, 
   t.codmes
   from wrk_base_po_rsk re
   inner join wrk_dim_tiempo t on 1 = 1
   left join wrk_base_maestra_clientes cuc on re.key_value = cuc.key_value and re.tip_doc=cuc.tip_doc
   group by 1,2,3,4
),
wrk_po as (
   select 
   a.tip_doc,
   a.key_value,
   a.cuc, 
   b.periodo_inicio,
   b.periodo as codmes,
   b.meses
   from wrk_po_ext a 
   left join wrk_periodos_ejecucion b on a.codmes  = cast(b.periodo as varchar)
   group by 1,2,3,4,5,6
),
wrk_pagos_tc AS (
   SELECT
   a.p_codmes periodo,
   a.fectransaccion fecha_pago,
   a.codunicocli cu,
   lpad(a.codctatarjeta, 10, '0') cuenta,
   a.fecprocesotrx fecha_proceso_pago,
   b.fecha_habil_ant_txt
   FROM e_perm_aws.t_trans_tarj_credito a
   INNER JOIN wrk_calendario b ON a.fectransaccion = b.fecha
   WHERE 1 = 1 AND (((codtransaccion IN ('30', '21')) AND (tipmovimiento IN ('0345', '0373', '0374', '0385', '0388', '0393', '0394', '0395', '0396', '0029', '0029', '0030', '0300', '0301', '0305', '0306', '0307', '0309', '0329', '0332', '0333'))) OR ((codtransaccion = '30') AND (tipmovimiento = '0303') AND (descomercio IN ('ABONO DEUDA IMPAGA', 'PAGO CON TARJ OTRO BANCO -', 'PAGO CON TARJ OTRO BANCO-RE', 'PAGO CON TARJ. OTRO BANCO', 'PAGO LINK NIUBIZ TARJETA C.'))))
   GROUP BY 1,2,3,4,5,6
),
wrk_pagos_hpc AS (
   SELECT
   format_datetime(a.fecha_pago, 'yyyyMM') as periodo, 
   a.fecha_pago,
   a.codunicliente cu,
   lpad(a.nrocredito, 10, '0') cuenta,
   a.fecha_pago fecha_proceso_pago,
   b.fecha_habil_ant_txt
   FROM e_perm_aws.t_rt_hpc_detalle_pagos_gdc a 
   INNER JOIN wrk_calendario b ON a.fecha_pago = b.fecha
   WHERE 1 = 1
   GROUP BY 1,2,3,4,5,6
),
wrk_pagos AS (
   SELECT  
   CAST(a.periodo AS varchar(6)) periodo,
   a.fecha_pago,
   a.cu,
   a.cuenta,
   a.fecha_proceso_pago,
   b.fecha_habil_ant_txt
   FROM e_perm_aws.t_cob_maestra_pagos a
   INNER JOIN wrk_calendario b ON a.fecha_proceso_pago = b.fecha
   WHERE 1 = 1 AND ((tipo_pago_cyber LIKE '%PAGO%') OR (tipo_pago_cyber LIKE '%AGO DE CUOTA%') OR (tipo_pago_cyber LIKE '%GO DE CUOTA%') OR (tipo_pago_cyber LIKE '%CANCELACION%') OR (tipo_pago_cyber LIKE '%NCELACION%') OR (tipo_pago_cyber LIKE '%ANCELACION%'))
   GROUP BY 1,2,3,4,5,6
), 
wrk_consolidado_pago AS (
   SELECT 
   a.periodo,
   a.fecha_pago,
   a.cu,
   a.cuenta,
   a.fecha_proceso_pago,
   a.fecha_habil_ant_txt
   FROM wrk_pagos a
   UNION
   SELECT 
   b.periodo,
   b.fecha_pago,
   b.cu,
   b.cuenta,
   b.fecha_proceso_pago,
   b.fecha_habil_ant_txt
   FROM wrk_pagos_tc b
   UNION    
   SELECT 
   c.periodo,
   c.fecha_pago,
   c.cu,
   c.cuenta,
   c.fecha_proceso_pago,
   c.fecha_habil_ant_txt
   FROM wrk_pagos_hpc c
),
wrk_pagos_dm as (
   select 
   pag.cu,
   pag.fecha_proceso_pago,
   sld.dm as dm_ant_pago
   from wrk_consolidado_pago pag
   left join e_perm_aws.t_diario_rsk sld on sld.p_fecinformacion=pag.fecha_habil_ant_txt
   and sld.cod_cuc = pag.cu  and sld.cuenta_num = pag.cuenta
   where 1 = 1
),
wrk_dm_fecha_pago as (
   select 
   to_char(fecha_proceso_pago,'yyyymm') as periodo,
   cu,
   max(dm_ant_pago) as max_dm_antes_pago
   from wrk_pagos_dm
   group by 1,2
),
wrk_variable_fecpago_dm_mes_mes as (
   select  
   vc.codmes,
   vc.tip_doc, 
   vc.key_value,
   vc.cuc, 
   vc.periodo_inicio, 
   vc.meses,
   coalesce(max(pag.max_dm_antes_pago),0) as max_dm_antes_pago
   from wrk_po vc
   left join wrk_dm_fecha_pago pag on vc.cuc = pag.cu
   and cast(vc.periodo_inicio as varchar) = pag.periodo 
   group by 1,2,3,4,5,6
   order by codmes,periodo_inicio
),
wrk_variable_fecpago_dm_mes_mes_pivot as (
   select 
   codmes,
   tip_doc,
   key_value,
   max(cuc) as cuc,
   max(case when meses = 0 then max_dm_antes_pago end) as max_dm_antes_pago_m0,
   max(case when meses = 1 then max_dm_antes_pago end) as max_dm_antes_pago_m1
   from wrk_variable_fecpago_dm_mes_mes
   group by 1,2,3
),
wrk_variable_fecpago_dm_mes_mes_pivot_2 as (
   select 
   codmes,
   tip_doc,
   key_value,
   cuc,
   max_dm_antes_pago_m0,
   max_dm_antes_pago_m1,
   cast(null as smallint) as atraso_01_aj
   from wrk_variable_fecpago_dm_mes_mes_pivot a
),
wrk_variable_fecpago_dm_mes_mes_pivot_2_1 as (
   select 
   codmes,
   cuc,
   tip_doc,
   key_value,
   case when max_dm_antes_pago_m0 is null then max_dm_antes_pago_m1 else max_dm_antes_pago_m1 end as atraso_01_aj
   from wrk_variable_fecpago_dm_mes_mes_pivot_2 a
),
wrk_feature_cdp_rsk as (
   select 
   x.codmes,
   x.cuc,
   x.tip_doc,
   x.key_value,
   case when x.atraso_01_aj > 30 then 30 else x.atraso_01_aj end as atraso_01_aj
   from wrk_variable_fecpago_dm_mes_mes_pivot_2_1 x
),
wrk_base_cron AS (
   SELECT
   cast(date_format(a.fecvencimiento, '%Y%m') as int) AS codmes_cuota,
   a.codmes as cod_mes,
   b.cod_cuc as cod_cli,
   a.nrocredito as cod_operacion,
   a.nrocuota as num_cuota,
   a.fecvencimiento as fec_venc_cuota,
   a.fecpago as fec_pago_cuota 
   FROM e_perm_aws.t_ifrs_hpc_cuotas_all a 
   LEFT JOIN e_perm_aws.t_seg_cliente_cartera_rsk b ON a.NROCREDITO = b.CODOPERACION and a.CODMES = cast(b.CODMES as int)
   INNER JOIN wrk_dim_tiempo t on 1 = 1
   WHERE a.p_codmes BETWEEN t.lcodmesM12 and t.lcodmesM01
   GROUP BY 1,2,3,4,5,6,7
),
wrk_base_final_cron AS (
   SELECT 
   a.codmes_cuota,
   a.cod_mes,
   a.cod_cli,
   a.cod_operacion,
   a.num_cuota,
   a.fec_venc_cuota,
   a.fec_pago_cuota,
   a.fec_pago_cuota as pago_fecha_base
   FROM wrk_base_cron a 
   WHERE a.cod_mes = a.codmes_cuota
),
wrk_salida AS (
   SELECT
   sp.cod_cli,
   sp.codmes_cuota,
   sp.cod_mes,
   sp.cod_operacion,
   sp.num_cuota,
   sp.fec_venc_cuota,
   sp.fec_pago_cuota,
   sp.pago_fecha_base,
   CASE WHEN sp.pago_fecha_base IS NOT NULL AND sp.pago_fecha_base <> DATE '1900-01-01' THEN date_diff('day', sp.fec_venc_cuota, sp.pago_fecha_base) ELSE NULL END AS dias_adelanto_atraso
   FROM wrk_base_final_cron sp
),
wrk_final_mes AS (
   SELECT 
   f.cod_cli,
   f.codmes_cuota,
   f.cod_mes,
   f.cod_operacion,
   f.num_cuota,
   f.fec_venc_cuota,
   f.fec_pago_cuota,
   f.pago_fecha_base,
   f.dias_adelanto_atraso
   FROM wrk_salida f
   INNER JOIN wrk_dim_tiempo t ON 1 = 1
   WHERE f.cod_mes = t.lcodmesm01_int 
  ),
wrk_feature_cronograma_rsk AS (
   SELECT 
   x.cod_cli,
   x.codmes_cuota,
   x.cod_mes,
   x.cod_operacion,
   x.num_cuota,
   x.fec_venc_cuota,
   x.fec_pago_cuota,
   x.pago_fecha_base,
   x.dias_adelanto_atraso
   FROM (
   SELECT
   f.cod_cli,
   f.codmes_cuota,
   f.cod_mes,
   f.cod_operacion,
   f.num_cuota,
   f.fec_venc_cuota,
   f.fec_pago_cuota,
   f.pago_fecha_base,
   f.dias_adelanto_atraso,
   ROW_NUMBER() OVER (PARTITION BY CAST(f.cod_mes AS VARCHAR), f.cod_cli ORDER BY f.fec_venc_cuota DESC, f.num_cuota DESC, f.cod_operacion DESC) AS rn
   FROM wrk_final_mes f
   ) x
   WHERE x.rn = 1
),
wrk_feature_intercorp as ( 
   select  
   b.tip_doc, 
   b.key_value, 
   a.trf_mto_max_venta_rubro_grifos_pos_ult_12m as trf_mtomax_grifos_pos12m,
   a.trf_far_mtomax_medicamento_12m as trf_far_mtomax_med_12m,
   a.trf_mto_total_tc_retail_pos_1m as trf_mtot_tc_retail_pos1m,
   a.trf_prm_rubro_restaurantes_pos_ult_6m as trf_prm_restaur_pos_6m,
   a.trf_mto_prm_alta_gama_ult_12m as trf_mtoprm_altagama_12m,
   a.trf_monto_consumo_salud_u24m as trf_mto_salud_u24m
   from e_perm_aws.t_inca_cmp a 
   inner join wrk_dim_tiempo t on 1 = 1 
   left join (select tip_doc, key_value, inter_party_id from e_perm_aws.t_mst_inter_ibk_base_cliente where tip_doc = '1') b on a.party_id = b.inter_party_id 
   where a.process_date = t.lcodmesm02 
),
wrk_feature_cppibkren as (
select 
   a.key_value, 
   a.tip_doc as cod_tip_doc, 
   a.cod_cuc as cod_cli,  
   cast(m.max_clfibk06m as decimal(18,3)) as max_clfibk_06m, 
   cast(m.ctd_mespeornor12m as decimal(18,3)) as cnt_mespeornorssff_12m, 
   cast(case when d.flag_dependiente is null then 0 else d.flag_dependiente end as int) as flg_labdp, 
   cast(coalesce(m.flg_pasivos_ibk,0) as int) as flg_pasibk,
   cast(m.prm_diamoraptmult12m as decimal(18,3)) as avg_diamorasldppibk_12m, 
   cast(m.ctd_entsldrsg06m as decimal(18,3)) as porc_max_sldrsg_06m, 
   cast(m.min_pas_ctsld_12m as decimal(18,3)) as min_pasctasld_12m, 
   cast(ee.edad as int) as num_edad, 
   cast(m.ratio_act_pas_tot_3m as decimal(18,6)) as rat_actpas_03m, 
   cast(m.max_rtosldppibk03m as decimal(18,3)) as rat_maxsldppibk_03m,
   cast(c.nro_vehiculos as integer) num_vehiculos,
   cast(e.mdn_sld_sa_hip_3i_6m as decimal(18,3)) as med_sld_sa_hip_3i_6m,
   cast(e.prm_ratdispefpnj_u1a as decimal(18,3)) as avg_rat_dispefpnj_u1a,
   cast(e.ctd_dectctotal_12m as int) as cnt_dectctotal_12m,
   cast(e.ratio_saldo_rt_t1_t12 as decimal(21,3)) as rat_saldo_rt_t1_t12,
   cast(e.prm_pct_sld_rd_6m as decimal(23,10)) as porc_avg_sld_rd_6m,
   cast(e.rat_miemsup2r as decimal(21,3)) as rat_miemsup2r,
   cast(e.ratio_comparacion_u1m_u12m as decimal(18,4)) as rat_comparacion_u1m_u12m,
   cast(f.antig_profesional as int) as ant_profesional,
   cast(f.num_inmuebles as int) as num_inmuebles,
   cast(f.mnt_totalrec06m as decimal(18,3)) as mto_totalrec06m,
   cast(f.prm_trxtot12m as decimal(18,3)) as avg_trxtot12m,
   cast(f.nro_titulo_prof as int) as num_titulo_prof,
   cast(g.prm_decrsld12m as decimal(18,6)) as avg_decrsld12m,
   cast(h.ratio_saldo_pp_u1m_tc_ibk as decimal(18,4)) as rat_sld_pp_u1m_tc_ibk,
   cast(i.beta_saldo_p_u1a as decimal(18,6)) as sld_beta_pc_pp_1a,
   cast(i.beta_entidades_dist_rd_u1a as decimal(18,6)) as var_ent_dist_rd_1a,
   cast(i.mnt_ddaotremp12m as decimal(18,6)) as mto_dda_otr_emp_12m,
   cast(i.nro_incsldtippas12m as int) as num_inc_sld_tip_pas_12m,
   cast(i.mdn_dec_sld_tarj_3i_6m as decimal(18,3)) as med_dec_sld_tarj_3i_6m, 
   cast(i.prm_ddatelc12m as decimal(18,3)) as avg_dda_tlc_12m, 
   cast(j.antig_primer_producto as int) as ant_primer_producto,
   cast(j.cta_deccorreg_12m as int) as cnt_deccorreg_12m,
   cast(j.ctd_gestiones_6m as int) as cnt_gestiones_6m,
   cast(j.desv_datraso_rd_u1a as decimal(23,10)) as std_datraso_rd_u1a,
   cast(j.max_dda_pp_rat_9m as decimal(23,10)) as max_dda_pp_rat_9m,
   cast(j.max_dias_atraso_no_ibk_cob_3m as int) as max_dias_atraso_no_ibk_3m,
   cast(j.prm_pctusotctot_u1a as decimal(23,10)) as porc_avg_pctusotctot_u1a,
   cast(j.prm_slddispefpn_u6m as decimal(23,10)) as avg_slddispefpn_u6m,
   cast(j.rat_svotrppeallsf_3m as decimal(23,10)) as rat_svotrppeallsf_3m,
   cast(k.atraso_01_aj as int) as cnt_atraso_01_aj,
   cast(l.dias_adelanto_atraso as int) as cnt_dias_adelanto_atraso,
   cast(n.trf_mtomax_grifos_pos12m as int) as trf_mtomax_grifos_pos12m,
   cast(n.trf_far_mtomax_med_12m as int) as trf_far_mtomax_med_12m,
   cast(n.trf_mtot_tc_retail_pos1m as int) as trf_mtot_tc_retail_pos1m,
   cast(n.trf_prm_restaur_pos_6m as int) as trf_prm_restaur_pos_6m,
   cast(n.trf_mtoprm_altagama_12m as int) as trf_mtoprm_altagama_12m,
   cast(n.trf_mto_salud_u24m as int) as trf_mto_salud_u24m
   from wrk_base_po_rsk a 
   left join wrk_vars_compp_rsk m on a.cod_cuc = m.cod_cuc and a.tip_doc = m.tip_doc 
   left join wrk_base_dependiente_rsk d on a.key_value = d.key_value and a.tip_doc = d.tip_doc 
   left join wrk_mst_reniec_rsk ee on a.key_value = ee.key_value and a.tip_doc = ee.tip_doc 
   left join wrk_vehiculos c on a.key_value = c.key_value and a.tip_doc = c.tip_doc
   left join wrk_feature_infingnc_rsk e on a.tip_doc = e.tip_doc and a.key_value = e.key_value
   left join wrk_base_inicial_rsk f on a.tip_doc = f.tip_doc and a.key_value = f.key_value
   left join wrk_rcc_3_rsk g on a.tip_doc = g.tip_doc and a.key_value = g.key_value
   left join wrk_rat_sldo_rcc h on a.tip_doc = h.tipdoc and a.key_value = h.coddoc
   left join wrk_feature_viscliest_rsk i on a.tip_doc = i.tip_doc and a.key_value = i.key_value  
   left join wrk_feature_admtcbank1_rsk j on a.key_value = j.key_value and a.tip_doc = j.tip_doc
   left join wrk_feature_cdp_rsk k on a.key_value = k.key_value and a.tip_doc = k.tip_doc
   left join wrk_feature_cronograma_rsk l on a.cod_cuc = l.cod_cli
   left join wrk_feature_intercorp n on a.tip_doc = n.tip_doc and a.key_value = n.key_value
),
-- Start: Add Calibration
cal_meses as (
   select date_format(m, '%Y%m') as cm
     from unnest(sequence(date '2018-01-01', date '2027-12-01', interval '1' month)) as t(m)
),
ipc as (
   select c.cm, max(cast(b.porc_ipc as double)) as ipc
     from cal_meses c
     left join e_perm_aws.t_mst_bcrp_rsk b on cast(b.cod_mes as varchar) = c.cm
    group by 1
),
mac as (
   select cm,
          avg(ipc)   over (order by cm rows between 10 preceding and 5 preceding) as x,
          count(ipc) over (order by cm rows between 10 preceding and 5 preceding) as n_vent
     from ipc
),
ft as (
   select cm as codmes_mrm,
          x,
          greatest(least(
            (inverse_normal_cdf(0.0, 1.0, 0.04226346409008948)
              - sqrt(1.0 - 0.038030115964094044) * (-1.900195796163702 + 0.6583423568236846 * x))
            / sqrt(0.038030115964094044)
            + 0.19111262350586136
          , 0.7656842281878757), -1.1308495593693428) as f_t
     from mac
    where n_vent = 6
),
cls_ing as (
   select substr(subject_id, 3)     as id_value,
          cast(tip_doc as varchar)   as tip_doc,
          cast(periodo as varchar)   as codmes_mrm,
          case when max(case when sit_lab = 'DEPENDIENTE'
                               and fuente not in ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                              then 1 else 0 end) = 1
               then 'DEP' else 'NO DEP' end as tipo_ingreso_dep
     from e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
    where cast(numcarga as int) = 1
      and cast(periodo as varchar) = date_format(date_add('month', -1, date_parse('202606', '%Y%m')), '%Y%m')
    group by 1, 2, 3
)
-- End: Add Calibration
SELECT
   t.lcodmesM00 as cod_mes,
   a.key_value,
   a.cod_tip_doc,
   a.cod_cli,
   a.max_clfibk_06m,
   a.cnt_mespeornorssff_12m,
   a.flg_labdp,
   a.flg_pasibk,
   a.avg_diamorasldppibk_12m,
   a.porc_max_sldrsg_06m,
   a.min_pasctasld_12m,
   a.num_edad,
   a.rat_actpas_03m,
   a.rat_maxsldppibk_03m,
   a.num_vehiculos,
   a.med_sld_sa_hip_3i_6m,
   a.avg_rat_dispefpnj_u1a,
   a.cnt_dectctotal_12m,
   a.rat_saldo_rt_t1_t12,
   a.porc_avg_sld_rd_6m,
   a.rat_miemsup2r,
   a.rat_comparacion_u1m_u12m,
   a.ant_profesional,
   a.num_inmuebles,
   a.mto_totalrec06m,
   a.avg_trxtot12m,
   a.num_titulo_prof,
   a.avg_decrsld12m,
   a.rat_sld_pp_u1m_tc_ibk,
   a.sld_beta_pc_pp_1a,
   a.var_ent_dist_rd_1a,
   a.mto_dda_otr_emp_12m,
   a.num_inc_sld_tip_pas_12m,
   a.med_dec_sld_tarj_3i_6m,
   a.avg_dda_tlc_12m,
   a.ant_primer_producto,
   a.cnt_deccorreg_12m,
   a.cnt_gestiones_6m,
   a.std_datraso_rd_u1a,
   a.max_dda_pp_rat_9m,
   a.max_dias_atraso_no_ibk_3m,
   a.porc_avg_pctusotctot_u1a,
   a.avg_slddispefpn_u6m,
   a.rat_svotrppeallsf_3m,
   a.cnt_atraso_01_aj,
   a.cnt_dias_adelanto_atraso,
   a.trf_mtomax_grifos_pos12m,
   a.trf_far_mtomax_med_12m,
   a.trf_mtot_tc_retail_pos1m,
   a.trf_prm_restaur_pos_6m,
   a.trf_mtoprm_altagama_12m,
   a.trf_mto_salud_u24m,  
   (localtimestamp - interval '5' hour) as ts_carga,
   -- Start: Add Calibration
   coalesce(ci.tipo_ingreso_dep, 'NO DEP')                                      as trf_tipo_ingreso_dep,
   f.f_t                                                                        as trf_macro01,
   f.x                                                                          as trf_macro02,
   -- End: Add Calibration
   t.lcodmesM00 as p_codmes
from wrk_feature_cppibkren a
inner join wrk_dim_tiempo t on 1 = 1
-- Start: Add Calibration
left join ft f on f.codmes_mrm = t.lcodmesM01
left join cls_ing ci on ci.id_value = a.key_value
                    and ci.tip_doc = cast(a.cod_tip_doc as varchar)
                    and ci.codmes_mrm = t.lcodmesM01
-- End: Add Calibration
