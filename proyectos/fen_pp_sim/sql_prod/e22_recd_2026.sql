-- e22_recd_2026.sql | tabla lookup rec_d (RECUPERACION, canal A_d del overlay FEN) por dep_inei
-- Metodo 2 pasos: (1) nivel base por rango de meses de recuperacion del analogo Yaku (Resiliente 1.0 .. Lenta 0.25),
--   (2) ajuste por la pendiente 2026 (simetrico, paso 0.125). Fuente: IBK+ donde hay serie, inflacion (IPC) donde no.
-- Entra al motor como A_d = 1 - wrec*rec_d[dep_inei]. dep_inei 2 char (formato e10). '00' = sin geo (fallback 1.0).
-- Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_prod -Only e22_recd_2026   (rebuild: -Only e22b_drop_recd_2026 antes)
CREATE TABLE disc_model_owner.fen_recd_2026
WITH (format = 'PARQUET') AS
SELECT dep_inei, rec_d
FROM (VALUES
  ('00',1.0),
  ('01',0.75),
  ('02',0.75),
  ('03',0.5),
  ('04',0.875),
  ('05',0.875),
  ('06',0.25),
  ('07',0.875),
  ('08',1.0),
  ('09',0.375),
  ('10',1.0),
  ('11',0.375),
  ('12',0.75),
  ('13',0.875),
  ('14',0.625),
  ('15',0.875),
  ('16',0.5),
  ('17',0.375),
  ('18',0.875),
  ('19',0.75),
  ('20',0.625),
  ('21',0.375),
  ('22',0.5),
  ('23',1.0),
  ('24',0.5),
  ('25',1.0)
) AS t(dep_inei, rec_d)