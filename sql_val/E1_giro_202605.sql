-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : E_giro/E1_giro_202605.sql
--   origen  : ~\mcp-runner\sql\E1_giro_202605_detalle.sql
--   sha256  : dd06cbceb292   (del cuerpo, sin este encabezado)
--   estado  : VERDE
-- =====================================================================================
-- =====================================================================================
-- E1 | GIRO RESTRINGIDO — detalle por cliente, cohorte 202605
--
-- Devuelve key_value + CIIU + la etiqueta de la maestra, para los que caen por giro.
--
-- IMPORTANTE PARA RESPONDER "¿como definen Restringido?"
--   No lo define el modelo. `flag_aceptanuevos` es un campo ESCRITO en
--   e_perm_aws.t_mst_bpe_giros_restringidos, propiedad de negocio/campanias.
--   El modelo solo cruza el CIIU de SUNAT contra esa maestra y aplica:
--       'Restringido' -> 1     'Atendido' -> 0     cualquier otra cosa / sin match -> -1
--       flg_giro = 1 SOLO si Giro_restringido = 1   (el -1 pasa como NO restringido)
--
-- OJO CON EL CONTEO
--   Este query da flg_giro AISLADO. El "motivo" de la cascada da menos, porque giro es
--   prioridad '22' y queda tapado por 09/17/18/19/20 si alguno de esos tambien cae.
--   Para comparar contra el reporte de rechazos, mirar la columna `tapado_por_cascada`.
--
-- READ-ONLY. Cambiar 202605 si quieres otra cohorte.
-- =====================================================================================

WITH pob AS (
  SELECT cast(codmes AS varchar) AS codmes, tip_doc, key_value
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes = '202605'
    AND cast(codmes AS int) = 202605
    AND cod_instit_financiera = '00002'          -- altas IBK
  GROUP BY 1,2,3
),

-- CIIU de SUNAT con corte PIT (fecalta > codmes -> 'SIN_DATO'), rank verbatim del original
sunat AS (
  SELECT codmes, tip_doc, key_value, CIIU, ESTADO, TPOEMP
  FROM (
    SELECT a.*,
           RANK() OVER(PARTITION BY codmes,tip_doc,key_value
                       ORDER BY codmes,tip_doc,key_value, CL_ESTADO_num asc, fecalta2 desc) AS num
    FROM (
      SELECT DISTINCT X.codmes,X.tip_doc,X.key_value,
        (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.CIIU END) AS CIIU,
        (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.estadocontribuyente END) AS ESTADO,
        (CASE WHEN (CAST(SUBSTR(Y.fecalta2,1,6) AS INTEGER)>cast(X.codmes as integer)) THEN 'SIN_DATO' ELSE Y.tipcontribuyente END) AS TPOEMP,
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
  SELECT p.codmes, p.tip_doc, p.key_value,
         coalesce(s.CIIU,'SIN_MATCH_SUNAT')       AS ciiu,
         coalesce(g.flag_aceptanuevos,'SIN_MATCH_MAESTRA') AS etiqueta_maestra,
         CASE WHEN g.flag_aceptanuevos='Restringido' THEN 1
              WHEN g.flag_aceptanuevos='Atendido'    THEN 0
              ELSE -1 END                          AS giro_restringido_3v,
         CASE WHEN g.flag_aceptanuevos='Restringido' THEN 1 ELSE 0 END AS flg_giro,
         -- ¿habria quedado tapado en la cascada por un motivo de mayor prioridad?
         CASE WHEN coalesce(s.TPOEMP,'') = '01' THEN '19. PNSN'
              WHEN coalesce(s.ESTADO,'') NOT IN ('00','03','SIN_DATO') THEN '20. estado RUC'
              ELSE '' END                          AS tapado_por_cascada
  FROM pob p
  LEFT JOIN sunat s ON s.codmes=p.codmes AND s.tip_doc=p.tip_doc AND s.key_value=p.key_value
  LEFT JOIN giros g ON g.codigoacteconomica = s.CIIU
)

-- ============ detalle cliente a cliente de los que caen por giro ============
SELECT codmes, tip_doc, key_value, ciiu, etiqueta_maestra, tapado_por_cascada
FROM det
WHERE flg_giro = 1
ORDER BY ciiu, key_value
