-- ============================================================================
-- V9. Funnel marginal de los seis filtros contra los n FIRMADOS, mas el
--     chequeo de magnitud de A37. Corre DESPUES de 70_cal.
--
--     Blancos fijos, medidos antes de construir (J1, J2, L1, H47, H51, H60, H61):
--       gtia_hip 130 | colab 25 | malo_sf 63 | malo_origen 0 | mto_pend 10 | baja 0
--     Son sobre el perimetro reenganche y la ventana completa.
--
--     A37: quien omita flg_scope_ree = 1 calibra sobre el stock entero, y eso no
--     falla - devuelve resultados. n_fit_mes debe estar en el orden de 1.3k, no
--     de 1.7M. Es un chequeo de MAGNITUD, el unico que caza un WHERE incompleto.
-- ============================================================================
SELECT
  'TOTAL_VENTANA'                                                                 AS alcance,
  COUNT(*)                                                                        AS n_universo,
  SUM(flg_scope_ree)                                                              AS n_ree,
  SUM(CASE WHEN flg_scope_ree = 1 THEN filtro_gtia_hip    ELSE 0 END)             AS n_gtia_hip,
  SUM(CASE WHEN flg_scope_ree = 1 THEN filtro_colab       ELSE 0 END)             AS n_colab,
  SUM(CASE WHEN flg_scope_ree = 1 THEN filtro_malo_sf     ELSE 0 END)             AS n_malo_sf,
  SUM(CASE WHEN flg_scope_ree = 1 THEN filtro_malo_origen ELSE 0 END)             AS n_malo_origen,
  SUM(CASE WHEN flg_scope_ree = 1 THEN filtro_mto_pend    ELSE 0 END)             AS n_mto_pend,
  SUM(CASE WHEN flg_scope_ree = 1 THEN filtro_baja        ELSE 0 END)             AS n_baja,
  SUM(CASE WHEN filtro_gtia_hip IS NULL OR filtro_colab IS NULL OR filtro_malo_sf IS NULL
             OR filtro_malo_origen IS NULL OR filtro_mto_pend IS NULL OR filtro_baja IS NULL
           THEN 1 ELSE 0 END)                                                     AS falla_filtro_null,
  SUM(CASE WHEN flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1 THEN 1 ELSE 0 END) AS n_fit_total,
  ROUND(CAST(SUM(CASE WHEN flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1 THEN 1 ELSE 0 END) AS DOUBLE)
        / NULLIF(COUNT(DISTINCT CASE WHEN flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
                                     THEN codmes_mrm END), 0), 0)                 AS n_fit_por_mes,
  COUNT(DISTINCT CASE WHEN flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
                      THEN codmes_mrm END)                                        AS n_cohortes_fit,
  ROUND(AVG(CASE WHEN flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
                 THEN CAST(target_12m_60 AS DOUBLE) END), 4)                      AS rd12_fit
FROM disc_model_owner.ds_stk_ree_pp_cal
