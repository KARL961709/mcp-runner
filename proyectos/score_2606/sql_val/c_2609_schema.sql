-- c_2609_schema. Esquema de la fuente nueva disc_riesgos.scr_vcbankv3_repro_ (202609).
--   Confirma que existan las llaves que usa el pipeline: probabilidad, codmes, cod_tip_doc, key_value.
--   Si nombran distinto (es vcbankv3, otra fuente), se adapta el driver de u01_dirty/u01_nodos.
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_riesgos' AND table_name = 'scr_vcbankv3_repro_'
ORDER BY ordinal_position
