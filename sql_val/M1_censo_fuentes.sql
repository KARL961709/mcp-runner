-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M1_censo_fuentes.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M1_censo_fuentes.sql
--   sha256  : 2c8cca54b751   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : perfila cada fuente sola: grano, duplicados, rango
-- =====================================================================================
-- =====================================================================================
-- M1_censo_fuentes.sql | censo de cada fuente madre POR SEPARADO
--
-- No cruza nada: perfila cada tabla en su propio terreno. El cruce contra la PO es M2.
-- Usa SOLO columnas verificadas en el codigo del ladder — nada adivinado.
--
-- QUE MIRA EN CADA UNA
--   n_filas · n_claves · dup_grano · rango de periodo
--   dup_grano DEBE ser 0 donde el ladder asume una fila por clave. Si no lo es, un
--   LEFT JOIN de 20 esta multiplicando filas y nadie se entero.
--
-- VENTANA  p_codmes 202604..202606 en lo particionado (PO y RCC).
--          Las maestras no tienen particion: se leen enteras, son chicas.
--          Para mover la ventana, cambiar las 3 lineas marcadas <<<
--
-- El bloque 07 es el importante: t_mst_bpe_giros_restringidos abierta en canal.
-- Ahi se ve de un vistazo la mezcla Rev_3/Rev_4 y los estados de flag_aceptanuevos.
--
-- ~14 filas. READ-ONLY.
-- =====================================================================================

-- ------------------------------------------------------------------ 01 · la PO
SELECT '01 · e_perm_aws.scr_admbankbpe_rsk'                          AS fuente,
       cast(count(*) AS varchar)                                     AS n_filas,
       cast(count(DISTINCT coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'')) AS varchar)       AS n_claves,
       cast(count(*) - count(DISTINCT coalesce(p_codmes,'') || '|'
                        || coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'')) AS varchar)       AS dup_grano,
       'p_codmes ' || min(p_codmes) || '..' || max(p_codmes)
       || ' · pd_raw ' || cast(round(min(probabilidad), 6) AS varchar)
       || '..' || cast(round(max(probabilidad), 6) AS varchar)       AS detalle
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE p_codmes BETWEEN '202604' AND '202606'                          -- <<<

-- ------------------------------------------------------------------ 02 · RCC vigente
UNION ALL
SELECT '02 · e_perm_aws.t_fact_report_rcc_rsk',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(cast(codmes AS varchar),'') || '|'
                        || coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'') || '|'
                        || coalesce(cast(cod_cuenta_rcc AS varchar),'')) AS varchar),
       'codmes ' || cast(min(codmes) AS varchar) || '..' || cast(max(codmes) AS varchar)
       || ' · tipo_credito ' || cast(min(tipo_credito) AS varchar)
       || '..' || cast(max(tipo_credito) AS varchar)
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '202604' AND '202606'                          -- <<<

-- ------------------------------------------------------------------ 03 · RCC historico
-- La rama que el ladder deja MUERTA: su filtro es p_codmes <= '201812' dentro de una
-- ventana que arranca en 202211. Aqui se lee sin ese filtro, para saber que hay.
UNION ALL
SELECT '03 · d_perm_aws.t_fact_report_rcc_rsk  (rama muerta en el ladder)',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'')) AS varchar),
       '-',
       'p_codmes ' || cast(min(p_codmes) AS varchar) || '..' || cast(max(p_codmes) AS varchar)
FROM d_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '201801' AND '201812'                          -- <<<

-- ------------------------------------------------------------------ 04 · RENIEC
UNION ALL
SELECT '04 · e_perm_aws.t_mst_reniec_rsk',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(tip_doc,'') || '|' || coalesce(key_value,'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(tip_doc,'') || '|'
                        || coalesce(key_value,'')) AS varchar),
       'sin fec_nacimiento ' || cast(count_if(fec_nacimiento IS NULL) AS varchar)
       || ' · con conyuge ' || cast(count_if(trim(coalesce(tipdoc_conyugue,'')) <> ''
                                         AND trim(coalesce(coddoc_conyugue,'')) <> '') AS varchar)
FROM e_perm_aws.t_mst_reniec_rsk

-- ------------------------------------------------------------------ 05 · SUNAT principal
UNION ALL
SELECT '05 · e_perm_aws.t_mst_princ_sunat_rsk',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(ruc_value,'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(ruc_value,'')) AS varchar),
       'sin fecalta ' || cast(count_if(fecalta IS NULL) AS varchar)
       || ' · flg_ruc distintos ' || cast(count(DISTINCT flg_ruc) AS varchar)
FROM e_perm_aws.t_mst_princ_sunat_rsk

-- ------------------------------------------------------------------ 06 · SUNAT secundaria
UNION ALL
SELECT '06 · e_perm_aws.t_mst_sec_sunat_rsk',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(ruc_value,'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(ruc_value,'')) AS varchar),
       'ojo: el ladder la desempata con RANK() por tip_doc,key_value — dup por ruc_value es ESPERADO'
FROM e_perm_aws.t_mst_sec_sunat_rsk

-- ------------------------------------------------------------------ 07 · GIROS · el critico
UNION ALL
SELECT '07 · e_perm_aws.t_mst_bpe_giros_restringidos',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(codigoacteconomica,'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(codigoacteconomica,'')) AS varchar),
       'estados: ' || array_join(array_agg(DISTINCT coalesce(flag_aceptanuevos,'(null)')), ' / ')
FROM e_perm_aws.t_mst_bpe_giros_restringidos

-- 07b · la mezcla de revisiones, medida. 5 digitos = Rev_3, 4 digitos = Rev_4.
-- El ladder hace `a.ciiu = c.codigoacteconomica`: si el ciiu que trae SUNAT esta en una
-- revision y la maestra en la otra, NO matchea y el cliente sale con Giro_restringido=-1,
-- que el codigo mapea a flg_giro=0 -> pasa como CLEAN.
UNION ALL
SELECT '07b · giros · largo del codigo (5=Rev_3, 4=Rev_4)',
       cast(count(*) AS varchar),
       cast(count_if(length(trim(coalesce(codigoacteconomica,''))) = 5) AS varchar),
       cast(count_if(length(trim(coalesce(codigoacteconomica,''))) = 4) AS varchar),
       'n_filas / de-5-digitos / de-4-digitos  ·  otros largos: '
       || cast(count_if(length(trim(coalesce(codigoacteconomica,''))) NOT IN (4,5)) AS varchar)
FROM e_perm_aws.t_mst_bpe_giros_restringidos

-- 07c · cuantos RESTRINGIDOS hay por revision. Si los Restringido viven casi todos en
-- una sola revision, el sesgo del no-match no es neutro: apaga el control.
UNION ALL
SELECT '07c · giros · Restringido por revision',
       cast(count_if(flag_aceptanuevos = 'Restringido') AS varchar),
       cast(count_if(flag_aceptanuevos = 'Restringido'
                 AND length(trim(coalesce(codigoacteconomica,''))) = 5) AS varchar),
       cast(count_if(flag_aceptanuevos = 'Restringido'
                 AND length(trim(coalesce(codigoacteconomica,''))) = 4) AS varchar),
       'total Restringido / en Rev_3 / en Rev_4'
FROM e_perm_aws.t_mst_bpe_giros_restringidos

-- ------------------------------------------------------------------ 08 · rep legal
UNION ALL
SELECT '08 · e_perm_aws.t_mst_rep_legal_sunat_rsk',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(ruc_value,'')) AS varchar),
       '-',
       'RL por RUC (prom) ' || cast(round(1.0 * count(*)
                                    / nullif(count(DISTINCT ruc_value), 0), 2) AS varchar)
       || ' · sin fec_vigencia ' || cast(count_if(fec_vigencia IS NULL) AS varchar)
FROM e_perm_aws.t_mst_rep_legal_sunat_rsk

-- ------------------------------------------------------------------ 09 · VPC negativos
UNION ALL
SELECT '09 · e_perm_aws.t_rel_vpc_myp_clientenegativo',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(cast(cliente_id AS varchar),'')) AS varchar),
       '-',
       'cod_tipo_val usados (1,2,3): '
       || cast(count_if(cod_tipo_val IN ('1','2','3')) AS varchar)
       || ' · sin fecha_habilita (siguen negativos) '
       || cast(count_if(trim(coalesce(fecha_habilita_dt,'')) = '') AS varchar)
FROM e_perm_aws.t_rel_vpc_myp_clientenegativo

-- ------------------------------------------------------------------ 10 · VPC actual
UNION ALL
SELECT '10 · e_perm_aws.t_mst_vpc_myp_cliente_actual',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(cast(cliente_id AS varchar),'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(cast(cliente_id AS varchar),'')) AS varchar),
       'dup por cliente_id rompe el JOIN de especiales — debe ser 0'
FROM e_perm_aws.t_mst_vpc_myp_cliente_actual

-- ------------------------------------------------------------------ 11 · calibracion
UNION ALL
SELECT '11 · disc_model_owner.bnbpe_ibk_calib_src  (congelada)',
       cast(count(*) AS varchar),
       cast(count(DISTINCT coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'')) AS varchar),
       cast(count(*) - count(DISTINCT coalesce(cast(codmes AS varchar),'') || '|'
                        || coalesce(cast(tip_doc AS varchar),'') || '|'
                        || coalesce(key_value,'')) AS varchar),
       'codmes ' || cast(min(cast(codmes AS int)) AS varchar)
       || '..' || cast(max(cast(codmes AS int)) AS varchar)
       || ' · con target ' || cast(count_if(target_12m IS NOT NULL) AS varchar)
FROM disc_model_owner.bnbpe_ibk_calib_src

ORDER BY 1
