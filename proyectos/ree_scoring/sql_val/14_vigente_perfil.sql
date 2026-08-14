-- 14. PERFIL DE LA VIGENTE POR MES, PARA TENER LA REFERENCIA ANTES DE ESCRIBIR
--   trf_f_t viene expuesto en la salida, asi que el factor de produccion se puede
--   comparar contra el calculado sin inferirlo. Debe ser constante dentro del mes.
--   Las tres columnas de cuenta sueldo y las dos fallas fijan lo que el mes nuevo
--   tiene que reproducir en las columnas que NO entran en la PD.
SELECT CAST(codmes AS VARCHAR)                                                    AS codmes,
       COUNT(*)                                                                   AS n,
       MIN(CAST(trf_f_t AS DOUBLE))                                               AS ft_min,
       MAX(CAST(trf_f_t AS DOUBLE))                                               AS ft_max,
       SUM(CASE WHEN trf_tipo_ingreso = 'DEPENDIENTE'   THEN 1 ELSE 0 END)        AS n_dependiente,
       SUM(CASE WHEN trf_tipo_ingreso = 'MIXTO'         THEN 1 ELSE 0 END)        AS n_mixto,
       SUM(CASE WHEN trf_tipo_ingreso = 'INDEPENDIENTE' THEN 1 ELSE 0 END)        AS n_independiente,
       SUM(CASE WHEN trf_tipo_ingreso_dep = 'DEP'       THEN 1 ELSE 0 END)        AS n_dep,
       SUM(CASE WHEN trf_flg_cs_estado = 'CS'           THEN 1 ELSE 0 END)        AS n_cs,
       SUM(CASE WHEN trf_flg_cs_estado = 'NO_CS'        THEN 1 ELSE 0 END)        AS n_no_cs,
       SUM(CASE WHEN trf_flg_cs_estado = 'SIN_DATO'     THEN 1 ELSE 0 END)        AS n_sin_dato,
       SUM(CAST(trf_falla_sin_tipo_ingreso AS INTEGER))                           AS n_falla_ti,
       SUM(CAST(trf_falla_sin_cta_sueldo AS INTEGER))                             AS n_falla_cs
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
 GROUP BY 1
 ORDER BY 1
