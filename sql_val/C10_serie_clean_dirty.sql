-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C10_serie_clean_dirty.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C10_serie_clean_dirty.sql
--   sha256  : 73869d234b8e   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : la inversion reciente del dirty: trimestre a trimestre, con peso de SIN BLOQUE
-- =====================================================================================
-- =====================================================================================
-- C10_serie_clean_dirty.sql | ¿el dirty separa riesgo, y desde cuando deja de hacerlo?
--
-- EL HECHO A RESOLVER
--   ventana completa 202207-202505 : CLEAN 8.83% · DIRTY real 12.57%  -> 1.42x, IC disjuntos
--   ultimos 3m       202503-202505 : CLEAN 5.43% · DIRTY real  2.91%  -> 0.54x, p=0.074
--   La inversion reciente puede ser (a) un cambio real, (b) ruido de 9 defaults sobre 309,
--   o (c) un artefacto de composicion. Esto lo separa mirando la serie completa.
--
-- POR QUE LA COMPOSICION PUEDE ENGANIAR
--   flg_impulsa es FORWARD [m0, m0+12] (q2_adv_prog_src.sql). No marca "el alta ocurrio en
--   epoca Impulsa": marca "este cliente tuvo exposicion Impulsa en los 12 meses siguientes".
--   Por eso SIN BLOQUE sigue siendo 22.7% de las altas de 2025.
--   Como SIN BLOQUE se lleva gente que si no estaria en DIRTY o en CLEAN, su peso cambia
--   la mezcla de los otros dos sin que cambie el riesgo de nadie.
--
-- TRES SALIDAS (q3_pdraw_tri_desfase.sql:33 · q3b_pdraw_dirty0.sql:36-37)
--   CLEAN       flg_calib_m2 = 1
--   DIRTY real  flg_calib_m2 = 0 AND impulsa = 0 AND reactiva_puro = 0
--   SIN BLOQUE  impulsa = 1 OR reactiva_puro = 1     -> no entra a ningun ajuste
--
-- COMO SE LEE
--   Bloque 1: ratio DIRTY/CLEAN por trimestre. Si es >1 casi siempre y solo cae al final,
--             es ruido o regimen. Si viene cayendo hace trimestres, es deriva real.
--   Bloque 2: peso de SIN BLOQUE. Si sube justo cuando el ratio cae, es composicion.
--   Bloque 3: cuanto del dirty es giro. Si giro crece, el bloque se vuelve politica pura
--             y su RD converge a la del clean por construccion.
--   n_dirty por trimestre: si baja de ~100, el ratio de ese trimestre no dice nada.
--
-- Ventana 202207-202505 (12m cerrados). ~48 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(cast(codmes AS int) / 100 AS varchar) || 'T'
      || cast((cast(substr(cast(codmes AS varchar), 5, 2) AS int) - 1) / 3 + 1 AS varchar) AS trim,
         personeria,
         cast(target_12m AS double) AS y,
         coalesce(flg_calib_m2,0)      AS clean,
         coalesce(flg_impulsa,0)       AS f_imp,
         coalesce(flg_reactiva_puro,0) AS f_rea,
         coalesce(flg_giro,0)          AS f_giro,
         coalesce(flg_monto,0)         AS f_monto
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
g AS (
  SELECT *, CASE WHEN f_imp = 1 OR f_rea = 1 THEN 'SIN BLOQUE'
                 WHEN clean = 1 THEN 'CLEAN'
                 ELSE 'DIRTY real' END AS grupo
  FROM b
),
p AS (
  SELECT trim,
         count_if(grupo = 'CLEAN')       AS n_cle,
         sum(CASE WHEN grupo = 'CLEAN'      THEN y ELSE 0 END) AS d_cle,
         count_if(grupo = 'DIRTY real')  AS n_dir,
         sum(CASE WHEN grupo = 'DIRTY real' THEN y ELSE 0 END) AS d_dir,
         count_if(grupo = 'SIN BLOQUE')  AS n_sin,
         sum(CASE WHEN grupo = 'SIN BLOQUE' THEN y ELSE 0 END) AS d_sin,
         count(*) AS n_tot,
         count_if(grupo = 'DIRTY real' AND f_giro = 1)  AS n_dir_giro,
         count_if(grupo = 'DIRTY real' AND f_monto = 0) AS n_dir_monto
  FROM g GROUP BY trim
)

-- ------------------------------------------------- 1. la serie: ¿separa o no?
SELECT '1. RATIO POR TRIMESTRE' AS bloque, trim AS detalle,
       cast(n_cle AS varchar) || ' / ' || cast(n_dir AS varchar) AS n_clean_dirty,
       cast(round(100.0 * d_cle / nullif(n_cle,0), 2) AS varchar) || ' %' AS rd_clean,
       cast(round(100.0 * d_dir / nullif(n_dir,0), 2) AS varchar) || ' %' AS rd_dirty,
       CASE WHEN n_dir < 60 THEN 'n chico: no concluir'
            ELSE 'ratio ' || cast(round((1.0*d_dir/nullif(n_dir,0))
                                      / nullif(1.0*d_cle/nullif(n_cle,0), 0), 2) AS varchar) || 'x'
       END AS ratio
FROM p

-- ------------------------------------------------- 2. el peso de SIN BLOQUE
-- Si sube justo cuando el ratio cae, la inversion es composicion y no riesgo.
UNION ALL
SELECT '2. PESO SIN BLOQUE', trim,
       cast(n_sin AS varchar) || ' de ' || cast(n_tot AS varchar),
       cast(round(100.0 * n_sin / nullif(n_tot,0), 1) AS varchar) || ' % de las altas',
       cast(round(100.0 * d_sin / nullif(n_sin,0), 2) AS varchar) || ' % RD',
       'impulsa es FORWARD: arrastra altas de cualquier cohorte'
FROM p

-- ------------------------------------------------- 3. cuanto del dirty es politica
-- giro y monto son politica, no riesgo. Si crecen, el dirty converge al clean solo.
UNION ALL
SELECT '3. COMPOSICION DIRTY', trim,
       cast(n_dir AS varchar) || ' dirty',
       'giro ' || cast(round(100.0 * n_dir_giro / nullif(n_dir,0), 1) AS varchar) || ' %',
       'monto ' || cast(round(100.0 * n_dir_monto / nullif(n_dir,0), 1) AS varchar) || ' %',
       'los dos son POLITICA'
FROM p

-- ------------------------------------------------- 4. acumulado por anio
-- Con mas n por celda que el trimestre, para leer la tendencia sin ruido.
UNION ALL
SELECT '4. POR ANIO', substr(trim, 1, 4),
       cast(sum(n_cle) AS varchar) || ' / ' || cast(sum(n_dir) AS varchar),
       cast(round(100.0 * sum(d_cle) / nullif(sum(n_cle),0), 2) AS varchar) || ' %',
       cast(round(100.0 * sum(d_dir) / nullif(sum(n_dir),0), 2) AS varchar) || ' %',
       'ratio ' || cast(round((1.0*sum(d_dir)/nullif(sum(n_dir),0))
                            / nullif(1.0*sum(d_cle)/nullif(sum(n_cle),0), 0), 2) AS varchar) || 'x'
       || ' · sin bloque ' || cast(round(100.0 * sum(n_sin) / nullif(sum(n_tot),0), 1) AS varchar) || ' %'
FROM p GROUP BY substr(trim, 1, 4)

ORDER BY 1, 2
