SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name   = 'pp_vc_ds_po_origpp'
  AND (column_name LIKE '%calib%' OR column_name LIKE '%nodo%'
    OR column_name LIKE '%driver%' OR column_name LIKE '%rd%'
    OR column_name LIKE '%ubi%'    OR column_name LIKE '%zona%'
    OR column_name LIKE '%target%' OR column_name LIKE '%alta%')
ORDER BY 1
