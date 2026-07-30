-- h01 VOLUMEN Y VENTANA de t_dmdireccion_apicliente -- la tabla NO tiene particiones (g01: extra_info vacio)
--     asi que todo es full scan: pocas consultas y densas
SELECT codmes,
       count(*)                        AS n_filas,
       count(DISTINCT key_value)       AS n_personas,
       count(DISTINCT tipdireccion)    AS n_tipos_dir,
       count(DISTINCT ubigeo)          AS n_ubigeos
FROM d_perm_aws.t_dmdireccion_apicliente
GROUP BY codmes
ORDER BY codmes
