-- ============================================================================
-- 52. TARGET VISION CLIENTE 1M A 12M - COHORTES DESDE 202401
--   DERIVADO de 50_targets.sql por sustitucion, no reescrito. Cambia UNA sola
--   cosa de fondo: la pata de mora pasa de dm_tc de la entidad de alta a dm_sf
--   de todo el sistema y todos los creditos. La pata dura queda byte a byte
--   identica, asi que target_vc_12m contra target_12m aisla exactamente la mora.
--   El WHERE codmes_mrm >= 202401 NO es cosmetico: 51_dmsf solo tiene [202402,
--   202606], asi que sin ese filtro una cohorte anterior no encontraria fila,
--   el coalesce(max_sf_12m, 0) > 60 daria falso y el target saldria 0 en vez de
--   NULL. Falsos buenos en silencio.
--   scan: 11_po_key + 51_dmsf [codmes+1, codmes+12] + 05_rcc_agg para la pata dura
--   ancla: acumulado desde +1. Inmaduro contra el snapshot 202606 es NULL, nunca 0
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_52_target_vc AS
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, date_format(date_add('month', 1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p01
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
    WHERE codmes_mrm >= '202401'
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           CASE WHEN coalesce(monto_cast,0) > 0 OR coalesce(sld_jud,0) > 0
                  OR coalesce(sld_ref,0)    > 0 OR coalesce(sld_ree,0) > 0
                THEN 1 ELSE 0 END                                                      AS duro
    FROM (
        SELECT codmes, tip_doc, key_value,
               sum(monto_cast) AS monto_cast, sum(sld_jud) AS sld_jud,
               sum(sld_ref)    AS sld_ref,    sum(sld_ree) AS sld_ree
        FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
        GROUP BY codmes, tip_doc, key_value) z
),
fut AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value, p.entidad,
           CAST(12 - count(DISTINCT e.codmes) AS INTEGER)                              AS missing_12_vc,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_01m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 2, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_02m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 3, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_03m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 4, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_04m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 5, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_05m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 6, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_06m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 7, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_07m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 8, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_08m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 9, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_09m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 10, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_10m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 11, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_11m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_sf END) AS max_sf_12m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_01m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 2, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_02m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 3, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_03m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 4, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_04m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 5, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_05m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 6, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_06m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 7, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_07m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 8, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_08m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 9, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_09m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 10, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_10m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 11, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_11m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_12m
    FROM po p
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_51_dmsf e ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value
                                AND e.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
    LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
                   AND c.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, p.entidad
)
SELECT tip_doc,
       id_value,
       entidad,
       missing_12,
       max_sf_12m                                                                      AS max_dm_sf_fut,
       CAST(coalesce(duro_12m, 0) AS INTEGER)                                          AS f_evento_fut_vc,
       CAST(CASE WHEN date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS INTEGER)                          AS falla_madurez_vc,
       CASE WHEN date_format(date_add('month', 1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_01m, 0) > 60 OR coalesce(duro_01m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_01m,
       CASE WHEN date_format(date_add('month', 2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_02m, 0) > 60 OR coalesce(duro_02m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_02m,
       CASE WHEN date_format(date_add('month', 3, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_03m, 0) > 60 OR coalesce(duro_03m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_03m,
       CASE WHEN date_format(date_add('month', 4, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_04m, 0) > 60 OR coalesce(duro_04m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_04m,
       CASE WHEN date_format(date_add('month', 5, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_05m, 0) > 60 OR coalesce(duro_05m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_05m,
       CASE WHEN date_format(date_add('month', 6, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_06m, 0) > 60 OR coalesce(duro_06m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_06m,
       CASE WHEN date_format(date_add('month', 7, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_07m, 0) > 60 OR coalesce(duro_07m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_07m,
       CASE WHEN date_format(date_add('month', 8, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_08m, 0) > 60 OR coalesce(duro_08m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_08m,
       CASE WHEN date_format(date_add('month', 9, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_09m, 0) > 60 OR coalesce(duro_09m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_09m,
       CASE WHEN date_format(date_add('month', 10, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_10m, 0) > 60 OR coalesce(duro_10m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_10m,
       CASE WHEN date_format(date_add('month', 11, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_11m, 0) > 60 OR coalesce(duro_11m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_11m,
       CASE WHEN date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_sf_12m, 0) > 60 OR coalesce(duro_12m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_vc_12m,
       codmes_mrm
FROM fut
