-- ============================================================================
-- V21. IMPACTO DE MOVER EL ANCLA DEL AFP DE M A M-1
--   scan: 11_po_key U t_fact_edc_solicitud_retiro_afp_ibk U 13_pasivos U cal
--   ancla: hoy la exclusion AFP usa codmes_retiro <= M, o sea el mes de la decision.
--          En campania un retiro hecho a mitad de M no se conoce. El ancla correcta es
--          M-1. Solo cambia quien retiro EXCLUSIVAMENTE en el mes M
--   el flag solo se da vuelta si ademas cumple los 6 meses de pasivo: los demas siguen
--          en cero por el lado del saldo. Se reporta donde estan hoy y su target
-- ============================================================================
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value,
           date_format(date_add('month', -1, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m01
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
afp AS (
    SELECT DISTINCT CAST(key_value AS VARCHAR)                                          AS id_value,
           CAST(cod_tip_doc AS VARCHAR)                                                 AS tip_doc,
           date_format(ts_solicitud, '%Y%m')                                            AS codmes_retiro
    FROM e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk
),
r AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value,
           max(CASE WHEN a.codmes_retiro <= p.codmes_mrm THEN 1 ELSE 0 END)             AS retiro_m0,
           max(CASE WHEN a.codmes_retiro <= p.m01        THEN 1 ELSE 0 END)             AS retiro_m1
    FROM po p
    INNER JOIN afp a ON a.id_value = p.id_value AND a.tip_doc = p.tip_doc
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value
)
SELECT CASE WHEN c.entidad = '00002' THEN '1.IBK' ELSE '2.resto' END                    AS ambito,
       c.nodo_final                                                                     AS nodo_hoy,
       CASE WHEN r.retiro_m0 = 1 AND r.retiro_m1 = 0 AND b.flg_pasivo_6m = 1
            THEN '1.el flag se da vuelta'
            WHEN r.retiro_m0 = 1 AND r.retiro_m1 = 0
            THEN '2.solo retiro en M, pero no cumple pasivo'
            ELSE '3.sin cambio' END                                                     AS efecto,
       count(*)                                                                         AS n,
       sum(c.target_12m)                                                                AS n_malo,
       round(100.0 * avg(CAST(c.target_12m AS DOUBLE)), 4)                              AS rd_12m
FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
LEFT JOIN r ON r.codmes_mrm = c.codmes_mrm AND r.tip_doc = c.tip_doc AND r.id_value = c.id_value
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_13_pasivos b
       ON b.codmes_mrm = c.codmes_mrm AND b.tip_doc = c.tip_doc AND b.id_value = c.id_value
WHERE c.flg_calib = 1 AND c.flg_clean = 1
GROUP BY CASE WHEN c.entidad = '00002' THEN '1.IBK' ELSE '2.resto' END,
         c.nodo_final,
         CASE WHEN r.retiro_m0 = 1 AND r.retiro_m1 = 0 AND b.flg_pasivo_6m = 1
              THEN '1.el flag se da vuelta'
              WHEN r.retiro_m0 = 1 AND r.retiro_m1 = 0
              THEN '2.solo retiro en M, pero no cumple pasivo'
              ELSE '3.sin cambio' END
ORDER BY ambito, nodo_hoy, efecto
