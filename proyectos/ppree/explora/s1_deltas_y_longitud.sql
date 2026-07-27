-- ============================================================================
-- S1. Las dos mediciones que faltan antes de dar el gate por bueno.
--   (a) F1: agregue LENGTH(key_value)=64 a la PO y el Recibido NO lo tiene.
--       Nada cuenta las filas que se caen. Aca el conteo, por anio y fuente.
--   (b) v9 dio gtia_hip=143 contra 130 firmado y malo_sf=61 contra 63.
--       El n firmado se midio sobre el perimetro de la marca; este sobre la
--       tabla construida. O se explica el delta o uno de los dos esta mal.
-- ============================================================================
SELECT 'A_longitud_llave' AS bloque,
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                       AS anio,
       COUNT(*)                                                    AS n_total,
       SUM(CASE WHEN LENGTH(CAST(key_value AS VARCHAR)) = 64 THEN 1 ELSE 0 END) AS n_len64,
       SUM(CASE WHEN key_value IS NULL THEN 1 ELSE 0 END)          AS n_null,
       SUM(CASE WHEN LENGTH(CAST(key_value AS VARCHAR)) NOT IN (64) THEN 1 ELSE 0 END) AS n_descartadas,
       CAST(MIN(LENGTH(CAST(key_value AS VARCHAR))) AS VARCHAR)    AS len_min,
       CAST(MAX(LENGTH(CAST(key_value AS VARCHAR))) AS VARCHAR)    AS len_max
FROM d_perm_aws.ds_compppibk_rsk
WHERE CAST(codmes AS INT) BETWEEN 201902 AND 202012
GROUP BY 1, 2
UNION ALL
SELECT 'A_longitud_llave_e',
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4),
       COUNT(*),
       SUM(CASE WHEN LENGTH(CAST(key_value AS VARCHAR)) = 64 THEN 1 ELSE 0 END),
       SUM(CASE WHEN key_value IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN LENGTH(CAST(key_value AS VARCHAR)) NOT IN (64) THEN 1 ELSE 0 END),
       CAST(MIN(LENGTH(CAST(key_value AS VARCHAR))) AS VARCHAR),
       CAST(MAX(LENGTH(CAST(key_value AS VARCHAR))) AS VARCHAR)
FROM e_perm_aws.scr_compppibk_rsk
WHERE CAST(codmes AS INT) BETWEEN 202101 AND 202607
GROUP BY 1, 2
UNION ALL
SELECT 'B_delta_filtros',
       SUBSTR(f.codmes_mrm, 1, 4),
       SUM(f.flg_scope_ree),
       SUM(CASE WHEN f.flg_scope_ree = 1 THEN f.filtro_gtia_hip ELSE 0 END),
       SUM(CASE WHEN f.flg_scope_ree = 1 THEN f.filtro_malo_sf  ELSE 0 END),
       SUM(CASE WHEN f.flg_scope_ree = 1 AND f.filtro_gtia_hip = 1 AND CAST(f.codmes_mrm AS INT) > 202604 THEN 1 ELSE 0 END),
       CAST(SUM(CASE WHEN f.flg_scope_ree = 1 AND f.filtro_malo_sf = 1 AND f.valida_scope = 0 THEN 1 ELSE 0 END) AS VARCHAR),
       CAST(SUM(CASE WHEN f.flg_scope_ree = 1 AND f.falla_foto_t0 = 1 THEN 1 ELSE 0 END) AS VARCHAR)
FROM disc_model_owner.ds_stk_ree_pp_60_filtros f
GROUP BY 1, 2
ORDER BY 1, 2
