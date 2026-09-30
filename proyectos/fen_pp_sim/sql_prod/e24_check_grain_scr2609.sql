-- e24_check_grain_scr2609.sql | CONFIRMA el grano de la fuente antes de crear e25.
-- Crea disc_model_owner.fen_check_grain_2609 con las key_value que tienen MAS de 1 fila.
-- INTERPRETACION por _resumen.txt (columna filas):
--   filas = 0  -> fuente 1:1 (1 fila por key_value) -> OK, se puede correr e25 tal cual.
--   filas > 0  -> hay duplicados -> NO correr e25; avisar para meter dedup/filtro PP.
-- Rerun: correr e24b_drop_check antes.
-- Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_prod -Only e24_check_grain_scr2609
CREATE TABLE disc_model_owner.fen_check_grain_2609
WITH (format = 'PARQUET') AS
SELECT key_value, count(*) AS c
FROM d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609
GROUP BY key_value
HAVING count(*) > 1
