-- =====================================================================================
-- PASO 2 | FLAGS DESDE FUENTES MADRE
--
-- Este archivo sirve para las DOS corridas. Cambia solo 2 cosas:
--
--   SMOKE (correr PRIMERO, es lectura, 3 cohortes)
--       dejarlo tal cual. Devuelve filas, no crea nada.
--
--   FULL  (solo si el SMOKE corre bien y barato)
--       (A) linea marcada  ->  BETWEEN 202207 AND 202604
--       (B) linea marcada  ->  BETWEEN '202106' AND '202604'
--       (C) descomentar el CREATE TABLE de abajo
--       Si ya existe de un intento previo:
--           DROP TABLE disc_model_owner.b46029_flags_madre
--       ESCRIBE una tabla NUEVA en tu namespace. No toca nada congelado del paquete.
-- =====================================================================================
-- (C) FULL: descomentar estas 2 lineas
-- CREATE TABLE disc_model_owner.b46029_flags_madre
-- WITH (format='PARQUET', parquet_compression='SNAPPY') AS

-- =====================================================================================
-- FLAGS_DESDE_MADRE.sql | flg_clean calculado 100% desde FUENTES MADRE
--
-- Porta la logica de q2_adv_prog_src.sql (RCC) + q2_sunat_esp_src.sql (maestras) y las
-- combina con la regla flg_calib_m2 de q4_maestro_calib_src.sql, SIN leer ninguna tabla
-- derivada (no bnbpe_ibk_calib_src, no bnbpe_ibk_altas_src, no perim_*, no rcc_agg).
--
-- USO
--   Reemplazar SOLO estos tres:
--     {POBLACION}  tabla/subquery con (codmes VARCHAR 'YYYYMM', tip_doc, key_value)
--                  codmes = MES DEL ALTA (m0)
--     {RCC_INI}    codmes minimo de la poblacion MENOS 13 meses  ('YYYYMM')
--                  (13 = lookback maximo: ventana novig_12m_m2 = [m0-13, m0-2])
--     {M_FIN}      codmes maximo de la poblacion                 ('YYYYMM')
--   Ambos podan la particion del RCC. Ej: poblacion 202601-202607 -> RCC_INI='202412', M_FIN='202607'
--
-- FUENTES MADRE usadas (todas maestras/hechos, ninguna derivada):
--   e_perm_aws.t_fact_report_rcc_rsk        RCC (p_codmes >= 201901)
--   d_perm_aws.t_fact_report_rcc_rsk        RCC historico (p_codmes <= 201812)
--   e_perm_aws.t_mst_princ_sunat_rsk        SUNAT principal
--   e_perm_aws.t_mst_sec_sunat_rsk          SUNAT secundaria
--   e_perm_aws.t_mst_bpe_giros_restringidos giros BPE
--   e_perm_aws.t_mst_reniec_rsk             RENIEC (titular, conyuge, rep legal)
--   e_perm_aws.t_mst_rep_legal_sunat_rsk    rep legal SUNAT
--   e_perm_aws.T_REL_VPC_MYP_CLIENTENEGATIVO    VPC historica
--   e_perm_aws.T_MST_VPC_MYP_CLIENTE_ACTUAL     VPC cliente actual
--
-- =====================================================================================
-- ⚠ TRES DESVIACIONES DELIBERADAS respecto de flg_calib_m2, TODAS por implementabilidad
-- =====================================================================================
--  1) flg_monto  NO se incluye.  Depende de saldo_m0/max_saldo del ALTA (q1_altas_src L36).
--     Antes del desembolso no existe. En la calibracion filtra monto>=30k (o 10-30k con
--     max_saldo>=30k). Si tu poblacion son ALTAS y tienes el monto, agregalo al AND final.
--
--  2) flg_impulsa  se calcula BACKWARD-ONLY.  El original (q2_adv_prog_src L81) usa
--     lb BETWEEN -12 AND 0, y lb = m0 - codmes_rcc, o sea mira 12 meses HACIA ADELANTE
--     del alta. Es correcto para EXCLUIR la era Impulsa de un ajuste retrospectivo, pero
--     NO es implementable ex-ante. Aqui: lb BETWEEN 0 AND 12 (12 meses previos).
--     => flg_impulsa_bwd <= flg_impulsa original. Sub-detecta. Documentado, no oculto.
--
--  3) flg_ubigeo  se calcula pero NO entra al AND (LIBERADO, decision 2026-07-02,
--     igual que en q4_maestro_calib_src.sql).
--
-- =====================================================================================
-- SALIDA: 1 fila por (codmes, tip_doc, key_value) con los 19 flags + flg_clean
-- =====================================================================================

WITH
pob AS (
  SELECT cast(codmes AS varchar) AS codmes, cast(tip_doc AS varchar) AS tip_doc, key_value
  FROM (SELECT cast(codmes AS varchar) AS codmes, tip_doc, key_value
   FROM disc_model_owner.bnbpe_ibk_altas_src
   WHERE top4_entidad='TOP4'
     AND cast(codmes AS int) BETWEEN 202602 AND 202604)   -- <<< (A) SMOKE. Para FULL: 202207 AND 202604
  GROUP BY 1,2,3
),

-- =====================================================================================
-- BLOQUE A — RCC crudo (port de q2_adv_prog_src.sql)
-- =====================================================================================
rcc_raw AS (
  SELECT codmes, tip_doc, key_value, cod_clasificacion_deudor, condicion,
         tipo_credito, cod_cuenta_rcc, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202501' AND '202604'   -- <<< (B) SMOKE. Para FULL: '202106' AND '202604'
      AND codmes   BETWEEN '202501' AND '202604'   -- <<< (B) SMOKE. Para FULL: '202106' AND '202604'
      AND p_codmes >= '201901'
  UNION ALL
  SELECT codmes, tip_doc, key_value, cod_clasificacion_deudor, condicion,
         tipo_credito, cod_cuenta_rcc, saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202501' AND '202604'   -- <<< (B) SMOKE. Para FULL: '202106' AND '202604'
      AND codmes   BETWEEN '202501' AND '202604'   -- <<< (B) SMOKE. Para FULL: '202106' AND '202604'
      AND p_codmes <= '201812'
),

-- agregados por cliente-mes. Definiciones VERBATIM de q2_adv_prog_src L27-47.
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
  FROM rcc_raw
  GROUP BY tip_doc, key_value, codmes
),

-- lb = m0 - codmes_rcc.  SOLO BACKWARD (lb >= 0): ver desviacion 2 de la cabecera.
lb AS (
  SELECT a.codmes, a.tip_doc, a.key_value,
    date_diff('month', date_parse(cast(c.codmes as varchar),'%Y%m'),
                       date_parse(a.codmes,'%Y%m')) AS lb,
    c.saldo_novig_neg, c.sld_no_normal, c.sld_cast, c.sld_jud, c.sld_ref, c.sld_rest,
    c.dm, c.clasif_nn, c.saldo_vig, c.sld_reactiva, c.sld_impulsa
  FROM pob a
  LEFT JOIN cm c
    ON c.tip_doc=a.tip_doc AND c.key_value=a.key_value
   AND cast(c.codmes as int) >= cast(date_format(date_parse(a.codmes,'%Y%m')
                                                 - interval '13' month,'%Y%m') as int)
   AND cast(c.codmes as int) <= cast(a.codmes as int)
),

flg_rcc AS (
  SELECT codmes, tip_doc, key_value,
    -- perimetro @ m0-2
    case when max(case when lb=2                then saldo_novig_neg else 0 end)>0 then 1 else 0 end as flg_novig_1m_m2,
    case when max(case when lb between 2 and 13 then saldo_novig_neg else 0 end)>0 then 1 else 0 end as flg_novig_12m_m2,
    case when max(case when lb=2                then sld_no_normal   else 0 end)>0 then 1 else 0 end as flg_clasif_m2,
    -- origen @ m0-2
    case when max(case when lb=2 then sld_cast  else 0 end)>0 then 1 else 0 end as flg_org_castigo_m2,
    case when max(case when lb=2 then sld_jud   else 0 end)>0 then 1 else 0 end as flg_org_jud_m2,
    case when max(case when lb=2 then sld_ref   else 0 end)>0 then 1 else 0 end as flg_org_refin_m2,
    case when max(case when lb=2 then sld_rest  else 0 end)>0 then 1 else 0 end as flg_org_reestr_m2,
    case when max(case when lb=2 then dm        else 0 end)>0 then 1 else 0 end as flg_org_atraso_m2,
    case when max(case when lb=2 then clasif_nn else 0 end)=1 then 1 else 0 end as flg_org_clasif_m2,
    -- programas
    case when max(case when lb between 0 and 12 then sld_impulsa else 0 end)>0
         then 1 else 0 end as flg_impulsa_bwd,
    case when max(case when lb=0 then sld_reactiva else 0 end)>0
          and max(case when lb=0 then saldo_vig    else 0 end)
           <= max(case when lb=0 then sld_reactiva else 0 end)
         then 1 else 0 end as flg_reactiva_puro
  FROM lb
  GROUP BY codmes, tip_doc, key_value
),

-- =====================================================================================
-- BLOQUE B — maestras (port de q2_sunat_esp_src.sql)
-- =====================================================================================
uni_conyuge AS (
  SELECT a.codmes, a.key_value, a.tip_doc, b.tipdoc_conyugue, b.coddoc_conyugue,
         b.fec_nacimiento AS fec_nacimiento
  FROM (SELECT codmes, tip_doc, key_value FROM pob WHERE tip_doc!='2') a
  LEFT JOIN e_perm_aws.t_mst_reniec_rsk b
    ON a.key_value=b.key_value AND a.tip_doc=b.tip_doc
),

uni_rl AS (
  SELECT b.codmes, b.key_value, b.tip_doc, a.key_value AS nrodoc_rl, a.tip_doc AS tipdoc_rl
  FROM e_perm_aws.t_mst_rep_legal_sunat_rsk a
  INNER JOIN pob b
    ON a.ruc_value=b.key_value
   AND cast(date_format(date_parse(cast(a.fec_vigencia as varchar),'%Y-%m-%d'),'%Y%m') as int)
       <= cast(b.codmes as int)
  GROUP BY b.codmes, b.key_value, b.tip_doc, a.key_value, a.tip_doc
),

nacimiento_rl AS (
  SELECT a.codmes, a.key_value, a.tip_doc,
         min(c.fec_nacimiento) AS fec_nacimiento_rl_min,
         max(c.fec_nacimiento) AS fec_nacimiento_rl_max
  FROM uni_rl a
  LEFT JOIN e_perm_aws.t_mst_reniec_rsk c
    ON a.nrodoc_rl=c.key_value AND a.tipdoc_rl=c.tip_doc
  GROUP BY 1,2,3
),

-- RCC del rep legal, reutiliza rcc_raw (misma ventana podada). Castigo 81.302 / 81.925.
fea_rcc_rl AS (
  SELECT b.codmes, a.nrodoc_rl, a.tipdoc_rl,
         sum(case when (substr(b.cod_cuenta_rcc,1,2)='81' and substr(b.cod_cuenta_rcc,4,3)='302')
                    or (substr(b.cod_cuenta_rcc,1,2)='81' and substr(b.cod_cuenta_rcc,4,3)='925')
                  then b.saldo else null end) AS sld_castigado
  FROM uni_rl a
  INNER JOIN rcc_raw b
    ON a.nrodoc_rl=b.key_value AND a.tipdoc_rl=b.tip_doc
  GROUP BY b.codmes, a.nrodoc_rl, a.tipdoc_rl
),

-- ventana RRLL castigo [m0-13, m0-2]  (q2_sunat_esp_src L95-97)
rcc_rl AS (
  SELECT A.codmes, A.tipdoc_rl, A.nrodoc_rl,
         sum(case when date_format(date_parse(a.codmes,'%Y%m') - interval '13' month,'%Y%m')<=b.codmes
                   and date_format(date_parse(a.codmes,'%Y%m') - interval '2'  month,'%Y%m')>=b.codmes
                  then sld_castigado else null end) AS sld_castigado_12um_rl_m2
  FROM uni_rl A
  LEFT JOIN fea_rcc_rl B
    ON a.nrodoc_rl=b.nrodoc_rl AND a.tipdoc_rl=b.tipdoc_rl
  GROUP BY A.codmes, A.nrodoc_rl, A.tipdoc_rl
),
rcc_rl_titular AS (
  SELECT a.codmes, a.tip_doc, a.key_value,
         sum(sld_castigado_12um_rl_m2) AS sld_castigado_12um_rl_m2
  FROM uni_rl a
  LEFT JOIN rcc_rl b
    ON a.codmes=b.codmes AND a.tipdoc_rl=b.tipdoc_rl AND a.nrodoc_rl=b.nrodoc_rl
  GROUP BY a.codmes, a.tip_doc, a.key_value
),

-- SUNAT PIT: fecalta <= codmes (q2_sunat_esp_src L117-173)
filtro_sunat AS (
  SELECT DISTINCT a.*
  FROM (
    SELECT a.*,
           RANK() OVER(PARTITION BY codmes,tip_doc,key_value
                       ORDER BY codmes,tip_doc,key_value, CL_ESTADO_num asc, fecalta2 desc) AS num
    FROM (
      SELECT DISTINCT Y.*,
        (CASE WHEN Y.ESTADO IN ('00') THEN 1 ELSE 0 END) AS CL_ESTADO_num,
        (CASE WHEN Y.ESTADO IN ('00')           THEN 'ACTIVO'
              WHEN Y.ESTADO IN ('01','02')      THEN 'BAJA PROV.'
              WHEN Y.ESTADO IN ('03')           THEN 'SUSPENSION TEMP.'
              WHEN Y.ESTADO IN ('04')           THEN 'ANUL.PROVI.-ACTO ILICITO'
              WHEN Y.ESTADO IN ('10','11','12') THEN 'CASERIO'
              WHEN Y.ESTADO IN ('21')           THEN 'OTROS OBLIG.'
              WHEN Y.ESTADO IN ('22')           THEN 'INHABILITADO'
              WHEN Y.ESTADO IN ('30','31')      THEN 'ANULACION'
              WHEN Y.ESTADO IN ('32')           THEN 'PEND. INI. ACTIV.' ELSE 'MISSING' END) AS CL_ESTADO
      FROM (
        SELECT DISTINCT X.codmes,X.tip_doc,X.key_value,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.tipcontribuyente    END) AS TPOEMP,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.estadocontribuyente END) AS ESTADO,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN NULL       ELSE Y.fecbaja             END) AS FECBAJA,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.UBIGEO              END) AS UBIGEO,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN ''         ELSE Y.fecalta2            END) AS fecalta2,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.CIIU                END) AS CIIU
        FROM (SELECT codmes,tip_doc,key_value FROM pob GROUP BY 1,2,3) X
        LEFT JOIN (
          SELECT X.*,
                 (CASE WHEN X.flg_ruc=10 THEN '1' WHEN X.flg_ruc=15 THEN '1'
                       WHEN X.flg_ruc=17 THEN '1' ELSE '2' END) AS TIPDOC,
                 (CASE WHEN (X.flg_ruc=10 OR X.flg_ruc=15 OR X.flg_ruc=17)
                       THEN Y.key_value ELSE X.ruc_value END) AS NRODOC
          FROM (SELECT a.*, cast(extract(year from a.fecalta)*10000
                             + extract(month from a.fecalta)*100
                             + extract(day from a.fecalta) as varchar(8)) as fecalta2
                FROM e_perm_aws.t_mst_princ_sunat_rsk a) X
          LEFT JOIN (
            SELECT *, RANK() OVER (PARTITION BY tip_doc, key_value
                                   ORDER BY fecproceso, fecinicio, estadoregistro, ruc_value DESC) AS num
            FROM e_perm_aws.t_mst_sec_sunat_rsk) Y
            ON (X.ruc_value=Y.ruc_value) and y.num=1
          WHERE X.fecalta2<>'') Y
          ON (X.tip_doc=Y.TIPDOC AND X.key_value=Y.NRODOC)
      ) Y
    ) a
  ) a
  WHERE a.num = 1
),

filtros_bpe AS (
  SELECT a.*,
         case when c.flag_aceptanuevos='Restringido' then 1
              when c.flag_aceptanuevos='Atendido'    then 0 else -1 end AS Giro_restringido
  FROM (
    SELECT b.codmes, b.tip_doc, b.key_value, b.tpoemp, b.estado, b.fecbaja, b.ciiu,
           b.ubigeo, b.cl_estado
    FROM (SELECT codmes,tip_doc,key_value FROM pob) a
    LEFT JOIN filtro_sunat b
      ON a.codmes=b.codmes AND a.tip_doc=b.tip_doc AND a.key_value=b.key_value
  ) a
  LEFT JOIN (SELECT codigoacteconomica, max(flag_aceptanuevos) AS flag_aceptanuevos
             FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1) c
    ON a.ciiu=c.codigoacteconomica
),

flag_bpe AS (
  SELECT A.codmes, A.tip_doc, A.key_value,
    case when J.tpoemp='01' then 1 else 0 end AS flg_pnsn,
    case when J.ESTADO not in ('00','03')
          and (J.FECBAJA is null or cast(date_format(J.FECBAJA,'%Y%m') as int) <= cast(a.codmes as int))
         then 1 else 0 end AS flg_estado_ruc,
    case when J.Giro_restringido=1 then 1 else 0 end AS flg_giro,
    case when (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM D.fec_nacimiento) as int), 30) <= 25)
           OR (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM D.fec_nacimiento) as int), 30) >= 75)
         then 1 else 0 end AS flg_edad_tit,
    case when (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM F.fec_nacimiento_rl_max) as int), 30) <= 25)
           OR (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM F.fec_nacimiento_rl_min) as int), 30) >= 75)
         then 1 else 0 end AS flg_edad_rl,
    case when B.sld_castigado_12um_rl_m2>0 then 1 else 0 end AS flg_rrll_castigo_m2
  FROM pob A
  LEFT JOIN rcc_rl_titular B ON A.key_value=B.key_value AND A.tip_doc=B.tip_doc AND A.codmes=B.codmes
  LEFT JOIN uni_conyuge     D ON A.key_value=D.key_value AND A.tip_doc=D.tip_doc AND A.codmes=D.codmes
  LEFT JOIN nacimiento_rl   F ON A.key_value=F.key_value AND A.tip_doc=F.tip_doc AND A.codmes=F.codmes
  LEFT JOIN filtros_bpe     J ON A.key_value=J.key_value AND A.tip_doc=J.tip_doc AND A.codmes=J.codmes
),

-- VPC (watchlist) — titular y conyuge
especiales AS (
  SELECT b.cod_tipo_doc_val AS tip_doc, b.num_doc_val AS key_value,
         a.fecha_dt,
         DATE_FORMAT(DATE_TRUNC('MONTH', COALESCE(CAST(
           case when a.fecha_habilita_dt='' then null else substring(a.fecha_habilita_dt,1,10) end AS DATE),
           CURRENT_DATE)), '%Y%m') AS considerar_hasta,
         DATE_FORMAT(DATE_TRUNC('MONTH', CAST(
           case when a.fecha_dt='' then null else substring(a.fecha_dt,1,10) end AS DATE)), '%Y%m') AS codmes_ingreso
  FROM (SELECT cliente_id,fecha_dt,fecha_habilita_dt,cod_tipo_val
        FROM e_perm_aws.T_REL_VPC_MYP_CLIENTENEGATIVO GROUP BY 1,2,3,4) a
  JOIN (SELECT cliente_id,cod_tipo_doc_val,num_doc_val
        FROM e_PERM_AWS.T_MST_VPC_MYP_CLIENTE_ACTUAL GROUP BY 1,2,3) b
    ON a.cliente_id=b.cliente_id
  WHERE a.cod_tipo_val IN ('1','2','3')
),

esp_tit AS (
  SELECT A.codmes, A.tip_doc, A.key_value,
         max(case when B.key_value IS NOT NULL then 1 else 0 end) AS flg_esp_tit
  FROM pob A
  LEFT JOIN especiales B
    ON A.tip_doc=B.tip_doc AND A.key_value=B.key_value
   AND A.codmes < B.considerar_hasta AND A.codmes >= B.codmes_ingreso
  GROUP BY 1,2,3
),

esp_cny AS (
  SELECT A.codmes, A.tip_doc, A.key_value,
         max(case when C.key_value IS NOT NULL then 1 else 0 end) AS flg_esp_cny
  FROM pob A
  INNER JOIN e_perm_aws.t_mst_reniec_rsk R
    ON A.key_value=R.key_value AND CAST(CAST(A.tip_doc AS INT) AS VARCHAR)=R.tip_doc
   AND TRIM(R.tipdoc_conyugue) <> '' AND TRIM(R.coddoc_conyugue) <> ''
  LEFT JOIN especiales C
    ON R.tipdoc_conyugue=C.tip_doc AND R.coddoc_conyugue=C.key_value
   AND A.codmes < C.considerar_hasta AND A.codmes >= C.codmes_ingreso
  WHERE A.tip_doc <> '2'
  GROUP BY 1,2,3
)

-- =====================================================================================
-- SALIDA — 19 flags + flg_clean
-- =====================================================================================
SELECT
  p.codmes, p.tip_doc, p.key_value,
  case when p.tip_doc='2' then 'PJJ' else 'PNN' end AS personeria,

  coalesce(r.flg_novig_1m_m2,0)    AS flg_novig_1m_m2,
  coalesce(r.flg_novig_12m_m2,0)   AS flg_novig_12m_m2,
  coalesce(r.flg_clasif_m2,0)      AS flg_clasif_m2,
  coalesce(r.flg_org_castigo_m2,0) AS flg_org_castigo_m2,
  coalesce(r.flg_org_jud_m2,0)     AS flg_org_jud_m2,
  coalesce(r.flg_org_refin_m2,0)   AS flg_org_refin_m2,
  coalesce(r.flg_org_reestr_m2,0)  AS flg_org_reestr_m2,
  coalesce(r.flg_org_atraso_m2,0)  AS flg_org_atraso_m2,
  coalesce(r.flg_org_clasif_m2,0)  AS flg_org_clasif_m2,
  coalesce(r.flg_impulsa_bwd,0)    AS flg_impulsa_bwd,
  coalesce(r.flg_reactiva_puro,0)  AS flg_reactiva_puro,

  coalesce(m.flg_pnsn,0)           AS flg_pnsn,
  coalesce(m.flg_estado_ruc,0)     AS flg_estado_ruc,
  coalesce(m.flg_giro,0)           AS flg_giro,
  coalesce(m.flg_edad_tit,0)       AS flg_edad_tit,
  coalesce(m.flg_edad_rl,0)        AS flg_edad_rl,
  coalesce(m.flg_rrll_castigo_m2,0) AS flg_rrll_castigo_m2,
  coalesce(t.flg_esp_tit,0)        AS flg_esp_tit,
  coalesce(y.flg_esp_cny,0)        AS flg_esp_cny,

  -- flg_clean = AND de las 19 exclusiones (regla q4_maestro_calib_src.sql flg_calib_m2,
  -- SIN flg_monto y con impulsa backward — ver desviaciones 1 y 2 de la cabecera)
  CASE WHEN coalesce(r.flg_novig_1m_m2,0)=0    AND coalesce(r.flg_novig_12m_m2,0)=0
        AND coalesce(r.flg_clasif_m2,0)=0      AND coalesce(r.flg_org_castigo_m2,0)=0
        AND coalesce(r.flg_org_jud_m2,0)=0     AND coalesce(r.flg_org_refin_m2,0)=0
        AND coalesce(r.flg_org_reestr_m2,0)=0  AND coalesce(r.flg_org_atraso_m2,0)=0
        AND coalesce(r.flg_org_clasif_m2,0)=0
        AND coalesce(r.flg_impulsa_bwd,0)=0    AND coalesce(r.flg_reactiva_puro,0)=0
        AND coalesce(m.flg_pnsn,0)=0           AND coalesce(m.flg_estado_ruc,0)=0
        AND coalesce(m.flg_giro,0)=0           AND coalesce(m.flg_edad_tit,0)=0
        AND coalesce(m.flg_edad_rl,0)=0        AND coalesce(m.flg_rrll_castigo_m2,0)=0
        AND coalesce(t.flg_esp_tit,0)=0        AND coalesce(y.flg_esp_cny,0)=0
       THEN 1 ELSE 0 END AS flg_clean
FROM pob p
LEFT JOIN flg_rcc  r ON r.codmes=p.codmes AND r.tip_doc=p.tip_doc AND r.key_value=p.key_value
LEFT JOIN flag_bpe m ON m.codmes=p.codmes AND m.tip_doc=p.tip_doc AND m.key_value=p.key_value
LEFT JOIN esp_tit  t ON t.codmes=p.codmes AND t.tip_doc=p.tip_doc AND t.key_value=p.key_value
LEFT JOIN esp_cny  y ON y.codmes=p.codmes AND y.tip_doc=p.tip_doc AND y.key_value=p.key_value
