-- 100_inventario_validacion.sql | que columnas de target/atraso/clasificacion tiene la tabla de maduracion, y que tablas congeladas existen para contrastar. Sin esto las validaciones de semantica del target y del port se escriben a ciegas
SELECT bloque, nombre, detalle
FROM (
    SELECT 'A_columnas_mad' AS bloque,
           column_name      AS nombre,
           data_type        AS detalle
    FROM information_schema.columns
    WHERE table_schema = 'disc_model_owner'
      AND table_name = 'ds_adm_bpe_bankbn_mad'
      AND regexp_like(lower(column_name),
            'target|atraso|clasif|castig|judic|refin|reest|condicion|alta|tag|dias|malo|flag')
    UNION ALL
    SELECT 'B_tablas_congeladas',
           table_name,
           table_schema
    FROM information_schema.tables
    WHERE table_schema IN ('disc_model_owner', 'disc_riesgos')
      AND regexp_like(lower(table_name),
            'calib_src|bnbpe|b46029|universo_bank|po_previa|frozen|src')
) z
ORDER BY bloque, nombre
