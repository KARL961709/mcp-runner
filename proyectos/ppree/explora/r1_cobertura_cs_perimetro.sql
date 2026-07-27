-- ============================================================================
-- R1. Q1 refuto que el 78% sin cruzar sea formato: es poblacion (las tres
--     variantes de join dieron identico). Falta la pregunta que decide:
--     cual es la cobertura de cuenta sueldo SOBRE EL PERIMETRO REENGANCHE,
--     que es lo que se calibra, y no sobre el stock completo.
--     Contradiccion a resolver: 22_scoring_ree_v3.sql#L14 afirma
--     'Cobertura 100%' y Q1 midio 21.7% sobre el stock.
--     Devuelve las dos poblaciones lado a lado, por anio.
-- ============================================================================
SELECT
  SUBSTR(p.codmes_mrm, 1, 4)                                                      AS anio,
  COUNT(*)                                                                        AS n_stock,
  SUM(CASE WHEN d.falla_sin_cta_sueldo = 0 THEN 1 ELSE 0 END)                     AS n_stock_con_cs,
  ROUND(100.0 * AVG(CASE WHEN d.falla_sin_cta_sueldo = 0 THEN 1.0 ELSE 0.0 END), 2) AS pct_stock,
  SUM(CASE WHEN m.id_value IS NOT NULL THEN 1 ELSE 0 END)                         AS n_ree,
  SUM(CASE WHEN m.id_value IS NOT NULL AND d.falla_sin_cta_sueldo = 0 THEN 1 ELSE 0 END) AS n_ree_con_cs,
  ROUND(100.0 * AVG(CASE WHEN m.id_value IS NOT NULL AND d.falla_sin_cta_sueldo = 0 THEN 1.0
                         WHEN m.id_value IS NOT NULL THEN 0.0 END), 2)            AS pct_ree,
  SUM(CASE WHEN m.id_value IS NOT NULL AND d.flg_cs = 1 THEN 1 ELSE 0 END)        AS n_ree_cs_1,
  SUM(CASE WHEN m.id_value IS NOT NULL AND d.falla_sin_cta_sueldo = 0 AND d.flg_cs = 0
           THEN 1 ELSE 0 END)                                                     AS n_ree_cs_0_medido,
  SUM(CASE WHEN m.id_value IS NOT NULL AND d.falla_sin_cta_sueldo = 1 THEN 1 ELSE 0 END) AS n_ree_cs_0_por_ausencia
FROM disc_model_owner.ds_stk_ree_pp_40_drivers d
INNER JOIN disc_model_owner.ds_stk_ree_pp_50_pd p
       ON p.codmes_mrm = d.codmes_mrm AND p.tip_doc = d.tip_doc AND p.id_value = d.id_value
LEFT JOIN disc_model_owner.ds_stk_ree_pp_11_marca m
       ON m.id_value = d.id_value AND m.codmes_mrm = d.codmes_mrm
GROUP BY 1
ORDER BY 1
