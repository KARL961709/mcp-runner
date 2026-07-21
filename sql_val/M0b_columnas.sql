-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M0b_columnas.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M0b_columnas.sql
--   sha256  : 4abca778e9d8   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : GATE: verifica que exista cada columna que usan M1/M2/M3. Correr antes
-- =====================================================================================
-- =====================================================================================
-- M0b_columnas.sql | GATE: verifica que exista cada columna que usan M1, M2 y M3
--
-- POR QUE EXISTE
--   M2 fallo con "y.ciiu not found". La causa: asumi que ciiu venia de sec_sunat
--   cuando el ladder hace `SELECT X.*` con X = princ_sunat. Fue asumir en vez de leer.
--   Este archivo convierte esa clase de error en algo que se detecta ANTES de correr:
--   lista una por una las columnas de las que dependen M1/M2/M3 y dice cuales faltan.
--
-- CORRER ANTES QUE M1/M2/M3. Solo lee metadata: instantaneo, sin riesgo.
--
-- COMO SE LEE
--   Las filas con '*** FALTA ***' salen PRIMERO. Si hay alguna, la consulta que la usa
--   va a fallar: hay que arreglarla antes de gastar tiempo de motor.
--   Si no hay ninguna, M1/M2/M3 estan libres de este tipo de error.
--
-- ~55 filas. READ-ONLY.
-- =====================================================================================

WITH usadas (tabla, columna, usada_en) AS (VALUES
  -- poblacion
  ('e_perm_aws.scr_admbankbpe_rsk',            'p_codmes',              'M1 M2'),
  ('e_perm_aws.scr_admbankbpe_rsk',            'tip_doc',               'M1 M2'),
  ('e_perm_aws.scr_admbankbpe_rsk',            'key_value',             'M1 M2'),
  ('e_perm_aws.scr_admbankbpe_rsk',            'probabilidad',          'M1'),
  -- RCC vigente
  ('e_perm_aws.t_fact_report_rcc_rsk',         'p_codmes',              'M1'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'codmes',                'M1'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'tip_doc',               'M1'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'key_value',             'M1'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'cod_cuenta_rcc',        'M1'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'tipo_credito',          'M1'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'saldo',                 'ladder'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'condicion',             'ladder'),
  ('e_perm_aws.t_fact_report_rcc_rsk',         'cod_clasificacion_deudor','ladder'),
  -- RCC historico (rama muerta en el ladder)
  ('d_perm_aws.t_fact_report_rcc_rsk',         'p_codmes',              'M1'),
  ('d_perm_aws.t_fact_report_rcc_rsk',         'tip_doc',               'M1'),
  ('d_perm_aws.t_fact_report_rcc_rsk',         'key_value',             'M1'),
  -- RENIEC
  ('e_perm_aws.t_mst_reniec_rsk',              'tip_doc',               'M1 M2'),
  ('e_perm_aws.t_mst_reniec_rsk',              'key_value',             'M1 M2'),
  ('e_perm_aws.t_mst_reniec_rsk',              'fec_nacimiento',        'M1 M2'),
  ('e_perm_aws.t_mst_reniec_rsk',              'tipdoc_conyugue',       'M1'),
  ('e_perm_aws.t_mst_reniec_rsk',              'coddoc_conyugue',       'M1'),
  -- SUNAT principal — de AQUI salen ciiu y los atributos, no de la secundaria
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'ruc_value',             'M1 M2'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'tip_doc',               'M2'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'key_value',             'M2'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'flg_ruc',               'M1 M2'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'fecalta',               'M1 M2'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'ciiu',                  'M2  <-- el que fallo'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'tipcontribuyente',      'ladder'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'estadocontribuyente',   'ladder'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'fecbaja',               'ladder'),
  ('e_perm_aws.t_mst_princ_sunat_rsk',         'ubigeo',                'ladder'),
  -- SUNAT secundaria — solo aporta key_value para armar NRODOC
  ('e_perm_aws.t_mst_sec_sunat_rsk',           'ruc_value',             'M1 M2'),
  ('e_perm_aws.t_mst_sec_sunat_rsk',           'tip_doc',               'M1 M2'),
  ('e_perm_aws.t_mst_sec_sunat_rsk',           'key_value',             'M1 M2'),
  ('e_perm_aws.t_mst_sec_sunat_rsk',           'fecproceso',            'M2'),
  ('e_perm_aws.t_mst_sec_sunat_rsk',           'fecinicio',             'M2'),
  ('e_perm_aws.t_mst_sec_sunat_rsk',           'estadoregistro',        'M2'),
  -- giros
  ('e_perm_aws.t_mst_bpe_giros_restringidos',  'codigoacteconomica',    'M1 M2'),
  ('e_perm_aws.t_mst_bpe_giros_restringidos',  'flag_aceptanuevos',     'M1 M2'),
  -- representante legal
  ('e_perm_aws.t_mst_rep_legal_sunat_rsk',     'ruc_value',             'M1 M2'),
  ('e_perm_aws.t_mst_rep_legal_sunat_rsk',     'key_value',             'ladder'),
  ('e_perm_aws.t_mst_rep_legal_sunat_rsk',     'tip_doc',               'ladder'),
  ('e_perm_aws.t_mst_rep_legal_sunat_rsk',     'fec_vigencia',          'M1'),
  -- VPC
  ('e_perm_aws.t_rel_vpc_myp_clientenegativo', 'cliente_id',            'M1'),
  ('e_perm_aws.t_rel_vpc_myp_clientenegativo', 'fecha_dt',              'M1'),
  ('e_perm_aws.t_rel_vpc_myp_clientenegativo', 'fecha_habilita_dt',     'M1'),
  ('e_perm_aws.t_rel_vpc_myp_clientenegativo', 'cod_tipo_val',          'M1'),
  ('e_perm_aws.t_mst_vpc_myp_cliente_actual',  'cliente_id',            'M1 M2'),
  ('e_perm_aws.t_mst_vpc_myp_cliente_actual',  'cod_tipo_doc_val',      'M2'),
  ('e_perm_aws.t_mst_vpc_myp_cliente_actual',  'num_doc_val',           'M2'),
  -- base congelada de calibracion
  ('disc_model_owner.bnbpe_ibk_calib_src',     'codmes',                'M1 M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'tip_doc',               'M1 M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'key_value',             'M1 M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'target_12m',            'M1 M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'flg_ibk',               'M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'top4_entidad',          'M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'flg_calib_m2',          'M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'flg_impulsa',           'M3'),
  ('disc_model_owner.bnbpe_ibk_calib_src',     'flg_reactiva_puro',     'M3')
)

SELECT
  CASE WHEN c.column_name IS NULL THEN '*** FALTA ***' ELSE 'ok' END  AS estado,
  u.tabla,
  u.columna,
  coalesce(c.data_type, '-')                                          AS tipo,
  u.usada_en
FROM usadas u
LEFT JOIN information_schema.columns c
  ON  lower(c.table_schema || '.' || c.table_name) = lower(u.tabla)
  AND lower(c.column_name)                        = lower(u.columna)
ORDER BY CASE WHEN c.column_name IS NULL THEN 0 ELSE 1 END,
         u.tabla, u.columna
