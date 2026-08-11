-- 110_donde_esta_mora_temprana.sql | ubica en que tablas sobrevive dias_atraso por mes. El cal solo arrastra 6m/9m/12m, pero la fuente de maduracion tiene 1m..12m y de ahi sale la mora 30d a 3m
SELECT table_name,
       count(*)                                                  AS n_columnas,
       array_join(array_agg(column_name ORDER BY column_name), ' ') AS columnas
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND (column_name LIKE 'dias_atraso%' OR column_name LIKE 'dm_f%')
GROUP BY table_name
ORDER BY table_name
