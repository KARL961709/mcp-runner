-- 04_columnas_scoring.sql | columnas llave y de score de las tablas candidatas para pd_raw (VC universe scr_vcadmbnk, BPE, altas_*_cal), para saber de donde sacar el score de estos clientes y con que llaves cruzar. READ-ONLY
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema IN ('disc_model_owner', 'd_perm_aws')
  AND ( table_name LIKE 'scr_vcadmbnk%'
     OR table_name LIKE '%admbankbpe%'
     OR table_name LIKE 'altas_%_cal' )
  AND ( lower(column_name) LIKE '%pd%'
     OR lower(column_name) LIKE '%prob%'
     OR lower(column_name) LIKE '%punt%'
     OR lower(column_name) LIKE '%score%'
     OR lower(column_name) IN ('key_value', 'tip_doc', 'cod_tip_doc', 'codmes', 'cod_mes', 'p_codmes', 'sub_producto', 'producto', 'modelo', 'personeria') )
ORDER BY table_name, column_name
