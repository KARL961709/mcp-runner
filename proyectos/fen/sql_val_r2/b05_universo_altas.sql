-- b05 FUENTE de altas -- ventana y llaves del universo que alimenta ENR_VC_FEM_3
SELECT substr(CAST(codmes AS varchar), 1, 4) AS anio,
       tipo_producto,
       count(*)                                            AS n_filas,
       sum(CASE WHEN dups = 0 THEN 1 ELSE 0 END)           AS n_dups0,
       sum(CASE WHEN flg_entidad_pp = 1 OR flg_entidad_tc = 1 THEN 1 ELSE 0 END) AS n_entidad
FROM disc_model_owner.universo_altas_tc_pp_vc_
GROUP BY 1, 2
ORDER BY 1, 2
