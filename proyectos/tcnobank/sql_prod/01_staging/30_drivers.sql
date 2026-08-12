-- ============================================================================
-- 30. DRIVERS - TIPO DE INGRESO Y ARQUETIPO SALUD
--   scan: ds_rtd_rskvol_cas_ingr_ir en codmes U t_inca_sa en codmes-2 U t_mst_inter_ibk_base_cliente
--   ancla: ingreso k=0. inca k=-2 por tablas.txt. numcarga=1 y ROW_NUMBER de orden total
--   la poblacion entra por INNER JOIN ANTES de cada ventana: sin eso el row_number ordena
--   2,000 millones de filas de la cascada y 1,250 de inca, y Athena agota recursos
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_30_drivers AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value,
           date_format(date_add('month', -2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m02
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
cls AS (
    SELECT codmes_mrm, tip_doc, id_value, sit_lab, fuente, tipo_ingreso
    FROM (
        SELECT b.codmes_mrm,
               b.tip_doc,
               b.id_value,
               a.sit_lab,
               a.fuente,
               CASE WHEN a.sit_lab = 'DEPENDIENTE'
                     AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
                    WHEN a.sit_lab = 'DEPENDIENTE'
                     AND a.fuente     IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
                    WHEN a.sit_lab = 'MIXTO'                                                  THEN 'MIXTO'
                    ELSE 'INDEPENDIENTE' END                                  AS tipo_ingreso,
               row_number() OVER (
                   PARTITION BY b.codmes_mrm, b.tip_doc, b.id_value
                   ORDER BY a.p_fecinformacion DESC, a.subject_id ASC)        AS rn
        FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
        INNER JOIN po b
               ON CAST(a.periodo AS VARCHAR) = b.codmes_mrm
              AND substr(a.subject_id, 3)    = b.id_value
              AND CAST(a.tip_doc AS VARCHAR) = b.tip_doc
        WHERE TRY_CAST(a.numcarga AS INTEGER) = 1
    ) r
    WHERE r.rn = 1
),
mapa AS (
    SELECT tip_doc, id_value, inter_party_id
    FROM (
        SELECT p.tip_doc,
               p.id_value,
               b.inter_party_id,
               row_number() OVER (PARTITION BY p.tip_doc, p.id_value
                                  ORDER BY b.inter_load_date DESC, b.inter_party_id ASC) AS rn
        FROM e_perm_aws.t_mst_inter_ibk_base_cliente b
        INNER JOIN (SELECT DISTINCT tip_doc, id_value FROM po) p
               ON p.tip_doc = b.tip_doc AND p.id_value = b.key_value
    ) x
    WHERE x.rn = 1
),
inca AS (
    SELECT codmes_mrm, tip_doc, id_value, seg_arq_salud, region_12m_prio,
           var_cuali_far_rubrofrec_9m_v3, flg_hosp_12m
    FROM (
        SELECT p.codmes_mrm,
               p.tip_doc,
               p.id_value,
               a.seg_arq_salud,
               a.region_12m_prio,
               a.var_cuali_far_rubrofrec_9m_v3,
               a.flg_cant_trx_rubro_hospitales_clinicas_pos_ult_12m_1                  AS flg_hosp_12m,
               row_number() OVER (PARTITION BY p.codmes_mrm, p.tip_doc, p.id_value
                                  ORDER BY a.load_date DESC)                           AS rn
        FROM po p
        INNER JOIN mapa m
               ON m.tip_doc = p.tip_doc AND m.id_value = p.id_value
        INNER JOIN e_perm_aws.t_inca_sa a
               ON a.party_id = m.inter_party_id
              AND a.cod_mes  = p.m02
    ) z
    WHERE z.rn = 1
)
SELECT p.tip_doc,
       p.id_value,
       coalesce(c.tipo_ingreso, 'INDEPENDIENTE')                                       AS tipo_ingreso,
       CASE WHEN coalesce(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
            THEN 'DEP_VAL' ELSE 'NO_DEP_VAL' END                                       AS tipo_ingreso_dep,
       c.sit_lab                                                                       AS sit_lab_crudo,
       c.fuente                                                                        AS fuente_ingreso,
       i.seg_arq_salud,
       i.region_12m_prio,
       i.var_cuali_far_rubrofrec_9m_v3,
       i.flg_hosp_12m,
       CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                 AS falla_sin_tipo_ingreso,
       CAST(CASE WHEN i.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                 AS ctrl_inca_sin_dato,
       CAST(CASE WHEN c.fuente IN ('SUSALUD','INFERIDO_IND_MVP') THEN 1 ELSE 0 END AS INTEGER) AS ctrl_fuente_nueva,
       p.codmes_mrm
FROM po p
LEFT JOIN cls  c ON c.tip_doc = p.tip_doc AND c.id_value = p.id_value AND c.codmes_mrm = p.codmes_mrm
LEFT JOIN inca i ON i.tip_doc = p.tip_doc AND i.id_value = p.id_value AND i.codmes_mrm = p.codmes_mrm
