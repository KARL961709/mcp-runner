-- ============================================================================
-- 05 | Integridad de la tabla final. Solo lee, no escribe.
--   Cierra lo que 03 no cubre: nulos campo por campo, llave duplicada, y
--   cuantas filas quedan pegadas al piso y al techo de la PD calibrada.
--   Toda fila reporta MAGNITUD (n y pct), no solo veredicto.
-- ============================================================================
WITH a AS (
  SELECT COUNT(*)                                                              AS n_total,
         SUM(CASE WHEN probabilidad         IS NULL THEN 1 ELSE 0 END)         AS n1,
         SUM(CASE WHEN puntuacion           IS NULL THEN 1 ELSE 0 END)         AS n2,
         SUM(CASE WHEN prob_modelo_cal      IS NULL THEN 1 ELSE 0 END)         AS n3,
         SUM(CASE WHEN puntuacion_cal       IS NULL THEN 1 ELSE 0 END)         AS n4,
         SUM(CASE WHEN trf_f_t              IS NULL THEN 1 ELSE 0 END)         AS n5,
         SUM(CASE WHEN trf_tipo_ingreso_dep IS NULL THEN 1 ELSE 0 END)         AS n6,
         SUM(CASE WHEN key_value IS NULL OR length(key_value) <> 64 THEN 1 ELSE 0 END) AS n7,
         SUM(CASE WHEN prob_modelo_cal <= 0 OR prob_modelo_cal >= 1 THEN 1 ELSE 0 END) AS n8,
         SUM(CASE WHEN puntuacion_cal  <  0 OR puntuacion_cal  > 1000 THEN 1 ELSE 0 END) AS n9,
         SUM(CASE WHEN prob_modelo_cal <= 1e-4   THEN 1 ELSE 0 END)            AS n10,
         SUM(CASE WHEN prob_modelo_cal >= 0.9999 THEN 1 ELSE 0 END)            AS n11,
         SUM(CASE WHEN puntuacion_cal = 1000 THEN 1 ELSE 0 END)                AS n12,
         ROUND(MIN(prob_modelo_cal), 8)                                        AS pd_cal_min,
         ROUND(MAX(prob_modelo_cal), 8)                                        AS pd_cal_max
  FROM disc_model_owner.scr_stk_ree_pp_cal_202607
),
dup AS (
  SELECT COUNT(*) AS n0
  FROM (SELECT codmes, tip_doc, key_value
        FROM disc_model_owner.scr_stk_ree_pp_cal_202607
        GROUP BY 1, 2, 3 HAVING COUNT(*) > 1) z
)
SELECT u.chk,
       u.n_viol,
       a.n_total,
       ROUND(100.0 * u.n_viol / a.n_total, 6) AS pct,
       a.pd_cal_min,
       a.pd_cal_max
FROM a
CROSS JOIN dup
CROSS JOIN UNNEST(
  ARRAY['llave (codmes,tip_doc,key_value) duplicada',
        'probabilidad nula',
        'puntuacion nula',
        'prob_modelo_cal nula',
        'puntuacion_cal nula',
        'trf_f_t nulo',
        'trf_tipo_ingreso_dep nulo',
        'key_value nula o de largo distinto de 64',
        'prob_modelo_cal fuera de (0,1)',
        'puntuacion_cal fuera de [0,1000]',
        'INFO prob_modelo_cal en el piso 1e-4',
        'INFO prob_modelo_cal en el techo 0.9999',
        'INFO puntuacion_cal = 1000'],
  ARRAY[dup.n0, a.n1, a.n2, a.n3, a.n4, a.n5, a.n6, a.n7, a.n8, a.n9, a.n10, a.n11, a.n12]
) AS u(chk, n_viol)
ORDER BY u.n_viol DESC, u.chk
