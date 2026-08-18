-- 05. CRUCE ds_ CONTRA scr_adm: la PD calibrada contra la mora observada
--   El grano de las dos tablas es el mismo -(tip_doc, id_value, entidad,
--   codmes_mrm)- asi que el join es 1 a 1 y las cuatro columnas van SIEMPRE.
--   Con tres solas la persona con altas en dos entidades el mismo mes abre
--   filas y no da error, solo infla los conteos.
--
--   Es el cruce que la tabla del universo NO puede hacer: scr_vcnbank_rsk no
--   trae mora ni identificacion de alta. Aca si esta target_12m.
SELECT s.nodo_calc,
       CASE WHEN s.puntuacion_cal IS NULL THEN NULL
            WHEN s.puntuacion_cal >= 972 THEN 'G1'
            WHEN s.puntuacion_cal >= 964 THEN 'G2'
            WHEN s.puntuacion_cal >= 938 THEN 'G3'
            WHEN s.puntuacion_cal >= 899 THEN 'G4'
            WHEN s.puntuacion_cal >= 768 THEN 'G5'
            ELSE                              'R'
       END                                                                       AS grupo,
       COUNT(*)                                                                  AS n,
       SUM(CASE WHEN d.target_12m IS NOT NULL THEN 1 ELSE 0 END)                 AS n_maduro,
       AVG(d.target_12m)                                                         AS rd_12m,
       AVG(s.pd_raw)                                                             AS pd_raw_prom,
       AVG(s.prob_modelo_cal)                                                    AS pd_cal_prom,
       AVG(s.pd_cal_vigente)                                                     AS pd_vigente_prom
  FROM disc_model_owner.scr_adm_vcnbank_tc_cal s
  INNER JOIN disc_model_owner.ds_adm_vcnbank_tc_cal d
          ON d.tip_doc    = s.tip_doc
         AND d.id_value   = s.id_value
         AND d.entidad    = s.entidad
         AND d.codmes_mrm = s.codmes_mrm
 WHERE s.prob_modelo_cal IS NOT NULL
   AND d.flg_calib = 1
   AND d.flg_clean = 1
   AND d.entidad   = '00002'
 GROUP BY s.nodo_calc,
       CASE WHEN s.puntuacion_cal IS NULL THEN NULL
            WHEN s.puntuacion_cal >= 972 THEN 'G1'
            WHEN s.puntuacion_cal >= 964 THEN 'G2'
            WHEN s.puntuacion_cal >= 938 THEN 'G3'
            WHEN s.puntuacion_cal >= 899 THEN 'G4'
            WHEN s.puntuacion_cal >= 768 THEN 'G5'
            ELSE                              'R'
       END
 ORDER BY 1, 2
