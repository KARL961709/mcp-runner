-- ============================================================================
-- V14. QUE EJE DE SEGMENTACION SE GANA LA CALIBRACION
--   scan: __T___cal sobre flg_calib = 1 y flg_clean = 1, las 5 entidades
--   ancla: el nodo cubre 18.4 por ciento (solo IBK) y su peor bucket mezcla
--          comportamiento con falta de dato. Un eje de calibracion tiene que existir
--          en toda la base. ratio_obs_pred es lo que la calibracion corrige: si no
--          varia entre niveles, el score ya lo capturo y el eje no aporta
--   n_sin_dato hace visible la cobertura de cada eje en vez de esconderla en un nivel
-- ============================================================================
WITH b AS (
    SELECT coalesce(CAST(ctrl_solo_linea AS VARCHAR), 'SIN_DATO')                       AS e_linea,
           coalesce(seg_arq_salud,        'SIN_DATO')                                   AS e_salud,
           coalesce(tipo_ingreso_dep,     'SIN_DATO')                                   AS e_ingreso,
           coalesce(flg_cs_estado,        'SIN_DATO')                                   AS e_cs,
           coalesce(region_12m_prio,      'SIN_DATO')                                   AS e_region,
           entidad                                                                      AS e_entidad,
           coalesce(nodo_final,           'SIN_DATO')                                   AS e_nodo,
           target_12m,
           pd_raw
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
)
SELECT t.eje,
       t.valor,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.eje), 3)             AS pct_del_eje,
       sum(b.target_12m)                                                                AS n_malo,
       round(100.0 * avg(CAST(b.target_12m AS DOUBLE)), 4)                              AS rd_12m,
       round(100.0 * avg(b.pd_raw), 4)                                                  AS pd_raw_media,
       round(avg(CAST(b.target_12m AS DOUBLE)) / nullif(avg(b.pd_raw), 0), 4)           AS ratio_obs_pred
FROM b
CROSS JOIN UNNEST(
    ARRAY['1.solo_linea','2.arq_salud','3.tipo_ingreso','4.cta_sueldo','5.region','6.entidad','7.nodo'],
    ARRAY[b.e_linea, b.e_salud, b.e_ingreso, b.e_cs, b.e_region, b.e_entidad, b.e_nodo])
    AS t (eje, valor)
GROUP BY t.eje, t.valor
ORDER BY t.eje, n DESC
LIMIT 60
