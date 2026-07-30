-- ============================================================================
-- V5. El invariante del ancla de la pd, como columna y no como argumento.
--     50_pd joinea contra codmes_scr. Si alguien vuelve a tocar el ancla,
--     falla_ancla_scr deja de ser 0 y el chequeo se pone rojo solo.
--     Y el flg_reenganche de la v4 debe coincidir con la marca (H46):
--     falla_marca_sin_v4 debe ser 0 donde hay pd.
-- ============================================================================
SELECT
  SUBSTR(p.codmes_mrm, 1, 4)                                                      AS anio,
  COUNT(*)                                                                        AS n,
  SUM(CASE WHEN p.codmes_scr <> DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(p.codmes_mrm, '%Y%m')), '%Y%m')
           THEN 1 ELSE 0 END)                                                     AS falla_ancla_scr,
  SUM(CASE WHEN p.falla_cruce_pd = 0 THEN 1 ELSE 0 END)                           AS n_con_pd,
  SUM(CASE WHEN m.id_value IS NOT NULL THEN 1 ELSE 0 END)                         AS n_marca,
  SUM(CASE WHEN m.id_value IS NOT NULL AND p.flg_ree_v4 = 1 THEN 1 ELSE 0 END)    AS n_marca_y_v4,
  SUM(CASE WHEN m.id_value IS NOT NULL AND p.falla_cruce_pd = 0
             AND COALESCE(p.flg_ree_v4, 0) <> 1 THEN 1 ELSE 0 END)                AS falla_marca_sin_v4
FROM disc_model_owner.ds_stk_ree_pp_50_pd p
LEFT JOIN disc_model_owner.ds_stk_ree_pp_11_marca m
       ON m.id_value = p.id_value AND m.codmes_mrm = p.codmes_mrm
GROUP BY 1
ORDER BY 1
