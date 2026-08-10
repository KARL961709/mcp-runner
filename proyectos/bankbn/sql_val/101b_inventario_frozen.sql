-- 101b_inventario_frozen.sql | columnas de las tres tablas congeladas contra las que hay que contrastar el port. Sin esto las queries del port se escriben adivinando nombres
SELECT table_name                                        AS tabla,
       count(1) OVER (PARTITION BY table_name)           AS cols_totales,
       ordinal_position                                  AS pos,
       column_name                                       AS columna,
       data_type                                         AS tipo
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name IN ('bnbpe_ibk_calib_src', 'bnbpe_ibk_target_src', 'bnbpe_ibk_altas_src')
  AND regexp_like(lower(column_name),
        'codmes|tip_doc|key_value|clean|calib|target|malo|flg|alta|entidad|instit|ppjj|personeria|pd|prob')
ORDER BY table_name, ordinal_position
