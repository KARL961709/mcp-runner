-- 01. ESQUEMA DE scr_vcnbank_rsk
--   nombre y tipo de cada columna. Sin esto no se puede escribir el CTAS: los
--   numericos de esta tabla vienen como texto y 40_pdraw los envuelve en
--   TRY_CAST, asi que el tipo hay que MEDIRLO, no suponerlo
SELECT ordinal_position,
       column_name,
       data_type
  FROM information_schema.columns
 WHERE table_schema = 'e_perm_aws'
   AND table_name   = 'scr_vcnbank_rsk'
 ORDER BY ordinal_position
