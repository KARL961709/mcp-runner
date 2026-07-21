-- =====================================================================================
-- E5 | ¿QUE TAN DISTINTOS SON `ciiu` y `ciiufinal`? + ¿que revision usa la maestra?
--
-- Cierra la unica pregunta abierta: cual de los dos campos de SUNAT hay que cruzar
-- contra e_perm_aws.t_mst_bpe_giros_restringidos.
--
-- Los tres bloques responden cosas distintas:
--   1. MAESTRA   en que `revision` esta codificada y de que fecha es el corte.
--                Es el dato que DECIDE. Si dice Rev.4 y `ciiu` es Rev.3, cruzamos mal.
--   2. CAMPOS    cuanto difieren en la poblacion real: iguales, distintos, vacios,
--                y la LONGITUD de cada uno (una difiere en digitos = codificacion distinta).
--   3. PARES     los 20 pares (ciiu -> ciiufinal) mas frecuentes donde discrepan,
--                con la etiqueta que recibe cada uno. Si es un mapeo de revision se
--                vera como patron; si es ruido, no.
--
-- Poblacion: altas IBK 202603-202605 (misma que E2/E3, comparable).
-- READ-ONLY.
-- =====================================================================================

WITH pob AS (
  SELECT cast(codmes AS varchar) AS codmes, tip_doc, key_value
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202603' AND '202605'
    AND cast(codmes AS int) BETWEEN 202603 AND 202605
    AND cod_instit_financiera = '00002'
  GROUP BY 1,2,3
),

sunat AS (
  SELECT codmes, tip_doc, key_value, CIIU, CIIUFINAL
  FROM (
    SELECT a.*,
           RANK() OVER(PARTITION BY codmes,tip_doc,key_value
                       ORDER BY codmes,tip_doc,key_value, CL_ESTADO_num asc, fecalta2 desc) AS num
    FROM (
      SELECT DISTINCT X.codmes,X.tip_doc,X.key_value,
        (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.CIIU      END) AS CIIU,
        (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.CIIUFINAL END) AS CIIUFINAL,
        (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN '' ELSE Y.fecalta2 END) AS fecalta2,
        (CASE WHEN Y.estadocontribuyente IN ('00') THEN 1 ELSE 0 END) AS CL_ESTADO_num
      FROM (SELECT codmes,tip_doc,key_value FROM pob GROUP BY 1,2,3) X
      LEFT JOIN (
        SELECT X.*,
               (CASE WHEN X.flg_ruc IN (10,15,17) THEN '1' ELSE '2' END) AS TIPDOC,
               (CASE WHEN X.flg_ruc IN (10,15,17) THEN Y.key_value ELSE X.ruc_value END) AS NRODOC
        FROM (SELECT a.*, cast(extract(year from a.fecalta)*10000
                            + extract(month from a.fecalta)*100
                            + extract(day from a.fecalta) as varchar(8)) as fecalta2
              FROM e_perm_aws.t_mst_princ_sunat_rsk a) X
        LEFT JOIN (
          SELECT *, RANK() OVER (PARTITION BY tip_doc, key_value
                                 ORDER BY fecproceso, fecinicio, estadoregistro, ruc_value DESC) AS num
          FROM e_perm_aws.t_mst_sec_sunat_rsk) Y
          ON X.ruc_value=Y.ruc_value AND Y.num=1
        WHERE X.fecalta2<>'') Y
        ON (X.tip_doc=Y.TIPDOC AND X.key_value=Y.NRODOC)
    ) a
  ) a
  WHERE a.num = 1
),

giros AS (
  SELECT codigoacteconomica, max(flag_aceptanuevos) AS flag_aceptanuevos
  FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1
),

s AS (
  SELECT p.codmes, p.tip_doc, p.key_value,
         trim(coalesce(u.CIIU,''))      AS c1,
         trim(coalesce(u.CIIUFINAL,'')) AS c2
  FROM pob p
  LEFT JOIN sunat u ON u.codmes=p.codmes AND u.tip_doc=p.tip_doc AND u.key_value=p.key_value
)

-- ============================= 1. LA MAESTRA =============================
SELECT '1. MAESTRA revision' AS bloque,
       coalesce(revision,'(null)') AS detalle,
       cast(count(*) AS varchar) AS valor
FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1,2

UNION ALL
SELECT '1. MAESTRA fecha', coalesce(fecinformacion,'(null)'), cast(count(*) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1,2

UNION ALL
SELECT '1. MAESTRA long codigo',
       cast(length(trim(codigoacteconomica)) AS varchar) || ' digitos',
       cast(count(*) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1,2

-- ============================= 2. LOS CAMPOS =============================
UNION ALL
SELECT '2. CAMPOS', 'total clientes',                      cast(count(*) AS varchar) FROM s
UNION ALL
SELECT '2. CAMPOS', 'ciiu = ciiufinal (identicos)',        cast(count_if(c1=c2 AND c1<>'') AS varchar) FROM s
UNION ALL
SELECT '2. CAMPOS', 'DIFIEREN (ambos con valor)',          cast(count_if(c1<>c2 AND c1<>'' AND c2<>'') AS varchar) FROM s
UNION ALL
SELECT '2. CAMPOS', 'ciiu vacio / ciiufinal con valor',    cast(count_if(c1='' AND c2<>'') AS varchar) FROM s
UNION ALL
SELECT '2. CAMPOS', 'ciiufinal vacio / ciiu con valor',    cast(count_if(c2='' AND c1<>'') AS varchar) FROM s
UNION ALL
SELECT '2. CAMPOS', 'ambos vacios',                        cast(count_if(c1='' AND c2='') AS varchar) FROM s

UNION ALL
SELECT '2b. LONG ciiu', cast(length(c1) AS varchar) || ' digitos', cast(count(*) AS varchar)
FROM s WHERE c1<>'' GROUP BY 1,2
UNION ALL
SELECT '2b. LONG ciiufinal', cast(length(c2) AS varchar) || ' digitos', cast(count(*) AS varchar)
FROM s WHERE c2<>'' GROUP BY 1,2

-- ============ 3. PARES EN DESACUERDO — ¿patron o ruido? ============
UNION ALL
SELECT '3. PAR ' || c1 || ' -> ' || c2,
       coalesce(g1.flag_aceptanuevos,'sin match') || ' -> ' || coalesce(g2.flag_aceptanuevos,'sin match'),
       cast(n AS varchar)
FROM (
  SELECT c1, c2, count(*) AS n
  FROM s WHERE c1<>c2 AND c1<>'' AND c2<>''
  GROUP BY 1,2 ORDER BY 3 DESC LIMIT 20
) t
LEFT JOIN giros g1 ON g1.codigoacteconomica = t.c1
LEFT JOIN giros g2 ON g2.codigoacteconomica = t.c2
ORDER BY 1,2
