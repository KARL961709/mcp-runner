-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : E_giro/E2_restringidos_3m.sql
--   origen  : ~\mcp-runner\sql\E2_restringidos_3meses.sql
--   sha256  : 819fd6490d03   (del cuerpo, sin este encabezado)
--   estado  : VERDE
-- =====================================================================================
-- =====================================================================================
-- E2 | GIRO RESTRINGIDO — conteo 202603-202605, por las DOS definiciones
--
-- Responde dos cosas de una sola pasada:
--   1) ¿cuantos restringidos hay en los ultimos 3 meses?
--   2) ¿cambia el numero si cruzo por `ciiu` (lo que hacemos) o por `ciiufinal`
--      (lo que hacia el modelamiento original, enviado_1 / target.txt L539)?
--
-- CONTEXTO
--   Misma maestra en ambos: e_perm_aws.t_mst_bpe_giros_restringidos.
--   Lo que cambia es el campo de SUNAT con que se cruza. Nuestra cadena
--   (q2_sunat_esp_src.sql L192) usa `ciiu`, siguiendo enviado_2.
--   Esa divergencia NO esta documentada en LINEAGE_README seccion 13.
--
--   Un cruce que falla cae en -1, y el -1 PASA COMO NO RESTRINGIDO. Por eso importa:
--   si `ciiu` matchea peor que `ciiufinal`, estamos admitiendo de mas.
--
-- COMO LEER
--   ciiu_restr        <- el numero que usa la calibracion HOY  (la respuesta a "cuantos")
--   ciiufinal_restr   <- el que habria dado el modelamiento original
--   solo_ciiufinal    <- restringidos que SE NOS ESCAPAN.  Si es >0, hay fuga.
--   solo_ciiu         <- restringidos de mas por nuestro lado
--   nomatch_*         <- sin cruce contra la maestra (caen a -1 = limpio)
--
-- READ-ONLY.
-- =====================================================================================

WITH pob AS (
  SELECT cast(codmes AS varchar) AS codmes, tip_doc, key_value
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202603' AND '202605'
    AND cast(codmes AS int) BETWEEN 202603 AND 202605
    AND cod_instit_financiera = '00002'          -- altas IBK
  GROUP BY 1,2,3
),

-- SUNAT con corte PIT, arrastrando AMBOS campos de CIIU
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
  FROM e_perm_aws.t_mst_bpe_giros_restringidos
  GROUP BY 1
),

det AS (
  SELECT p.codmes,
         CASE WHEN ga.flag_aceptanuevos='Restringido' THEN 1 ELSE 0 END AS r_ciiu,
         CASE WHEN gb.flag_aceptanuevos='Restringido' THEN 1 ELSE 0 END AS r_ciiufinal,
         CASE WHEN ga.codigoacteconomica IS NULL THEN 1 ELSE 0 END AS nm_ciiu,
         CASE WHEN gb.codigoacteconomica IS NULL THEN 1 ELSE 0 END AS nm_ciiufinal
  FROM pob p
  LEFT JOIN sunat s ON s.codmes=p.codmes AND s.tip_doc=p.tip_doc AND s.key_value=p.key_value
  LEFT JOIN giros ga ON ga.codigoacteconomica = s.CIIU
  LEFT JOIN giros gb ON gb.codigoacteconomica = s.CIIUFINAL
)

SELECT codmes,
       count(*)                                        AS n_altas_ibk,
       sum(r_ciiu)                                     AS ciiu_restr,
       sum(r_ciiufinal)                                AS ciiufinal_restr,
       count_if(r_ciiufinal=1 AND r_ciiu=0)            AS solo_ciiufinal,
       count_if(r_ciiu=1 AND r_ciiufinal=0)            AS solo_ciiu,
       sum(nm_ciiu)                                    AS nomatch_ciiu,
       sum(nm_ciiufinal)                               AS nomatch_ciiufinal
FROM det
GROUP BY codmes

UNION ALL

SELECT 'TOTAL', count(*), sum(r_ciiu), sum(r_ciiufinal),
       count_if(r_ciiufinal=1 AND r_ciiu=0), count_if(r_ciiu=1 AND r_ciiufinal=0),
       sum(nm_ciiu), sum(nm_ciiufinal)
FROM det
ORDER BY 1
