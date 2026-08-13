-- ============================================================================
-- 15. CUENTA SUELDO
--   scan: e_perm_aws.t_rsk_cta_sueldo en codmes-1
--   ancla: k=-1 como en el build de reenganche. La fuente lista a TODOS con flag 0/1
--          (medido: 4.43M unos contra 5.07M ceros en 2024), asi que la ausencia de
--          fila es HUECO y no un cero: el eje sale con tres valores y flg_cs_v2
--          replica la semantica del nodo, que funde hueco con cero
--   tipdoc se normaliza con doble cast como en reenganche: 01 y 1 son el mismo tipo
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_15_cta_sueldo AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value,
           date_format(date_add('month', -1, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m01
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
s AS (
    SELECT CAST(a.codmes AS VARCHAR)                                                    AS codmes,
           CAST(a.key_value AS VARCHAR)                                                 AS id_value,
           CAST(CAST(a.tipdoc AS INTEGER) AS VARCHAR)                                   AS tip_doc,
           max(TRY_CAST(a.flg_cs_riesgos AS INTEGER))                                   AS flg_cs
    FROM e_perm_aws.t_rsk_cta_sueldo a
    INNER JOIN (SELECT DISTINCT id_value, tip_doc FROM po) k
            ON k.id_value = CAST(a.key_value AS VARCHAR)
           AND k.tip_doc  = CAST(CAST(a.tipdoc AS INTEGER) AS VARCHAR)
    GROUP BY CAST(a.codmes AS VARCHAR), CAST(a.key_value AS VARCHAR),
             CAST(CAST(a.tipdoc AS INTEGER) AS VARCHAR)
)
SELECT p.tip_doc,
       p.id_value,
       CAST(coalesce(s.flg_cs, 0) AS INTEGER)                                           AS flg_cs_v2,
       CASE WHEN s.flg_cs IS NULL THEN 'SIN_DATO'
            WHEN s.flg_cs = 1     THEN 'CS'
            ELSE                       'NO_CS' END                                      AS flg_cs_estado,
       CAST(CASE WHEN s.flg_cs IS NULL THEN 1 ELSE 0 END AS INTEGER)                    AS ctrl_sin_cta_sueldo,
       p.codmes_mrm
FROM po p
LEFT JOIN s ON s.id_value = p.id_value AND s.tip_doc = p.tip_doc AND s.codmes = p.m01
