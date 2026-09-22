-- e15_dep_ambos_lados.sql | por que el join por nombre da 0: muestra los DEPARTAMENTOS crudos de ambos lados.
--   grado_elnino_ubigeo_v3.departamento  vs  t_mst_reniec_rsk.dep_ubi_domicilio  (valor + conteo).
--   Si un lado son NOMBRES (PIURA) y el otro CODIGOS (20) -> ahi esta el 0. Read-only.
-- Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e15_dep_ambos_lados
WITH g AS (
  SELECT 'grado' AS src, CAST(departamento AS varchar) AS dep, COUNT(*) AS n
  FROM disc_model_owner.grado_elnino_ubigeo_v3
  GROUP BY 1, 2
),
r AS (
  SELECT 'reniec' AS src, CAST(dep_ubi_domicilio AS varchar) AS dep, COUNT(*) AS n
  FROM e_perm_aws.t_mst_reniec_rsk
  GROUP BY 1, 2
)
SELECT src, dep, n FROM g
UNION ALL
SELECT src, dep, n FROM r
ORDER BY src, n DESC
