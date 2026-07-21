-- =====================================================================================
-- E4 | LA MAESTRA DE GIROS — ¿que es y esta vieja?
--
-- Responde "¿de que base sale?" y da los elementos para juzgar si esta desactualizada.
--   Tabla: e_perm_aws.t_mst_bpe_giros_restringidos
--   La usan IGUAL enviado_1 y enviado_2; lo que difiere entre ellos es el CIIU del cruce.
--
-- Historial (de los comentarios en target.txt y MaduracionV9) — pasaron por tres:
--   1. d_mdl_riesgos_disc.moa_Giro_restringido_BPE   (cod_actividadeconomica_t)
--   2. d_perm_aws.t_mst_bpe_giros_restringidos
--   3. e_perm_aws.t_mst_bpe_giros_restringidos       <- la vigente
--   Si campanias hoy mantiene una CUARTA, ahi esta el "desactualizado".
--
-- Bloque 1: columnas reales de la tabla (incluye si hay campo de fecha/vigencia)
-- Bloque 2: cuantos CIIU trae y como se reparten las etiquetas
-- Bloque 3: CIIU con etiqueta DUPLICADA — el max() del original los resuelve en silencio
--
-- READ-ONLY.
-- =====================================================================================

-- ---------- 1. columnas de la maestra ----------
SELECT '1. COLUMNA' AS bloque, column_name AS detalle, data_type AS valor
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name   = 't_mst_bpe_giros_restringidos'

UNION ALL

-- ---------- 2. tamano y reparto de etiquetas ----------
SELECT '2. ETIQUETA', coalesce(flag_aceptanuevos,'(null)'), cast(count(*) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos
GROUP BY 1,2

UNION ALL

SELECT '3. TOTAL', 'filas en la maestra', cast(count(*) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos
UNION ALL
SELECT '3. TOTAL', 'CIIU distintos', cast(count(DISTINCT codigoacteconomica) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos
UNION ALL
SELECT '3. TOTAL', 'CIIU con MAS DE UNA etiqueta (los resuelve el max)',
       cast(count(*) AS varchar)
FROM (SELECT codigoacteconomica
      FROM e_perm_aws.t_mst_bpe_giros_restringidos
      GROUP BY 1 HAVING count(DISTINCT flag_aceptanuevos) > 1)
UNION ALL
SELECT '3. TOTAL', 'longitud del codigo (min-max digitos)',
       cast(min(length(trim(codigoacteconomica))) AS varchar) || ' - ' ||
       cast(max(length(trim(codigoacteconomica))) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos
ORDER BY 1,2
