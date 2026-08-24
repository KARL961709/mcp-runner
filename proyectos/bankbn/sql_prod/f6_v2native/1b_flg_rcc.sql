-- =====================================================================================
-- PO_1_flags_rcc.sql | ETAPA 1 de 3  flags RCC de la POBLACION OBJETIVO
--
-- ESCRIBE: crea disc_model_owner.b46029_v2n_flg_rcc_202607
--
-- POR QUE EN ETAPAS
--   La PO son ~4.2M clientes/mes. Todo junto no pasa: correr la logica completa como
--   un solo SELECT murio con INTERNAL_ERROR_QUERY_ENGINE ya con 2,299 altas.
--   El paquete original hace exactamente esto: q2_adv_prog_src (RCC) y q2_sunat_esp_src
--   (maestras) son CTAS separados que q4 despues une. Un CTAS aguanta lo que un SELECT
--   interactivo no  q2_adv_prog_src lee el RCC de 87 meses SIN filtro de cliente.
--
-- ALINEAMIENTO
--   p_codmes  P        mes del score
--   codmes    P + 1    alta potencial  <- el `codmes` de esta tabla
--   RCC       P - 1    = codmes - 2, la foto que el score tenia enfrente
--
-- DEFINICIONES verbatim de q2_adv_prog_src.sql (L27-47 agregados, L72-85 flags).
-- Sin filtro de cliente en el RCC, igual que el original: deja que el motor lo resuelva
-- por particion en vez de armar un semi-join de 4M claves.
--
-- UNA DESVIACION, Y ES NECESARIA: NADA MIRA MAS ALLA DE m0-2
--   El original evalua impulsa y reactiva_puro con lb=0, el RCC del mes del ALTA.
--   Para CALIBRAR eso es correcto  el alta ya ocurrio y su mes es historia.
--   Para la PO no: aqui codmes = p_codmes + 1, asi que lb=0 es el RCC de UN MES
--   DESPUES del score. Ese dato no existe cuando sale la campania: es look-ahead.
--   Se mueven a lb=2, la misma foto que los otros 9 flags.
--   Ademas la lectura se corta en m0-2: ningun flag mira lb=0 ni lb=1, asi que traer
--   esos meses seria arrastrar datos posteriores al score sin siquiera usarlos.
--   Resultado: TODO en esta tabla se decide con informacion de p_codmes - 1 o anterior.
--
-- REEMPLAZAR
--   202206 202607   rango de p_codmes, 'YYYYMM'
--   202105         P_INI menos 14 meses (lookback de novig_12m_m2 = [m0-13, m0-2])
--   Ej: P_INI='202606' P_FIN='202606'  ->  RCC_INI='202504'
--
-- Si ya existe de una corrida previa: DROP TABLE disc_model_owner.b46029_v2n_flg_rcc_202607
-- =====================================================================================
CREATE TABLE disc_model_owner.b46029_v2n_flg_rcc_202607
WITH (format='PARQUET', parquet_compression='SNAPPY') AS

WITH pob AS (
  SELECT cast(date_format(date_parse(p_codmes,'%Y%m') + interval '1' month,'%Y%m') AS varchar) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202401' AND '202607'
  GROUP BY 1,2,3
),
rcc AS (
  SELECT codmes, tip_doc, key_value, cod_clasificacion_deudor, condicion,
         tipo_credito, cod_cuenta_rcc, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202211' AND '202607'
      AND codmes   BETWEEN '202211' AND '202607'
      AND p_codmes >= '201901'
  UNION ALL
  SELECT codmes, tip_doc, key_value, cod_clasificacion_deudor, condicion,
         tipo_credito, cod_cuenta_rcc, saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202211' AND '202607'
      AND codmes   BETWEEN '202211' AND '202607'
      AND p_codmes <= '201812'
),
cm AS (
  SELECT tip_doc, key_value, codmes,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,7,2) not in ('01','04')
              and substr(cod_cuenta_rcc,4,1) in ('3','4','5','6')
         then saldo else 0 end) as saldo_novig_neg,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1) in ('1','3','4','5','6')
              and cod_clasificacion_deudor<>'0' and substr(cod_cuenta_rcc,7,2) not in ('01','04')
         then saldo else 0 end) as sld_no_normal,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,3) in ('302','925')
         then saldo else 0 end) as sld_cast,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1)='6'
         then saldo else 0 end) as sld_jud,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1)='4'
         then saldo else 0 end) as sld_ref,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1)='3'
         then saldo else 0 end) as sld_rest,
    max(case when cast(tipo_credito as int) between 1 and 10
              and ( (substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,7,2) not in ('01','04')
                     and substr(cod_cuenta_rcc,4,1) in ('1','3','4','5','6'))
                 or (substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,3) in ('302','925')) )
         then condicion else 0 end) as dm,
    max(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,7,2) not in ('01','04')
              and substr(cod_cuenta_rcc,4,1) in ('1','3','4','5','6')
              and cod_clasificacion_deudor is not null and cod_clasificacion_deudor not in ('0','')
         then 1 else 0 end) as clasif_nn,
    sum(case when cast(tipo_credito as int) between 1 and 10
              and substr(cod_cuenta_rcc,1,2)='14' and substr(cod_cuenta_rcc,4,1) in ('1','3','4','5','6')
         then saldo else 0 end) as saldo_vig,
    sum(case when substr(cod_cuenta_rcc,1,2)='81' and substr(cod_cuenta_rcc,4,1)='8'
              and substr(cod_cuenta_rcc,6,1) in ('1','3','4','5','6')
         then saldo else 0 end) as sld_reactiva,
    sum(case when regexp_like(cod_cuenta_rcc,'^81.9520[1-9]|^81.95210') and saldo>0
         then saldo else 0 end) as sld_impulsa
  FROM rcc
  GROUP BY tip_doc, key_value, codmes
),
lb AS (
  SELECT a.codmes, a.tip_doc, a.key_value,
    date_diff('month', date_parse(cast(c.codmes as varchar),'%Y%m'),
                       date_parse(a.codmes,'%Y%m')) AS lb,
    c.saldo_novig_neg, c.sld_no_normal, c.sld_cast, c.sld_jud, c.sld_ref, c.sld_rest,
    c.dm, c.clasif_nn, c.saldo_vig, c.sld_reactiva, c.sld_impulsa
  FROM pob a
  LEFT JOIN cm c
    ON c.tip_doc=a.tip_doc AND c.key_value=a.key_value
   -- 14, no 13: impulsa ahora usa lb hasta 14. Y el tope se corta en m0-2, no en m0:
   -- ya no hay ningun flag que mire lb=0 ni lb=1, asi que leer esos meses seria
   -- traer al plan datos posteriores al score sin usarlos.
   AND cast(c.codmes as int) >= cast(date_format(date_parse(a.codmes,'%Y%m')
                                                 - interval '14' month,'%Y%m') as int)
   AND cast(c.codmes as int) <= cast(date_format(date_parse(a.codmes,'%Y%m')
                                                 - interval '2' month,'%Y%m') as int)
)
SELECT codmes, tip_doc, key_value,
  case when max(case when lb=2                then saldo_novig_neg else 0 end)>0 then 1 else 0 end as flg_novig_1m_m2,
  case when max(case when lb between 2 and 13 then saldo_novig_neg else 0 end)>0 then 1 else 0 end as flg_novig_12m_m2,
  case when max(case when lb=2                then sld_no_normal   else 0 end)>0 then 1 else 0 end as flg_clasif_m2,
  case when max(case when lb=2 then sld_cast  else 0 end)>0 then 1 else 0 end as flg_org_castigo_m2,
  case when max(case when lb=2 then sld_jud   else 0 end)>0 then 1 else 0 end as flg_org_jud_m2,
  case when max(case when lb=2 then sld_ref   else 0 end)>0 then 1 else 0 end as flg_org_refin_m2,
  case when max(case when lb=2 then sld_rest  else 0 end)>0 then 1 else 0 end as flg_org_reestr_m2,
  case when max(case when lb=2 then dm        else 0 end)>0 then 1 else 0 end as flg_org_atraso_m2,
  case when max(case when lb=2 then clasif_nn else 0 end)=1 then 1 else 0 end as flg_org_clasif_m2,
  -- IMPULSA y REACTIVA a m0-2, NO a m0.
  -- En el original (q2_adv_prog_src) estos usan lb=0, o sea el RCC del mes del ALTA.
  -- En calibracion eso es legitimo: el alta ya ocurrio y su mes es historia.
  -- AQUI NO. Para la PO, codmes = p_codmes + 1, asi que lb=0 seria el RCC de UN MES
  -- DESPUES del score  dato que no existe cuando sale la campania. Es look-ahead.
  -- Se mueven a la misma foto que el resto: lb=2 = p_codmes - 1.
  --   impulsa:  [0,12] -> [2,14]   mismos 13 meses, terminando en m0-2
  --   reactiva:  lb=0  -> lb=2
  case when max(case when lb between 2 and 14 then sld_impulsa else 0 end)>0
       then 1 else 0 end as flg_impulsa_bwd,
  case when max(case when lb=2 then sld_reactiva else 0 end)>0
        and max(case when lb=2 then saldo_vig    else 0 end)
         <= max(case when lb=2 then sld_reactiva else 0 end)
       then 1 else 0 end as flg_reactiva_puro
FROM lb
GROUP BY codmes, tip_doc, key_value
