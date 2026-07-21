-- =====================================================================================
-- PO_2_SMOKE.sql | prueba de PO_2 sobre UN MES, solo lectura, salida agregada
--
-- POR QUE EXISTE
--   PO_2 nunca se ha ejecutado, y ademas le hice 11 reemplazos quirurgicos para llevar
--   los cortes de fecha a m0-2. Tracé la propagacion de codmes_ref leyendo, pero leer
--   no es ejecutar: la resolucion de nombres entre subconsultas anidadas es justo donde
--   se esconden los errores. Esto lo prueba antes de gastar un CTAS de 30 meses.
--
-- p_codmes = 202606  ->  codmes = 202607  ·  codmes_ref = 202605
--
-- QUE MIRAR
--   1. que CORRA. Si codmes_ref no resuelve en alguna CTE, revienta aqui.
--   2. codmes_ref debe salir 202605 = p_codmes - 1. Si sale 202607, el parche no
--      se aplico y sigue habiendo look-ahead.
--   3. tasas plausibles. En ALTAS (F1, 2.299 casos) fueron:
--        giro 9.4% · edad_rl 4.0% · rrll_castigo 3.0% · pnsn 0.2% · esp_tit 0.5%
--      La PO es poblacion sin filtrar, asi que se esperan tasas distintas — pero no
--      cero en todo ni 100% en algo.
--   4. cuanto tarda un mes, para dimensionar los 30.
--
-- Una fila, 12 columnas, sin identificadores.
-- READ-ONLY: no crea nada.
-- =====================================================================================

WITH pob AS (
  SELECT cast(date_format(date_parse(p_codmes,'%Y%m') + interval '1' month,'%Y%m') AS varchar) AS codmes,
         -- codmes_ref = p_codmes - 1 = codmes - 2. TODOS los cortes de fecha usan esta,
         -- no `codmes`: en la PO el mes del alta es futuro respecto del score.
         cast(date_format(date_parse(p_codmes,'%Y%m') - interval '1' month,'%Y%m') AS varchar) AS codmes_ref,
         cast(tip_doc AS varchar) AS tip_doc, key_value
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202606' AND '202606'
  GROUP BY 1,2,3
),

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
       <= cast(b.codmes_ref as int)
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

-- RCC del REP LEGAL. NO puede reutilizar rcc_raw: ese esta filtrado a los key_value de
-- la poblacion, y el representante legal es OTRA persona (nrodoc_rl). Lleva su propia
-- lectura, filtrada a los documentos de los rep legales — igual de podada.
rcc_rl_raw AS (
  SELECT codmes, tip_doc, key_value, cod_cuenta_rcc, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202505' AND '202606'
      AND codmes   BETWEEN '202505' AND '202606'
      AND p_codmes >= '201901'
      AND substr(cod_cuenta_rcc,1,2) = '81'          -- solo castigo: 81.302 / 81.925
      AND key_value IN (SELECT nrodoc_rl FROM uni_rl)
  UNION ALL
  SELECT codmes, tip_doc, key_value, cod_cuenta_rcc, saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202505' AND '202606'
      AND codmes   BETWEEN '202505' AND '202606'
      AND p_codmes <= '201812'
      AND substr(cod_cuenta_rcc,1,2) = '81'
      AND key_value IN (SELECT nrodoc_rl FROM uni_rl)
),
fea_rcc_rl AS (
  SELECT b.codmes, a.nrodoc_rl, a.tipdoc_rl,
         sum(case when (substr(b.cod_cuenta_rcc,1,2)='81' and substr(b.cod_cuenta_rcc,4,3)='302')
                    or (substr(b.cod_cuenta_rcc,1,2)='81' and substr(b.cod_cuenta_rcc,4,3)='925')
                  then b.saldo else null end) AS sld_castigado
  FROM uni_rl a
  INNER JOIN rcc_rl_raw b
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
        SELECT DISTINCT X.codmes,X.codmes_ref,X.tip_doc,X.key_value,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes_ref as integer)) THEN 'SIN_DATO' ELSE Y.tipcontribuyente    END) AS TPOEMP,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes_ref as integer)) THEN 'SIN_DATO' ELSE Y.estadocontribuyente END) AS ESTADO,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes_ref as integer)) THEN NULL       ELSE Y.fecbaja             END) AS FECBAJA,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes_ref as integer)) THEN 'SIN_DATO' ELSE Y.UBIGEO              END) AS UBIGEO,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes_ref as integer)) THEN ''         ELSE Y.fecalta2            END) AS fecalta2,
          (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes_ref as integer)) THEN 'SIN_DATO' ELSE Y.CIIU                END) AS CIIU
        FROM (SELECT codmes,codmes_ref,tip_doc,key_value FROM pob GROUP BY 1,2,3,4) X
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
    SELECT b.codmes, b.codmes_ref, b.tip_doc, b.key_value, b.tpoemp, b.estado, b.fecbaja, b.ciiu,
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
          and (J.FECBAJA is null or cast(date_format(J.FECBAJA,'%Y%m') as int) <= cast(J.codmes_ref as int))
         then 1 else 0 end AS flg_estado_ruc,
    case when J.Giro_restringido=1 then 1 else 0 end AS flg_giro,
    case when (COALESCE(CAST(SUBSTRING(A.codmes_ref,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM D.fec_nacimiento) as int), 30) <= 25)
           OR (COALESCE(CAST(SUBSTRING(A.codmes_ref,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM D.fec_nacimiento) as int), 30) >= 75)
         then 1 else 0 end AS flg_edad_tit,
    case when (COALESCE(CAST(SUBSTRING(A.codmes_ref,1,4) AS INT)
                        - cast(EXTRACT(YEAR FROM F.fec_nacimiento_rl_max) as int), 30) <= 25)
           OR (COALESCE(CAST(SUBSTRING(A.codmes_ref,1,4) AS INT)
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
   AND A.codmes_ref < B.considerar_hasta AND A.codmes_ref >= B.codmes_ingreso
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
   AND A.codmes_ref < C.considerar_hasta AND A.codmes_ref >= C.codmes_ingreso
  WHERE A.tip_doc <> '2'
  GROUP BY 1,2,3
)

SELECT
  min(p.codmes)      AS codmes,
  min(p.codmes_ref)  AS codmes_ref,
  count(*)                                    AS n_clientes,
  sum(coalesce(m.flg_pnsn,0))                 AS pnsn,
  sum(coalesce(m.flg_estado_ruc,0))           AS estado_ruc,
  sum(coalesce(m.flg_giro,0))                 AS giro,
  sum(coalesce(m.flg_edad_tit,0))             AS edad_tit,
  sum(coalesce(m.flg_edad_rl,0))              AS edad_rl,
  sum(coalesce(m.flg_rrll_castigo_m2,0))      AS rrll_castigo,
  sum(coalesce(t.flg_esp_tit,0))              AS esp_tit,
  sum(coalesce(y.flg_esp_cny,0))              AS esp_cny,
  count_if(coalesce(m.flg_pnsn,0)+coalesce(m.flg_estado_ruc,0)+coalesce(m.flg_giro,0)
          +coalesce(m.flg_edad_tit,0)+coalesce(m.flg_edad_rl,0)
          +coalesce(m.flg_rrll_castigo_m2,0)+coalesce(t.flg_esp_tit,0)
          +coalesce(y.flg_esp_cny,0) >= 1)    AS con_algun_ko
FROM pob p
LEFT JOIN flag_bpe m ON m.codmes=p.codmes AND m.tip_doc=p.tip_doc AND m.key_value=p.key_value
LEFT JOIN esp_tit  t ON t.codmes=p.codmes AND t.tip_doc=p.tip_doc AND t.key_value=p.key_value
LEFT JOIN esp_cny  y ON y.codmes=p.codmes AND y.tip_doc=p.tip_doc AND y.key_value=p.key_value
