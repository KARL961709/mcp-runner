-- 01 inference t_cal_cppibkren_rsk
with
tiempo as (
   select '{codmes}' as t,
          date_parse('{codmes}', '%Y%m') as d
),
par as (
   select p.valor as cod_mes_freeze
     from <base_cal>.t_cal_parametros_rsk p
    where p.modelo = 'cppibkren'
      and p.parametro = 'cod_mes_freeze'
      and p.p_codmes <= '{codmes}'
    order by p.p_codmes desc, p.nro_carga desc
    limit 1
),
ipc as (
   select cast(b.cod_mes as varchar) as cm,
          max(cast(b.porc_ipc as double)) as ipc
     from e_perm_aws.t_mst_bcrp_rsk b
    group by 1
),
x_mes as (
   select avg(i.ipc) as x,
          count(i.ipc) as n
     from ipc i
    cross join tiempo t
    where i.cm between date_format(date_add('month', -11, t.d), '%Y%m')
                   and date_format(date_add('month', -6, t.d), '%Y%m')
),
x_frz as (
   select max(c.var_macro_01) as x,
          count(*) as n
     from <base_cal>.t_cal_cppibkren_rsk c
    cross join par
    where c.p_codmes = par.cod_mes_freeze
),
macro as (
   select case when xm.n = 6 then xm.x end as var_macro_01,
          case when par.cod_mes_freeze = '{codmes}' then (case when xm.n = 6 then xm.x end)
               else xf.x end as var_macro_02
     from x_mes xm
    cross join par
    cross join x_frz xf
),
pd_raw as (
   select cast(s.cod_mes as varchar) as cod_mes,
          cast(s.cod_tip_doc as varchar) as cod_tip_doc,
          cast(s.key_value as varchar) as key_value,
          cast(s.cod_cli as varchar) as cod_cli,
          cast(s.prob_modelo as double) as prob_modelo,
          cast(s.puntuacion as integer) as puntuacion
     from <base_mlops>.scr_cppibkren_rsk s
    where s.p_codmes = '{codmes}'
),
cls_ing as (
   select substr(subject_id, 3) as id_value,
          cast(tip_doc as varchar) as tip_doc,
          case when max(case when sit_lab = 'DEPENDIENTE'
                               and fuente not in ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                              then 1 else 0 end) = 1
               then 'DEP' else 'NO DEP' end as tipo_ingreso_dep
     from e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
    where cast(numcarga as int) = 1
      and cast(periodo as varchar) = date_format(date_add('month', -1, date_parse('{codmes}', '%Y%m')), '%Y%m')
    group by 1, 2
)
select a.cod_mes,
       a.cod_tip_doc,
       a.key_value,
       a.cod_cli,
       a.prob_modelo,
       a.puntuacion,
       m.var_macro_01,
       m.var_macro_02,
       cast(null as double) as var_macro_03,
       cast(null as double) as var_macro_04,
       cast(null as double) as var_macro_05,
       cast(null as double) as var_macro_06,
       cast(null as double) as var_macro_07,
       cast(null as double) as var_macro_08,
       cast(null as double) as var_macro_09,
       cast(null as double) as var_macro_10,
       cast(null as double) as var_macro_11,
       cast(null as double) as var_macro_12,
       coalesce(ci.tipo_ingreso_dep, 'NO DEP') as var_driver_01,
       cast(null as varchar) as var_driver_02,
       cast(null as varchar) as var_driver_03,
       cast(null as varchar) as var_driver_04,
       cast(null as varchar) as var_driver_05,
       cast(null as varchar) as var_driver_06,
       cast(null as varchar) as var_driver_07,
       cast(null as varchar) as var_driver_08,
       cast(null as varchar) as var_driver_09,
       cast(null as varchar) as var_driver_10,
       cast(null as varchar) as var_driver_11,
       cast(null as varchar) as var_driver_12,
       cast(null as varchar) as flg_clean_01,
       cast(null as varchar) as flg_clean_02,
       cast(null as varchar) as flg_clean_03,
       cast(null as varchar) as flg_clean_04,
       (localtimestamp - interval '5' hour) as ts_carga,
       '{codmes}' as p_codmes,
       date_format(localtimestamp - interval '5' hour, '%Y%m%d') as p_fecdia
  from pd_raw a
 cross join macro m
  left join cls_ing ci on ci.id_value = a.key_value
                      and ci.tip_doc = a.cod_tip_doc
