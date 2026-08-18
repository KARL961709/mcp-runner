-- ============================================================================
-- Q04. COBERTURA DE 51_dmsf POR MES
--   Cuenta FILAS, no particiones: una particion declarada y vacia es el error
--   que ya costo un redibujo entero de tramos. Ningun mes de [201903, 202606]
--   puede faltar ni venir con n muy por debajo de sus vecinos.
-- ============================================================================
SELECT codmes,
       count(*)                                                                 AS n_filas,
       sum(CASE WHEN dm_sf IS NULL THEN 1 ELSE 0 END)                           AS n_dmsf_null,
       sum(CASE WHEN dm_sf > 60 THEN 1 ELSE 0 END)                              AS n_dmsf_60,
       max(dm_sf)                                                               AS dm_sf_max
  FROM disc_model_owner.ds_adm_vcnbank_tc_51_dmsf
 GROUP BY codmes
 ORDER BY codmes
