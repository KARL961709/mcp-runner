-- qa_01_integridad.sql | QA de INTEGRIDAD de la tabla creada b46029_desemb_cal_202609 (y sus fuentes base/target). Cada fila es un chequeo: bloque, chequeo, valor, esperado, estado. Valida grano sin duplicados, reconciliacion de filas, rango pd_raw, as-of sin look-ahead, coherencia sin_pd, target monotono y binario (tolerando NULL de horizontes inmaduros), madurez en rango, frontera RCC unica, y que el insumo no pierda filas ni quede sin fila de target. READ-ONLY. Corre despues del build de sql_prod
WITH mb AS (
  SELECT count(*) AS n,
         count(DISTINCT concat(cast(cod_mes AS varchar), '|', cod_tip_doc, '|', key_value, '|', desc_producto)) AS n_dist,
         coalesce(min(pd_raw), 0) AS pmin, coalesce(max(pd_raw), 0) AS pmax,
         coalesce(min(lag_meses), 0) AS lagmin,
         sum(CASE WHEN (sin_pd = 1 AND pd_raw IS NOT NULL) OR (sin_pd = 0 AND pd_raw IS NULL) THEN 1 ELSE 0 END) AS incoh
  FROM disc_model_owner.b46029_desemb_base_202609
),
mt AS (
  SELECT count(*) AS n,
         count(DISTINCT concat(cast(cod_mes AS varchar), '|', cod_tip_doc, '|', key_value)) AS n_dist,
         sum(CASE WHEN target_01m > target_02m OR target_02m > target_03m OR target_03m > target_04m
                    OR target_04m > target_05m OR target_05m > target_06m OR target_06m > target_07m
                    OR target_07m > target_08m OR target_08m > target_09m OR target_09m > target_10m
                    OR target_10m > target_11m OR target_11m > target_12m THEN 1 ELSE 0 END) AS no_mono,
         sum(CASE WHEN target_01m NOT IN (0,1) OR target_02m NOT IN (0,1) OR target_03m NOT IN (0,1)
                    OR target_04m NOT IN (0,1) OR target_05m NOT IN (0,1) OR target_06m NOT IN (0,1)
                    OR target_07m NOT IN (0,1) OR target_08m NOT IN (0,1) OR target_09m NOT IN (0,1)
                    OR target_10m NOT IN (0,1) OR target_11m NOT IN (0,1) OR target_12m NOT IN (0,1) THEN 1 ELSE 0 END) AS no_bin,
         min(meses_madurez) AS mmin, max(meses_madurez) AS mmax,
         count(DISTINCT rcc_frontera) AS n_fr, max(rcc_frontera) AS fr
  FROM disc_model_owner.b46029_desemb_target_202609
),
mc AS (
  SELECT count(*) AS n,
         sum(CASE WHEN meses_madurez IS NULL THEN 1 ELSE 0 END) AS sin_fila_target,
         coalesce(min(lag_meses), 0) AS lagmin,
         sum(CASE WHEN (sin_pd = 1 AND pd_raw IS NOT NULL) OR (sin_pd = 0 AND pd_raw IS NULL) THEN 1 ELSE 0 END) AS incoh
  FROM disc_model_owner.b46029_desemb_cal_202609
),
msrc AS (
  SELECT count(*) AS n FROM (
    SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc, key_value, desc_producto FROM d_perm_aws.user_desembolso
  ) z
),
msrcraw AS (
  SELECT count(*) AS n FROM d_perm_aws.user_desembolso
)
SELECT bloque, chequeo, valor, esperado, estado FROM (
  SELECT 'BASE' AS bloque, '1 grano sin duplicados' AS chequeo, cast(mb.n AS varchar) AS valor, cast(mb.n_dist AS varchar) AS esperado, CASE WHEN mb.n = mb.n_dist THEN 'OK' ELSE 'FALLA' END AS estado FROM mb
  UNION ALL SELECT 'BASE', '2 filas = fuente distinct', cast(mb.n AS varchar), cast(msrc.n AS varchar), CASE WHEN mb.n = msrc.n THEN 'OK' ELSE 'FALLA' END FROM mb, msrc
  UNION ALL SELECT 'BASE', '2b fuente RAW cubierta 1a1', cast(msrcraw.n AS varchar), cast(msrc.n AS varchar), CASE WHEN msrcraw.n = msrc.n THEN 'OK (1a1)' ELSE 'REVISAR (hay grano repetido, se agrego)' END FROM msrcraw, msrc
  UNION ALL SELECT 'BASE', '3 pd_raw en [0,1]', concat(cast(round(mb.pmin, 4) AS varchar), '..', cast(round(mb.pmax, 4) AS varchar)), '0..1', CASE WHEN mb.pmin >= 0 AND mb.pmax <= 1 THEN 'OK' ELSE 'FALLA' END FROM mb
  UNION ALL SELECT 'BASE', '4 as-of sin look-ahead lag>=0', cast(mb.lagmin AS varchar), '>=0', CASE WHEN mb.lagmin >= 0 THEN 'OK' ELSE 'FALLA' END FROM mb
  UNION ALL SELECT 'BASE', '5 sin_pd coherente', cast(mb.incoh AS varchar), '0', CASE WHEN mb.incoh = 0 THEN 'OK' ELSE 'FALLA' END FROM mb
  UNION ALL SELECT 'TARGET', '1 grano sin duplicados', cast(mt.n AS varchar), cast(mt.n_dist AS varchar), CASE WHEN mt.n = mt.n_dist THEN 'OK' ELSE 'FALLA' END FROM mt
  UNION ALL SELECT 'TARGET', '2 target monotono', cast(mt.no_mono AS varchar), '0', CASE WHEN mt.no_mono = 0 THEN 'OK' ELSE 'FALLA' END FROM mt
  UNION ALL SELECT 'TARGET', '3 target binario (0/1 o NULL)', cast(mt.no_bin AS varchar), '0', CASE WHEN mt.no_bin = 0 THEN 'OK' ELSE 'FALLA' END FROM mt
  UNION ALL SELECT 'TARGET', '4 meses_madurez [0,12]', concat(cast(mt.mmin AS varchar), '..', cast(mt.mmax AS varchar)), '0..12', CASE WHEN mt.mmin >= 0 AND mt.mmax <= 12 THEN 'OK' ELSE 'FALLA' END FROM mt
  UNION ALL SELECT 'TARGET', '5 frontera RCC unica', concat(cast(mt.n_fr AS varchar), ' fr=', cast(mt.fr AS varchar)), '1', CASE WHEN mt.n_fr = 1 THEN 'OK' ELSE 'FALLA' END FROM mt
  UNION ALL SELECT 'INSUMO', '1 filas = base', cast(mc.n AS varchar), cast(mb.n AS varchar), CASE WHEN mc.n = mb.n THEN 'OK' ELSE 'FALLA' END FROM mc, mb
  UNION ALL SELECT 'INSUMO', '2 todas con fila target', cast(mc.sin_fila_target AS varchar), '0', CASE WHEN mc.sin_fila_target = 0 THEN 'OK' ELSE 'FALLA' END FROM mc
  UNION ALL SELECT 'INSUMO', '3 as-of sin look-ahead', cast(mc.lagmin AS varchar), '>=0', CASE WHEN mc.lagmin >= 0 THEN 'OK' ELSE 'FALLA' END FROM mc
  UNION ALL SELECT 'INSUMO', '4 sin_pd coherente', cast(mc.incoh AS varchar), '0', CASE WHEN mc.incoh = 0 THEN 'OK' ELSE 'FALLA' END FROM mc
) q
ORDER BY bloque, chequeo
