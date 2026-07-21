-- =====================================================================================
-- ORIGEN BPE PD · V2 · BUILD (crea tablas)
--   archivo : CALIB_2_target.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\CALIB_2_target.sql
--   sha256  : a83a24121844   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : targets 1m..12m desde RCC crudo IBK; depende de CALIB_1
-- =====================================================================================
-- =====================================================================================
-- CALIB_2_target.sql | ETAPA 1b — targets 1m..12m, DESDE RCC CRUDO
--
-- ESCRIBE: disc_model_owner.b46029_calib_target
--
-- FUENTES
--   disc_model_owner.b46029_calib_altas    (CALIB_1)  poblacion
--   e_perm_aws.t_fact_report_rcc_rsk       MADRE      RCC crudo, solo IBK '00002'
--
-- POR QUE NO ESTA d_perm_aws
--   El original SI la incluye y advierte "no eliminar: truncaria los targets historicos".
--   Esa advertencia aplica al tramo de cohortes 201801-202206, que aqui NO se construye.
--   Con altas desde 202207 la ventana forward arranca en 202208: toda por encima del
--   corte 201901. Incluirla seria una rama que lee 0 filas — el mismo codigo muerto que
--   ya existe en 10_flags_rcc.sql. Si se agrega el tramo historico, vuelve a hacer falta.
--
-- DEFINICION DE DEFAULT — inlinada VERBATIM de q2_target_src.sql (== S1_rcc_agg)
--   dm           max(condicion) sobre 14.x[1,3,4,5,6] con substr(7,2) NOT IN ('01','04)
--                                  OR 81.302/925 ;  tipo_credito 01-10
--   saldo_total  sum(saldo)     sobre 14.x[1,3,4,5,6] OR 81.302/925 ; tipo 01-10 (n_obs)
--   flag_jud     14.x substr(4,1)='6'
--   flag_cast    81.x substr(4,3) IN ('302','925')
--   flag_ref     14.x substr(4,1)='4'
--   flag_ref_ree 14.x substr(4,1)='3'
--   default_N =  dm>90  U  jud  U  cast  U  ref  U  ree,  acumulado sobre age<=N
--
-- POR QUE IMPORTAN LAS TEMPRANAS
--   target_12m solo se observa en cohortes con 12 meses cerrados: hasta 202505. Las de
--   1m..6m dejan medir cohortes recientes (202506+) mucho antes. Como el default
--   acumulado es monotono no-decreciente, target_6m es COTA INFERIOR de target_12m.
--
-- LEFT JOIN a proposito: un alta sin exposicion IBK forward se conserva con n_obs=0 y
-- target=0. Sacarla sesgaria la RD hacia arriba.
--
-- Si ya existe: DROP TABLE disc_model_owner.b46029_calib_target
-- =====================================================================================
CREATE TABLE disc_model_owner.b46029_calib_target
WITH (format='PARQUET', parquet_compression='SNAPPY') AS

WITH alt AS (
    SELECT codmes, tip_doc, key_value
    FROM disc_model_owner.b46029_calib_altas
    WHERE top4_entidad = 'TOP4'
),

rcc_raw AS (   -- RCC crudo, SOLO IBK, ventana forward podada por particion
    SELECT codmes, tip_doc, key_value, cod_cuenta_rcc, tipo_credito, condicion, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202208' AND '202704'
      AND codmes   BETWEEN '202208' AND '202704'
      AND cod_instit_financiera = '00002'
),

agg_ibk AS (   -- grano cliente-mes IBK
    SELECT tip_doc, key_value, cast(codmes AS integer) AS codmes,
        max(case when cast(tipo_credito as int) between 1 and 10
                  and ( (substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,7,2) not in ('01','04') and substr(cod_cuenta_rcc,4,1) in ('1','3','4','5','6'))
                        or (substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,3) in ('302','925')) )
            then condicion else null end) as dm,
        sum(case when cast(tipo_credito as int) between 1 and 10
                  and ( (substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1) in ('1','3','4','5','6'))
                        or (substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,3) in ('302','925')) )
            then saldo else null end) as saldo_total,
        max(case when substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1)='6' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') then 1 else 0 end) as flag_jud,
        max(case when substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,3) in ('302','925') and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') then 1 else 0 end) as flag_cast,
        max(case when substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1)='4' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') then 1 else 0 end) as flag_ref,
        max(case when substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1)='3' and tipo_credito in ('01','02','03','04','05','06','07','08','09','10') then 1 else 0 end) as flag_ref_ree
    FROM rcc_raw
    GROUP BY tip_doc, key_value, codmes
),

perf AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
           date_diff('month', date_parse(a.codmes,'%Y%m'),
                              date_parse(cast(g.codmes as varchar),'%Y%m')) AS age,
           g.saldo_total, g.dm, g.flag_jud, g.flag_cast, g.flag_ref, g.flag_ref_ree
    FROM alt a
    LEFT JOIN agg_ibk g
      ON g.tip_doc = a.tip_doc AND g.key_value = a.key_value
     AND g.codmes >  cast(a.codmes as int)
     AND g.codmes <= cast(date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') as int)
)

SELECT codmes, tip_doc, key_value,
  count(distinct case when saldo_total>0 and age between 1 and 12 then age end) as n_obs_ibk_12,
  max(case when age<=1 then dm else null end) as dias_atraso_1m_ibk,
  max(case when age<=2 then dm else null end) as dias_atraso_2m_ibk,
  max(case when age<=3 then dm else null end) as dias_atraso_3m_ibk,
  max(case when age<=4 then dm else null end) as dias_atraso_4m_ibk,
  max(case when age<=5 then dm else null end) as dias_atraso_5m_ibk,
  max(case when age<=6 then dm else null end) as dias_atraso_6m_ibk,
  max(case when age<=7 then dm else null end) as dias_atraso_7m_ibk,
  max(case when age<=8 then dm else null end) as dias_atraso_8m_ibk,
  max(case when age<=9 then dm else null end) as dias_atraso_9m_ibk,
  max(case when age<=10 then dm else null end) as dias_atraso_10m_ibk,
  max(case when age<=11 then dm else null end) as dias_atraso_11m_ibk,
  max(case when age<=12 then dm else null end) as dias_atraso_12m_ibk,
  case when max(case when age<=1 then dm else 0 end) > 90 or max(case when age<=1 then flag_jud else 0 end)=1 or max(case when age<=1 then flag_cast else 0 end)=1 or max(case when age<=1 then flag_ref else 0 end)=1 or max(case when age<=1 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_1m,
  case when max(case when age<=2 then dm else 0 end) > 90 or max(case when age<=2 then flag_jud else 0 end)=1 or max(case when age<=2 then flag_cast else 0 end)=1 or max(case when age<=2 then flag_ref else 0 end)=1 or max(case when age<=2 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_2m,
  case when max(case when age<=3 then dm else 0 end) > 90 or max(case when age<=3 then flag_jud else 0 end)=1 or max(case when age<=3 then flag_cast else 0 end)=1 or max(case when age<=3 then flag_ref else 0 end)=1 or max(case when age<=3 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_3m,
  case when max(case when age<=4 then dm else 0 end) > 90 or max(case when age<=4 then flag_jud else 0 end)=1 or max(case when age<=4 then flag_cast else 0 end)=1 or max(case when age<=4 then flag_ref else 0 end)=1 or max(case when age<=4 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_4m,
  case when max(case when age<=5 then dm else 0 end) > 90 or max(case when age<=5 then flag_jud else 0 end)=1 or max(case when age<=5 then flag_cast else 0 end)=1 or max(case when age<=5 then flag_ref else 0 end)=1 or max(case when age<=5 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_5m,
  case when max(case when age<=6 then dm else 0 end) > 90 or max(case when age<=6 then flag_jud else 0 end)=1 or max(case when age<=6 then flag_cast else 0 end)=1 or max(case when age<=6 then flag_ref else 0 end)=1 or max(case when age<=6 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_6m,
  case when max(case when age<=7 then dm else 0 end) > 90 or max(case when age<=7 then flag_jud else 0 end)=1 or max(case when age<=7 then flag_cast else 0 end)=1 or max(case when age<=7 then flag_ref else 0 end)=1 or max(case when age<=7 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_7m,
  case when max(case when age<=8 then dm else 0 end) > 90 or max(case when age<=8 then flag_jud else 0 end)=1 or max(case when age<=8 then flag_cast else 0 end)=1 or max(case when age<=8 then flag_ref else 0 end)=1 or max(case when age<=8 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_8m,
  case when max(case when age<=9 then dm else 0 end) > 90 or max(case when age<=9 then flag_jud else 0 end)=1 or max(case when age<=9 then flag_cast else 0 end)=1 or max(case when age<=9 then flag_ref else 0 end)=1 or max(case when age<=9 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_9m,
  case when max(case when age<=10 then dm else 0 end) > 90 or max(case when age<=10 then flag_jud else 0 end)=1 or max(case when age<=10 then flag_cast else 0 end)=1 or max(case when age<=10 then flag_ref else 0 end)=1 or max(case when age<=10 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_10m,
  case when max(case when age<=11 then dm else 0 end) > 90 or max(case when age<=11 then flag_jud else 0 end)=1 or max(case when age<=11 then flag_cast else 0 end)=1 or max(case when age<=11 then flag_ref else 0 end)=1 or max(case when age<=11 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_11m,
  case when max(case when age<=12 then dm else 0 end) > 90 or max(case when age<=12 then flag_jud else 0 end)=1 or max(case when age<=12 then flag_cast else 0 end)=1 or max(case when age<=12 then flag_ref else 0 end)=1 or max(case when age<=12 then flag_ref_ree else 0 end)=1 then 1 else 0 end as target_12m
FROM perf
GROUP BY codmes, tip_doc, key_value
