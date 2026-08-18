-- ============================================================================
-- 03. DESCOMPOSICION DE LA BRECHA POR EJE
--   scan: ds_adm_vcnbank_tc_11_po_key + ds_adm_vcnbank_tc_05_rcc_agg [mrm+1, mrm+12]
--   Reproduce max_dm_fut quitando SOLO el filtro de entidad, con el mismo dm_tc.
--   Lo que gana aqui es el eje ENTIDAD puro. El resto de la brecha contra el
--   original es el eje PRODUCTO -dm_sf cubre todos los creditos, dm_tc solo TC-.
--   La columna de mes es codmes_mrm en 11_po_key y en la tabla de calibracion,
--   y codmes en 05_rcc_agg, que es su particion.
-- ============================================================================
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           date_format(date_add('month',  1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p01,
           date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p12
      FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
fut AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value, p.entidad,
           max(e.dm_tc)                                                          AS dm_sist
      FROM po p
      LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg e
             ON e.tip_doc   = p.tip_doc
            AND e.key_value = p.id_value
            AND e.codmes BETWEEN p.p01 AND p.p12
     GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, p.entidad
)
SELECT c.codmes_mrm                                                              AS codmes,
       count(*)                                                                  AS n,
       sum(c.target_12m)                                                         AS n_tc,
       sum(CASE WHEN coalesce(f.dm_sist, 0) > 60 OR c.f_evento_fut = 1
                THEN 1 ELSE 0 END)                                               AS n_tc_todas_ent,
       sum(CASE WHEN (coalesce(f.dm_sist, 0) > 60 OR c.f_evento_fut = 1)
                 AND c.target_12m = 0 THEN 1 ELSE 0 END)                         AS solo_otra_ent,
       sum(CASE WHEN coalesce(c.max_dm_fut, 0) > 60 THEN 1 ELSE 0 END)           AS n_mora_ent,
       sum(CASE WHEN coalesce(f.dm_sist, 0) > 60 THEN 1 ELSE 0 END)              AS n_mora_sist
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
  JOIN fut f
    ON f.tip_doc    = c.tip_doc
   AND f.id_value   = c.id_value
   AND f.entidad    = c.entidad
   AND f.codmes_mrm = c.codmes_mrm
 WHERE c.flg_calib = 1 AND c.flg_clean = 1
 GROUP BY c.codmes_mrm
 ORDER BY c.codmes_mrm
