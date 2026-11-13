-- 02 inference t_cal_vcadmbnk_rsk
with
tiempo as (
   select '{codmes}' as t,
          date_parse('{codmes}', '%Y%m') as d
),
par as (
   select p.valor as cod_mes_freeze
     from <base_cal>.t_cal_parametros_rsk p
    where p.modelo = 'vcadmbnk'
      and p.parametro = 'cod_mes_freeze'
      and p.p_codmes <= '{codmes}'
    order by p.p_codmes desc, p.nro_carga desc
    limit 1
),
cal as (
   select date_format(m, '%Y%m') as cm
     from tiempo t
    cross join unnest(sequence(date_add('month', -40, t.d), t.d, interval '1' month)) as u(m)
),
ipc as (
   select c.cm,
          max(cast(b.porc_ipc as double)) as ipc
     from cal c
     left join e_perm_aws.t_mst_bcrp_rsk b on cast(b.cod_mes as varchar) = c.cm
    group by 1
),
v12 as (
   select cm,
          case when count(ipc) over (order by cm rows between 11 preceding and current row) = 12
               then 100.0 * (exp(sum(ln(1.0 + ipc / 100.0)) over (order by cm rows between 11 preceding and current row)) - 1.0)
          end as v12
     from ipc
),
ult as (
   select max(cm) as ult
     from v12
    where v12 is not null
),
caso as (
   select u.ult,
          date_diff('month', date_parse(u.ult, '%Y%m'), t.d) as k,
          mod(month(date_parse(u.ult, '%Y%m')), 3) as fase,
          case when mod(month(date_parse(u.ult, '%Y%m')), 3) = 0 then 3
               else 3 - mod(month(date_parse(u.ult, '%Y%m')), 3) end as e0
     from ult u
    cross join tiempo t
),
entrega as (
   select p_codmes, nro_carga
     from (select p_codmes, nro_carga,
                  row_number() over (order by p_codmes desc, nro_carga desc) as rn
             from disc_model_owner.macro_apoyo_proy
            where ticker = 'AP00025BQ'
              and p_codmes <= '{codmes}'
            group by p_codmes, nro_carga) z
    where rn = 1
),
apoyo as (
   select cast(a.cod_mes as varchar) as cod_mes,
          cast(a.valor as double) as valor
     from disc_model_owner.macro_apoyo_proy a
     join entrega e on a.p_codmes = e.p_codmes and a.nro_carga = e.nro_carga
    where a.ticker = 'AP00025BQ'
),
x_obs as (
   select avg(v.v12) as x,
          count(v.v12) as n
     from v12 v
    cross join tiempo t
    where v.cm between date_format(date_add('month', -2, t.d), '%Y%m') and t.t
),
x_denton as (
   select sum(w.peso * case when w.origen = 'OBS' then o.v12 else a.valor end) as x,
          count(*) as n_pesos,
          count(case when w.origen = 'OBS' then o.v12 else a.valor end) as n_ok
     from <base_cal>.t_mst_denton_pesos_rsk w
    cross join caso c
     left join v12 o on w.origen = 'OBS'
                    and o.cm = date_format(date_add('month', -w.rel, date_parse(c.ult, '%Y%m')), '%Y%m')
     left join apoyo a on w.origen = 'TRIM'
                      and a.cod_mes = date_format(date_add('month', c.e0 + 3 * w.rel, date_parse(c.ult, '%Y%m')), '%Y%m')
    where w.variante = 'SIN_TRIM_CURSO'
      and w.fase = c.fase
      and w.k = c.k
),
x_mes as (
   select case when c.k = 0 and xo.n = 3 then xo.x
               when c.k in (1, 2) and xd.n_pesos > 0 and xd.n_ok = xd.n_pesos then xd.x
          end as x
     from caso c
    cross join x_obs xo
    cross join x_denton xd
),
x_frz as (
   select max(c.var_macro_01) as x
     from <base_cal>.t_cal_vcadmbnk_rsk c
    cross join par
    where c.p_codmes = par.cod_mes_freeze
),
macro as (
   select xm.x as var_macro_01,
          case when par.cod_mes_freeze = '{codmes}' then xm.x else xf.x end as var_macro_02
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
     from <base_mlops>.scr_vcadmbnk_rsk s
    where s.p_codmes = '{codmes}'
),
drivers as (
   select key_value, cod_tip_doc,
          var_driver_01, var_driver_02, var_driver_03, var_driver_04, var_driver_05,
          flg_clean_01, flg_clean_02
     from <fuente_drivers_vc>
    where p_codmes = '{codmes}'
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
       d.var_driver_01,
       d.var_driver_02,
       d.var_driver_03,
       d.var_driver_04,
       d.var_driver_05,
       cast(null as varchar) as var_driver_06,
       cast(null as varchar) as var_driver_07,
       cast(null as varchar) as var_driver_08,
       cast(null as varchar) as var_driver_09,
       cast(null as varchar) as var_driver_10,
       cast(null as varchar) as var_driver_11,
       cast(null as varchar) as var_driver_12,
       d.flg_clean_01,
       d.flg_clean_02,
       cast(null as varchar) as flg_clean_03,
       cast(null as varchar) as flg_clean_04,
       (localtimestamp - interval '5' hour) as ts_carga,
       '{codmes}' as p_codmes,
       date_format(localtimestamp - interval '5' hour, '%Y%m%d') as p_fecdia
  from pd_raw a
 cross join macro m
  left join drivers d on d.key_value = a.key_value
                     and d.cod_tip_doc = a.cod_tip_doc
