-- c7 | Que fuente explica la caida de DEP entre codmes_drv 202604 y 202605.
--      Solo las filas que la regla ve como DEPENDIENTE en sit_lab: ahi es donde
--      la lista negra de fuente decide DEP contra NO DEP. Sobre las llaves del
--      stock, no sobre la fuente entera
WITH po AS (
  SELECT DISTINCT
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_drv,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR)   AS id_value
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202604' AND '202607'
    AND pd_comppp_reen_itc IS NOT NULL
),
r AS (
  SELECT CAST(a.periodo AS VARCHAR) AS codmes_drv,
         a.sit_lab,
         a.fuente,
         ROW_NUMBER() OVER (
           PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
           ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
  INNER JOIN po b
    ON CAST(a.periodo AS VARCHAR) = b.codmes_drv
   AND SUBSTR(a.subject_id, 3)    = b.id_value
   AND CAST(a.tip_doc AS VARCHAR) = b.tip_doc
  WHERE CAST(a.numcarga AS INT) = 1
)
SELECT codmes_drv,
       fuente,
       CASE WHEN fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
            THEN 'degrada a MIXTO' ELSE 'queda DEP' END AS efecto,
       COUNT(*)                                                          AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY codmes_drv), 2) AS pct_de_dependientes
FROM r
WHERE rn = 1
  AND sit_lab = 'DEPENDIENTE'
GROUP BY codmes_drv, fuente
ORDER BY codmes_drv, n DESC
