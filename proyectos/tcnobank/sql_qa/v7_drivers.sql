-- v7_drivers.sql | G7. Cobertura de los dos drivers. El de ingreso tiene que cubrir toda la serie. El de Intercorp
-- arranca en 202305 y por eso ctrl_inca_sin_dato tiene que ser 1 en todo lo anterior: si no lo es, el join trajo algo
-- que no deberia. Y si seg_arq_salud no varia entre meses, el rezago -2 no protege de nada y el eje es estatico.
SELECT substr(codmes_mrm, 1, 4)                                                          AS anio,
       count(*)                                                                          AS n,
       round(100.0 * avg(CAST(falla_sin_tipo_ingreso AS DOUBLE)), 3)                     AS pct_sin_ingreso,
       round(100.0 * avg(CAST(ctrl_inca_sin_dato     AS DOUBLE)), 3)                     AS pct_sin_inca,
       round(100.0 * avg(CAST(ctrl_fuente_nueva      AS DOUBLE)), 3)                     AS pct_fuente_nueva,
       count(DISTINCT tipo_ingreso)                                                      AS n_tipo_ingreso,
       count(DISTINCT seg_arq_salud)                                                     AS n_seg_salud,
       round(100.0 * avg(CASE WHEN tipo_ingreso = 'DEPENDIENTE' THEN 1.0 ELSE 0.0 END), 3) AS pct_dep_val,
       round(100.0 * avg(CAST(falla_sin_score AS DOUBLE)), 3)                            AS pct_sin_score,
       round(100.0 * avg(CAST(falla_sin_cuc   AS DOUBLE)), 3)                            AS pct_sin_cuc,
       round(100.0 * avg(CAST(falla_sin_sbs   AS DOUBLE)), 3)                            AS pct_sin_sbs
FROM disc_model_owner.ds_adm_tcnb_cal
GROUP BY substr(codmes_mrm, 1, 4)
ORDER BY anio
