-- v17_pd_lead_vs_calib_pareado.sql | la version POBLACIONAL del caso de 4 filas
-- Read-only sobre ds_stk_ree_pp_cal, que ya trae las 90 cohortes. Para cada alta
-- toma su fila en la cohorte D (pd del cierre de D = la que uso la calibracion) y
-- su fila en la cohorte D-1 (pd del cierre de D-1 = la del lead), y las compara
-- PAREADAS. Es el numero que hoy no tenemos: el caso unico dio -63% y los 36 pares
-- locales dieron +22%, asi que la direccion no esta establecida.
-- Grano: la marca es (id_value, codmes_mrm) sin tip_doc (A17/H38), por eso cal se
-- agrega por (codmes_mrm, id_value) antes del join.
WITH mar AS (
  SELECT DISTINCT id_value, codmes_mrm AS d
  FROM disc_model_owner.ds_stk_ree_pp_11_marca
  WHERE codmes_mrm BETWEEN '202401' AND '202506'
),
cal AS (
  SELECT codmes_mrm,
         id_value,
         MAX(pd_raw)            AS pd_raw,
         MAX(score_raw)         AS score_raw,
         MAX(tipo_ingreso_dep)  AS tipo_ingreso_dep,
         MAX(flg_calib)         AS flg_calib,
         MAX(flg_clean)         AS flg_clean,
         MAX(falla_madurez_12)  AS falla_madurez_12,
         MAX(target_12m_60)     AS target_12m_60
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE codmes_mrm BETWEEN '202312' AND '202506'
  GROUP BY 1, 2
),
j AS (
  SELECT
    c0.tipo_ingreso_dep                            AS seg,
    c0.pd_raw                                      AS pd_cal,
    c0.score_raw                                   AS sc_cal,
    c1.pd_raw                                      AS pd_lead,
    c1.score_raw                                   AS sc_lead,
    c0.flg_calib, c0.flg_clean, c0.falla_madurez_12, c0.target_12m_60
  FROM mar m
  LEFT JOIN cal c0 ON c0.id_value = m.id_value AND c0.codmes_mrm = m.d
  LEFT JOIN cal c1 ON c1.id_value = m.id_value
                  AND c1.codmes_mrm = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
)
SELECT
  COALESCE(seg, 'TOTAL')                                                      AS segmento,
  COUNT(*)                                                                    AS n_altas,
  ROUND(AVG(CASE WHEN pd_lead IS NOT NULL THEN 1.0 ELSE 0 END), 4)            AS pct_con_pd_lead,
  COUNT_IF(pd_lead IS NOT NULL AND pd_cal IS NOT NULL)                        AS n_par,
  ROUND(100.0 * AVG(pd_lead), 4)                                              AS pd_lead_media_pct,
  ROUND(100.0 * AVG(pd_cal), 4)                                               AS pd_calib_media_pct,
  ROUND(APPROX_PERCENTILE(pd_cal / NULLIF(pd_lead, 0), 0.5), 4)               AS ratio_mediano,
  ROUND(AVG(CASE WHEN pd_lead IS NULL OR pd_cal IS NULL THEN NULL
                 WHEN pd_cal < pd_lead THEN 1.0 ELSE 0 END), 4)               AS pct_pd_baja,
  ROUND(APPROX_PERCENTILE(CAST(sc_cal - sc_lead AS DOUBLE), 0.5), 1)          AS delta_score_mediano,
  ROUND(CORR(pd_lead, pd_cal), 4)                                             AS corr_lead_calib,
  ROUND(AVG(CASE WHEN flg_calib = 1 AND flg_clean = 1 AND falla_madurez_12 = 0
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)                  AS rd12_cohorte_d
FROM j
GROUP BY GROUPING SETS ((seg), ())
ORDER BY 1
