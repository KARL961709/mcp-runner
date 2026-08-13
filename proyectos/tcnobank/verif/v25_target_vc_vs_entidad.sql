-- ============================================================================
-- V25. TARGET VISION CLIENTE CONTRA TARGET POR ENTIDAD - SERIE MENSUAL
--   scan: 11_po_key U 05_rcc_agg [codmes+1, codmes+12] U cal
--   la unica diferencia entre los dos es el filtro de entidad sobre la mora. El evento
--          duro ya se calcula a nivel CLIENTE en 50_targets lineas 54 y 55, sin entidad,
--          asi que no aporta a la brecha. 50_targets linea 52 es la que la produce
--   target_ent  mora de la entidad del alta         -> es nuestro target_12m
--   target_cli  mora del cliente en cualquier entidad -> es el TARGET60_12_VC del recibido
--   el sesgo esta firmado como A2.3 y medido en +0.71 pp sobre 13,916 registros de un csv
--          de un solo corte. Esto lo abre por mes y por entidad sobre toda la ventana
--   control  target_ent recalculado aca contra cal.target_12m. Tiene que dar CERO
--          discrepancias. Si no da cero, la reconstruccion esta mal y el resto no se lee
--   solo maduros: target_12m NULL queda fuera del promedio, no cuenta como bueno
-- ============================================================================
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           date_format(date_add('month',  1, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS p01,
           date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS p12
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           CASE WHEN sum(monto_cast) > 0 OR sum(sld_jud) > 0
                  OR sum(sld_ref)    > 0 OR sum(sld_ree) > 0
                THEN 1 ELSE 0 END                                                       AS duro
    FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
),
fut AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value, p.entidad,
           max(CASE WHEN e.entidad = p.entidad THEN e.dm_tc END)                        AS dm_ent,
           max(e.dm_tc)                                                                 AS dm_cli,
           max(CASE WHEN c.duro = 1 THEN 1 ELSE 0 END)                                  AS duro
    FROM po p
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg e
           ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value
          AND e.codmes BETWEEN p.p01 AND p.p12
    LEFT JOIN cli c
           ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
          AND c.codmes BETWEEN p.p01 AND p.p12
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, p.entidad
),
t AS (
    SELECT f.codmes_mrm,
           f.entidad,
           CASE WHEN f.entidad = '00002' THEN '1.IBK' ELSE '2.resto' END                AS ambito,
           c.target_12m,
           CAST(CASE WHEN coalesce(f.dm_ent, 0) > 60 OR coalesce(f.duro, 0) = 1
                     THEN 1 ELSE 0 END AS INTEGER)                                      AS target_ent,
           CAST(CASE WHEN coalesce(f.dm_cli, 0) > 60 OR coalesce(f.duro, 0) = 1
                     THEN 1 ELSE 0 END AS INTEGER)                                      AS target_cli
    FROM fut f
    INNER JOIN disc_model_owner.ds_adm_vcnbank_tc_cal c
            ON c.tip_doc = f.tip_doc AND c.id_value = f.id_value
           AND c.entidad = f.entidad AND c.codmes_mrm = f.codmes_mrm
    WHERE c.flg_clean = 1 AND c.target_12m IS NOT NULL
)
SELECT '0.control'                                                                      AS corte,
       'target_ent recalculado vs cal.target_12m'                                       AS dim,
       ''                                                                               AS ambito,
       count(*)                                                                         AS n,
       sum(CASE WHEN target_ent <> target_12m THEN 1 ELSE 0 END)                        AS n_discrepancia,
       CAST(NULL AS BIGINT)                                                             AS n_solo_cli,
       CAST(NULL AS DOUBLE)                                                             AS rd_ent,
       CAST(NULL AS DOUBLE)                                                             AS rd_cli,
       CAST(NULL AS DOUBLE)                                                             AS delta_pp
FROM t
UNION ALL
SELECT 'A.mes'                                                                          AS corte,
       codmes_mrm                                                                       AS dim,
       ambito,
       count(*)                                                                         AS n,
       sum(CASE WHEN target_ent <> target_12m THEN 1 ELSE 0 END)                        AS n_discrepancia,
       sum(CASE WHEN target_cli = 1 AND target_ent = 0 THEN 1 ELSE 0 END)               AS n_solo_cli,
       round(100.0 * avg(CAST(target_ent AS DOUBLE)), 4)                                AS rd_ent,
       round(100.0 * avg(CAST(target_cli AS DOUBLE)), 4)                                AS rd_cli,
       round(100.0 * avg(CAST(target_cli AS DOUBLE))
           - 100.0 * avg(CAST(target_ent AS DOUBLE)), 4)                                AS delta_pp
FROM t
WHERE codmes_mrm >= '202301'
GROUP BY codmes_mrm, ambito
UNION ALL
SELECT 'B.entidad'                                                                      AS corte,
       entidad                                                                          AS dim,
       ambito,
       count(*)                                                                         AS n,
       sum(CASE WHEN target_ent <> target_12m THEN 1 ELSE 0 END)                        AS n_discrepancia,
       sum(CASE WHEN target_cli = 1 AND target_ent = 0 THEN 1 ELSE 0 END)               AS n_solo_cli,
       round(100.0 * avg(CAST(target_ent AS DOUBLE)), 4)                                AS rd_ent,
       round(100.0 * avg(CAST(target_cli AS DOUBLE)), 4)                                AS rd_cli,
       round(100.0 * avg(CAST(target_cli AS DOUBLE))
           - 100.0 * avg(CAST(target_ent AS DOUBLE)), 4)                                AS delta_pp
FROM t
GROUP BY entidad, ambito
ORDER BY corte, dim, ambito
