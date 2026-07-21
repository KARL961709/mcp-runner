-- =====================================================================================
-- ORIGEN BPE PD · V2 · BUILD (crea tablas)
--   archivo : 00_drop_todo.sql
--   origen  : escrito nuevo
--   sha256  : e5ad502ff598   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : solo si hay que rehacer el ladder
-- =====================================================================================
-- ###
-- 00_drop_todo.sql | borra las 4 tablas del ladder, en orden inverso
--
-- CORRER SOLO si hay que rehacer el ladder completo. No es parte del flujo normal.
-- El orden importa: 40 depende de 30, que depende de 10 y 20.
-- ###
-- OJO los nombres: son flg_ en singular, no flags_. Un DROP con el nombre
-- equivocado corre limpio (IF EXISTS) sin borrar nada, y recien falla el peldanio
-- siguiente con "la tabla ya existe". Verificado contra el CREATE de cada peldanio.
DROP TABLE IF EXISTS disc_model_owner.b46029_po_scoring_v1v2;
DROP TABLE IF EXISTS disc_model_owner.b46029_po_flg_clean;
DROP TABLE IF EXISTS disc_model_owner.b46029_po_flg_maestras;
DROP TABLE IF EXISTS disc_model_owner.b46029_po_flg_rcc;
