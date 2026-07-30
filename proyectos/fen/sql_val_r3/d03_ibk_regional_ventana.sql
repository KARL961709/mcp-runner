-- d03 VENTANA MEDIDA de IBK+ regional -- meses con filas, regiones, categorias y proyeccion
SELECT codmes,
       count(*)                              AS n_filas,
       count(DISTINCT region_nombre)         AS n_regiones,
       count(DISTINCT categoria_nombre)      AS n_categorias,
       max(es_proyeccion)                    AS flg_proyeccion
FROM disc_model_owner.ibk_indice_regional_categoria
GROUP BY codmes
ORDER BY codmes
