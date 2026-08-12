-- 73_gdp_rcc_ppe_donde.sql | la PO de produccion lee e_perm_aws.T_GDP_RCC_PPE pero el volcado de esquema solo la encontro en d_perm_aws. Se busca en TODOS los esquemas sin filtrar, para saber si la referencia esta rota o si la tabla vive en otro lado
SELECT table_schema,
       table_name,
       count(*)  AS n_cols
FROM information_schema.columns
WHERE lower(table_name) LIKE '%gdp_rcc_ppe%'
   OR lower(table_name) LIKE '%rcc_ppe%'
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name
