-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M2_cobertura_po.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M2_cobertura_po.sql
--   sha256  : e0238684c566   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : cuanto de la PO alcanza cada fuente — mide si flg_giro esta apagado
-- =====================================================================================
-- =====================================================================================
-- M2_cobertura_po.sql | cuanto de la PO alcanza REALMENTE cada fuente
--
-- M1 perfila cada tabla sola. Esta la cruza contra la PO y mide donde se pierde gente.
-- Replica la cadena de JOIN del ladder tal cual — no una aproximacion — para que el
-- numero sea el que de verdad se aplica en 20_flags_maestras.sql.
--
-- LA PREGUNTA QUE MOTIVA TODO ESTO
--   flg_giro sale de:   case when Giro_restringido = 1 then 1 else 0 end
--   y Giro_restringido: 'Restringido' -> 1 · 'Atendido' -> 0 · CUALQUIER OTRA COSA -> -1
--   Un CIIU que NO matchea la maestra cae en -1, que se mapea a flg_giro = 0:
--   pasa como CLEAN.
--   Con Rev_3 (5 digitos) vs Rev_4 (4 digitos) sin coincidencias, el no-match puede
--   ser masivo y estar APAGANDO el control entero sin que nada falle ni avise.
--   El bloque 3 lo mide. Es el numero mas importante de esta consulta.
--
-- MES DE REFERENCIA  p_codmes = '202606'  (cambiar en las 2 lineas <<<)
--   Un solo mes a proposito: la PO son ~4.2M/mes y esto cruza 7 fuentes.
--
-- COMO SE LEE
--   pct sobre la PO. Una cobertura baja NO es necesariamente un bug — no todo cliente
--   tiene RUC ni representante legal. Lo que importa es que el numero sea EXPLICABLE.
--   El que no admite explicacion benigna es el bloque 3.
--
-- ~16 filas. READ-ONLY.
-- =====================================================================================

WITH pob AS (
  SELECT cast(date_format(date_parse(p_codmes,'%Y%m') - interval '1' month,'%Y%m') AS varchar) AS codmes_ref,
         cast(tip_doc AS varchar) AS tip_doc,
         key_value
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes = '202606'                                            -- <<<
  GROUP BY 1,2,3
),

-- cadena SUNAT, verbatim de 20_flags_maestras.sql L160-176
sec_rk AS (
  SELECT *, RANK() OVER (PARTITION BY tip_doc, key_value
                         ORDER BY fecproceso, fecinicio, estadoregistro, ruc_value DESC) AS num
  FROM e_perm_aws.t_mst_sec_sunat_rsk
),
-- OJO de donde sale cada columna. El ladder hace `SELECT X.*` con X = princ_sunat,
-- asi que ciiu / tipcontribuyente / estadocontribuyente / fecbaja / ubigeo son TODAS
-- de t_mst_princ_sunat_rsk. De sec_sunat solo se usa key_value, y solo para armar
-- NRODOC cuando flg_ruc esta en (10,15,17).
-- (La version anterior de este archivo ponia Y.ciiu apuntando a sec_sunat: no existe.)
sunat AS (
  SELECT X.ruc_value, X.flg_ruc, X.fecalta2, X.ciiu,
         (CASE WHEN X.flg_ruc IN (10,15,17) THEN '1' ELSE '2' END)              AS tipdoc,
         (CASE WHEN X.flg_ruc IN (10,15,17) THEN Y.key_value ELSE X.ruc_value END) AS nrodoc
  FROM (SELECT a.*, cast(extract(year  from a.fecalta)*10000
                       + extract(month from a.fecalta)*100
                       + extract(day   from a.fecalta) AS varchar(8)) AS fecalta2
        FROM e_perm_aws.t_mst_princ_sunat_rsk a) X
  LEFT JOIN sec_rk Y
    ON X.ruc_value = Y.ruc_value AND Y.num = 1
  WHERE X.fecalta2 <> ''
),

giros AS (
  SELECT codigoacteconomica, max(flag_aceptanuevos) AS flag_aceptanuevos
  FROM e_perm_aws.t_mst_bpe_giros_restringidos
  GROUP BY 1
),

-- una fila por cliente de la PO, con el resultado de cada hop
x AS (
  SELECT p.tip_doc, p.key_value, p.codmes_ref,
         CASE WHEN s.nrodoc IS NULL THEN 0 ELSE 1 END AS hit_sunat,
         -- enmascarado por fecha: si el RUC nace DESPUES del corte, el ciiu no existia
         CASE WHEN s.nrodoc IS NULL THEN NULL
              WHEN CAST(SUBSTR(s.fecalta2,1,6) AS INTEGER) > cast(p.codmes_ref AS integer)
                   THEN 'SIN_DATO'
              ELSE s.ciiu END                                          AS ciiu_efectivo,
         g.flag_aceptanuevos,
         CASE WHEN r.key_value  IS NULL THEN 0 ELSE 1 END AS hit_reniec,
         CASE WHEN r.fec_nacimiento IS NULL THEN 0 ELSE 1 END AS tiene_fnac,
         CASE WHEN rl.ruc_value IS NULL THEN 0 ELSE 1 END AS hit_rl,
         CASE WHEN v.cliente_id IS NULL THEN 0 ELSE 1 END AS hit_vpc
  FROM pob p
  LEFT JOIN sunat s
    ON p.tip_doc = s.tipdoc AND p.key_value = s.nrodoc
  LEFT JOIN giros g
    ON g.codigoacteconomica = CASE
         WHEN s.nrodoc IS NULL THEN NULL
         WHEN CAST(SUBSTR(s.fecalta2,1,6) AS INTEGER) > cast(p.codmes_ref AS integer)
              THEN 'SIN_DATO'
         ELSE s.ciiu END
  LEFT JOIN e_perm_aws.t_mst_reniec_rsk r
    ON p.key_value = r.key_value AND p.tip_doc = r.tip_doc
  LEFT JOIN (SELECT ruc_value FROM e_perm_aws.t_mst_rep_legal_sunat_rsk GROUP BY 1) rl
    ON rl.ruc_value = p.key_value
  LEFT JOIN (SELECT b.cod_tipo_doc_val, b.num_doc_val, min(b.cliente_id) AS cliente_id
             FROM e_perm_aws.t_mst_vpc_myp_cliente_actual b
             GROUP BY 1,2) v
    ON v.cod_tipo_doc_val = p.tip_doc AND v.num_doc_val = p.key_value
)

-- ------------------------------------------------------------------ 1. la PO
SELECT '1. PO'  AS bloque, 'clientes en p_codmes 202606' AS detalle,
       cast(count(*) AS varchar) AS n, '' AS pct, '' AS nota
FROM x

-- ------------------------------------------------------------------ 2. SUNAT
UNION ALL SELECT '2. SUNAT', 'matchean la cadena princ+sec',
       cast(sum(hit_sunat) AS varchar),
       cast(round(100.0 * sum(hit_sunat) / nullif(count(*),0), 2) AS varchar) || ' %',
       'sin match -> tpoemp/estado/ciiu quedan NULL -> los 3 flags SUNAT dan 0 (pasa clean)'
FROM x
UNION ALL SELECT '2. SUNAT', 'con ciiu utilizable (no SIN_DATO, no vacio)',
       cast(count_if(ciiu_efectivo IS NOT NULL AND ciiu_efectivo <> 'SIN_DATO'
                 AND trim(ciiu_efectivo) <> '') AS varchar),
       cast(round(100.0 * count_if(ciiu_efectivo IS NOT NULL AND ciiu_efectivo <> 'SIN_DATO'
                 AND trim(ciiu_efectivo) <> '') / nullif(count(*),0), 2) AS varchar) || ' %',
       'lo que NO llega aqui ya no puede evaluarse contra la maestra de giros'
FROM x
UNION ALL SELECT '2. SUNAT', 'enmascarados por fecha (RUC posterior al corte)',
       cast(count_if(ciiu_efectivo = 'SIN_DATO') AS varchar),
       cast(round(100.0 * count_if(ciiu_efectivo = 'SIN_DATO') / nullif(count(*),0), 2) AS varchar) || ' %',
       'correcto: es el point-in-time funcionando'
FROM x

-- ------------------------------------------------------------------ 3. GIROS · el critico
UNION ALL SELECT '3. GIROS ***', 'con ciiu Y match en la maestra',
       cast(count_if(flag_aceptanuevos IS NOT NULL) AS varchar),
       cast(round(100.0 * count_if(flag_aceptanuevos IS NOT NULL) / nullif(count(*),0), 2) AS varchar) || ' %',
       'SI ESTO ES BAJO, flg_giro ESTA APAGADO'
FROM x
UNION ALL SELECT '3. GIROS ***', 'con ciiu pero SIN match -> Giro_restringido = -1',
       cast(count_if(ciiu_efectivo IS NOT NULL AND ciiu_efectivo <> 'SIN_DATO'
                 AND trim(ciiu_efectivo) <> '' AND flag_aceptanuevos IS NULL) AS varchar),
       cast(round(100.0 * count_if(ciiu_efectivo IS NOT NULL AND ciiu_efectivo <> 'SIN_DATO'
                 AND trim(ciiu_efectivo) <> '' AND flag_aceptanuevos IS NULL)
                 / nullif(count(*),0), 2) AS varchar) || ' %',
       'TIENE giro declarado pero la maestra no lo conoce -> pasa como CLEAN'
FROM x
UNION ALL SELECT '3. GIROS ***', 'estado devuelto: ' || coalesce(flag_aceptanuevos, '(sin match)'),
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 2) AS varchar) || ' %',
       CASE WHEN flag_aceptanuevos = 'Restringido' THEN 'flg_giro = 1  -> DIRTY'
            ELSE 'flg_giro = 0  -> pasa CLEAN' END
FROM x GROUP BY flag_aceptanuevos

-- ------------------------------------------------------------------ 4. el resto
UNION ALL SELECT '4. RENIEC', 'matchean',
       cast(sum(hit_reniec) AS varchar),
       cast(round(100.0 * sum(hit_reniec) / nullif(count(*),0), 2) AS varchar) || ' %',
       'alimenta flg_edad_tit y flg_esp_cny'
FROM x
UNION ALL SELECT '4. RENIEC', 'con fec_nacimiento no nula',
       cast(sum(tiene_fnac) AS varchar),
       cast(round(100.0 * sum(tiene_fnac) / nullif(count(*),0), 2) AS varchar) || ' %',
       'sin fecha -> flg_edad_tit = 0 (pasa clean)'
FROM x
UNION ALL SELECT '5. REP LEGAL', 'RUC con al menos un RL',
       cast(sum(hit_rl) AS varchar),
       cast(round(100.0 * sum(hit_rl) / nullif(count(*),0), 2) AS varchar) || ' %',
       'esperable que sea bajo: solo aplica a personas juridicas'
FROM x
UNION ALL SELECT '6. VPC', 'estan en el maestro de clientes VPC',
       cast(sum(hit_vpc) AS varchar),
       cast(round(100.0 * sum(hit_vpc) / nullif(count(*),0), 2) AS varchar) || ' %',
       'puerta de entrada a la lista de especiales'
FROM x
UNION ALL SELECT '7. PERSONERIA', 'PJJ (tip_doc = 2) vs PNN',
       cast(count_if(tip_doc = '2') AS varchar),
       cast(round(100.0 * count_if(tip_doc = '2') / nullif(count(*),0), 2) AS varchar) || ' %',
       'define que cadena de calibracion se aplica'
FROM x

ORDER BY 1, 2
