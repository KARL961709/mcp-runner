-- cmp_src_list.sql | tablas disc_model_owner candidatas a ser la fuente de la enviada (v2n/scoring/rsk_cal/po). Agregado.
SELECT table_name FROM information_schema.tables
WHERE table_schema='disc_model_owner'
  AND (table_name LIKE '%v2n%' OR table_name LIKE '%po_scoring%' OR table_name LIKE '%admbankbpe%' OR table_name LIKE '%rsk_cal%')
ORDER BY table_name
