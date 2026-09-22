-- 0_drop_v1v2v3_escopt.sql | borra la tabla escopt antes de re-crearla con los factores nuevos (PJJ 0.65 / PNN 0.79). Correr ANTES de 5_po_v1v2v3_escopt.sql. Athena no tiene CREATE OR REPLACE para tablas, por eso el drop va aparte
DROP TABLE IF EXISTS disc_model_owner.b46029_po_scoring_v1v2v3_202607
