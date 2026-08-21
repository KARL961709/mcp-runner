-- 127_catalogo_tablas_scoring.sql | lista las tablas de disc_model_owner ligadas a scoring/po/bpe/v1v2/v3/escopt para ver que EXISTE realmente en el banco (v3 incluido). READ-ONLY
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'disc_model_owner'
  AND ( table_name LIKE '%scoring%'
     OR table_name LIKE '%v1v2%'
     OR table_name LIKE '%v3%'
     OR table_name LIKE '%escopt%'
     OR table_name LIKE '%admbankbpe%'
     OR table_name LIKE 'b46029%'
     OR table_name LIKE '%bankbn%'
     OR table_name LIKE '%prospect%' )
ORDER BY table_name
