-- ============================================================================
-- v37. flg_ree_v4: NULL, cero, y como queda compuesto el perimetro
--
--   El 50_pd nuevo construye flg_ree_v4 con LEFT JOIN y un literal 1 del lado
--   derecho, asi que el dominio es {1, NULL} y nunca 0. Falta el COALESCE.
--   Hoy el perimetro funciona porque NULL = 1 no pasa el filtro, pero cualquier
--   consumo que pida el complemento (= 0, <> 1) recibe cero filas sin error.
--   Aca se mide el dominio real y la composicion del perimetro por los DOS
--   ejes, que es lo que decide cuantas filas entran al fit.
--
--   Agrupado por anio para que entre en una pantalla. El quiebre que importa es
--   202312 / 202401: antes de 202401 el perimetro lo da flg_scope_ree y desde
--   202401 lo da flg_ree_v4, asi que la columna solo_v4 debe despertar ahi.
-- ============================================================================
SELECT SUBSTR(CAST(codmes_mrm AS VARCHAR), 1, 4)                             AS anio,
       COUNT(*)                                                              AS n_filas,
       SUM(CASE WHEN flg_ree_v4 = 1 THEN 1 ELSE 0 END)                       AS v4_uno,
       SUM(CASE WHEN flg_ree_v4 = 0 THEN 1 ELSE 0 END)                       AS v4_cero,
       SUM(CASE WHEN flg_ree_v4 IS NULL THEN 1 ELSE 0 END)                   AS v4_nulo,
       SUM(CASE WHEN flg_scope_ree = 1 THEN 1 ELSE 0 END)                    AS scope_uno,
       SUM(CASE WHEN flg_scope_ree = 1 AND flg_ree_v4 = 1 THEN 1 ELSE 0 END) AS ambos,
       SUM(CASE WHEN flg_scope_ree = 1
                 AND (flg_ree_v4 IS NULL OR flg_ree_v4 = 0)
                THEN 1 ELSE 0 END)                                           AS solo_scope,
       SUM(CASE WHEN flg_ree_v4 = 1
                 AND (flg_scope_ree IS NULL OR flg_scope_ree <> 1)
                THEN 1 ELSE 0 END)                                           AS solo_v4,
       SUM(CASE WHEN flg_scope_ree = 1 OR flg_ree_v4 = 1 THEN 1 ELSE 0 END)  AS perimetro_96
FROM disc_model_owner.ds_stk_ree_pp_cal
GROUP BY SUBSTR(CAST(codmes_mrm AS VARCHAR), 1, 4)
ORDER BY 1
