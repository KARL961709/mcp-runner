-- =====================================================================================
-- ORIGEN BPE PD · V2 · BUILD (crea tablas)
--   archivo : 00_drop_todo.sql
--   origen  : escrito nuevo
--   sha256  : e0e7f2228407   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : solo si hay que rehacer el ladder
-- =====================================================================================
-- ###
-- 00_drop_todo.sql | borra las 4 tablas del ladder, en orden inverso
--
-- CORRER SOLO si hay que rehacer el ladder completo. No es parte del flujo normal.
-- El orden importa: 40 depende de 30, que depende de 10 y 20.
-- ###
DROP TABLE IF EXISTS disc_model_owner.b46029_po_scoring_v1v2;
DROP TABLE IF EXISTS disc_model_owner.b46029_po_flg_clean;
DROP TABLE IF EXISTS disc_model_owner.b46029_po_flags_maestras;
DROP TABLE IF EXISTS disc_model_owner.b46029_po_flags_rcc;
