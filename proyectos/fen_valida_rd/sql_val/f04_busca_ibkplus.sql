-- f04 localizar IBK plus (columnas/tablas candidatas en las bases de riesgo)
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema IN ('disc_model_owner','d_perm_aws','e_perm_aws','disc_riesgos')
  AND (regexp_like(lower(column_name), 'ibk.?plus|ibkplus|ibk_plus|beneficio|_plus|recompensa')
       OR regexp_like(lower(table_name), 'ibk.?plus|ibkplus|plus'))
ORDER BY table_schema, table_name, column_name
