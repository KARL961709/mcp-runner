-- e03_r_schema.sql | tabla del score directo FEN por persona (R): en que schema esta, su llave y el campo R_LABEL_REEST + ubigeo
SELECT table_schema, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'mca_bd_reniec_xy_r_reest'
ORDER BY table_schema, ordinal_position
