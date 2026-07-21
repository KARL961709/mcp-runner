-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/CALIB_0_sesgo_entidad.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\CALIB_0_sesgo_entidad.sql
--   sha256  : 03bc2f2049f7   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : mide cuantas altas IBK se pierden por el desempate de entidad del generador
-- =====================================================================================
-- =====================================================================================
-- CALIB_0_sesgo_entidad.sql | ¿cuantas altas IBK se pierden por el desempate de entidad?
--
-- EL PROBLEMA QUE MIDE
--   'altas monitoreo.txt' — el generador de t_dan_mrm_admbankbpe_altas_rep — hace:
--       left join (select * from morigbk_altas where alta2=1) b
--         on a.key_value=b.key_value and a.tip_doc=b.tip_doc      <- SIN entidad
--       RANK() OVER (PARTITION BY tip_doc,key_value ORDER BY cod_instit_financiera asc)
--       ... where rank = 1
--   morigbk_altas esta a grano cliente-ENTIDAD. El join es solo por cliente, asi que
--   abanica, y el rank se queda con el codigo de entidad MAS BAJO.
--   No es "donde ocurrio el alta": es un desempate arbitrario.
--   IBK es '00002', asi que gana contra todo SALVO '00001'. Un cliente que abrio en
--   ambos queda contado como '00001' y sale con flg_ibk = 0.
--   Las filas perdedoras NO se guardan -> en la tabla publicada esto es INVISIBLE.
--
-- POR QUE ESTA CONSULTA ES BARATA
--   1. alta2 NO necesita los 13 saldos. La cascada usa sumas acumuladas, pero con
--      saldos >= 0 se colapsa:
--        A-02 : saldo_mo_u1m + saldo_mo_u2m = 0
--             = saldo_m1 + (saldo_m1 + saldo_m2) = 0
--             = 2*saldo_m1 + saldo_m2 = 0   ->   saldo_m1 = 0 AND saldo_m2 = 0
--      y A-03..A-12 son mas estrictos. Asi que alta2 = (tipo_credito in 08,09,10)
--      AND saldo_m0 > 0 AND saldo_m1 = 0 AND saldo_m2 = 0.
--      El bloque 0 VERIFICA el supuesto saldo >= 0 del que depende esa equivalencia.
--   2. IBK solo pierde contra '00001' -> alcanza con dos entidades.
--   De 13 meses x todas las entidades  ->  3 meses x 2 entidades.
--
-- COHORTES  202601, 202602, 202603  (dentro de altas_rep, con RCC completo)
--   RCC leido: 202511..202603
--
-- COMO SE LEE
--   Bloque 2 es el numero: 'alta2 en IBK Y en 00001' son las altas IBK que la tabla
--   publicada atribuye a '00001'. Sobre 'alta2 en IBK (total)' da el % de perdida.
--   Bloque 3 contrasta contra la tabla publicada. NO tiene por que cuadrar exacto:
--   la publicada aplica ademas max_saldo>0 (sistema, sobre m1..m12) y la exclusion por
--   nombre de entidad, que aqui no se replican. Sirve para ver el orden de magnitud.
--
-- READ-ONLY. ~12 filas.
-- =====================================================================================

WITH coh (codmes) AS (VALUES ('202601'), ('202602'), ('202603')),

-- morigbk_tag: poblacion inicial. RCC del mes de cohorte, TODAS las entidades.
tag AS (
  SELECT codmes, tip_doc, key_value,
         CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                   AND cast(tipo_credito AS int) BETWEEN 8 AND 10 THEN
                CASE WHEN substr(cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                     WHEN substr(cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                     WHEN substr(cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                     WHEN substr(cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                     ELSE 'RESTO DD NEGOCIO' END
              WHEN substr(cod_cuenta_rcc,1,2)='72' AND substr(cod_cuenta_rcc,4,1)='5'
                   AND cast(tipo_credito AS int) BETWEEN 8 AND 10 THEN
                CASE WHEN substr(cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                     WHEN substr(cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                     ELSE 'RESTO LC NEGOCIO' END
              ELSE 'OTROS' END AS tg,
         CASE WHEN cod_instit_financiera IN
              ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
               '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580',
               '00581','00582','00583','00587','00588','00589','00592','00593','00594','00596',
               '00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes IN ('202601','202602','202603')
    AND codmes   IN ('202601','202602','202603')
),
pob AS (
  SELECT codmes, tip_doc, key_value
  FROM tag
  WHERE tg IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO')
    AND ent_honrada = 0
  GROUP BY 1,2,3
),

-- RCC de las dos entidades que compiten, ventana [M-2, M]
rcc2 AS (
  SELECT codmes, tip_doc, key_value, cod_instit_financiera, tipo_credito, saldo,
         CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN substr(cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                     WHEN substr(cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                     WHEN substr(cod_cuenta_rcc,4,1)='4'  THEN 'REFINANCIADOS'
                     ELSE 'RESTO DD' END
              WHEN substr(cod_cuenta_rcc,1,2)='72' AND substr(cod_cuenta_rcc,4,1)='5' THEN
                CASE WHEN substr(cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                     WHEN substr(cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                     ELSE 'RESTO LC' END
              ELSE 'OTROS' END AS tg
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202511' AND '202603'
    AND codmes   BETWEEN '202511' AND '202603'
    AND cod_instit_financiera IN ('00001','00002')
),
agg AS (   -- por mes, cliente, entidad
  SELECT codmes, tip_doc, key_value, cod_instit_financiera,
         min(CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10 THEN tipo_credito END) AS tipo_credito,
         sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10
                   AND tg IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO')
                  THEN saldo ELSE 0 END) AS saldo_mo,
         sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10
                   AND tg IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO')
                  THEN saldo ELSE 0 END) AS saldo_neg,
         min(saldo) AS saldo_min
  FROM rcc2
  GROUP BY 1,2,3,4
),
ent AS (   -- una fila por cohorte x cliente x entidad, con m0/m1/m2
  SELECT p.codmes, p.tip_doc, p.key_value, a.cod_instit_financiera,
         min(CASE WHEN a.codmes = p.codmes THEN a.tipo_credito END) AS tipo_credito,
         sum(CASE WHEN a.codmes = p.codmes THEN a.saldo_neg ELSE 0 END) AS saldo_m0,
         sum(CASE WHEN a.codmes = cast(date_format(date_parse(p.codmes,'%Y%m') - interval '1' month,'%Y%m') AS varchar)
                  THEN a.saldo_mo ELSE 0 END) AS saldo_m1,
         sum(CASE WHEN a.codmes = cast(date_format(date_parse(p.codmes,'%Y%m') - interval '2' month,'%Y%m') AS varchar)
                  THEN a.saldo_mo ELSE 0 END) AS saldo_m2
  FROM pob p
  JOIN agg a ON a.tip_doc = p.tip_doc AND a.key_value = p.key_value
  GROUP BY 1,2,3,4
),
alta AS (
  SELECT codmes, tip_doc, key_value, cod_instit_financiera,
         CASE WHEN tipo_credito IN ('08','09','10')
               AND saldo_m0 > 0 AND saldo_m1 = 0 AND saldo_m2 = 0
              THEN 1 ELSE 0 END AS alta2
  FROM ent
),
cli AS (   -- una fila por cohorte x cliente: donde tuvo alta2
  SELECT codmes, tip_doc, key_value,
         max(CASE WHEN cod_instit_financiera = '00002' THEN alta2 ELSE 0 END) AS a2_ibk,
         max(CASE WHEN cod_instit_financiera = '00001' THEN alta2 ELSE 0 END) AS a2_e1
  FROM alta
  GROUP BY 1,2,3
)

-- ------------------------------------------------- 0. el supuesto del que todo depende
SELECT '0. SUPUESTO' AS bloque, 'saldos negativos en el RCC leido' AS detalle,
       cast(count_if(saldo_min < 0) AS varchar) AS valor,
       'DEBE ser 0 — si no, alta2 != (m1=0 AND m2=0) y esta consulta no vale' AS criterio
FROM agg

-- ------------------------------------------------- 1. tamanio
UNION ALL SELECT '1. POBLACION', 'clientes-cohorte en la PO inicial',
       cast(count(*) AS varchar), '3 cohortes 202601-202603'
FROM pob

-- ------------------------------------------------- 2. EL NUMERO
UNION ALL SELECT '2. SESGO ***', 'alta2 en IBK (total real)',
       cast(count_if(a2_ibk = 1) AS varchar), 'lo que IBK origino de verdad'
FROM cli
UNION ALL SELECT '2. SESGO ***', 'alta2 en IBK y NO en 00001  -> queda IBK',
       cast(count_if(a2_ibk = 1 AND a2_e1 = 0) AS varchar), 'sobrevive el rank'
FROM cli
UNION ALL SELECT '2. SESGO ***', 'alta2 en IBK Y TAMBIEN en 00001  -> SE PIERDE',
       cast(count_if(a2_ibk = 1 AND a2_e1 = 1) AS varchar),
       cast(round(100.0 * count_if(a2_ibk = 1 AND a2_e1 = 1)
                / nullif(count_if(a2_ibk = 1), 0), 2) AS varchar)
       || ' % de las altas IBK  <-- ESTE ES EL SESGO'
FROM cli
UNION ALL SELECT '2. SESGO ***', 'alta2 solo en 00001',
       cast(count_if(a2_ibk = 0 AND a2_e1 = 1) AS varchar), 'no compiten con IBK'
FROM cli

-- ------------------------------------------------- 2b. abierto por cohorte
UNION ALL SELECT '2b. POR COHORTE', codmes,
       cast(count_if(a2_ibk = 1 AND a2_e1 = 1) AS varchar) || ' de '
       || cast(count_if(a2_ibk = 1) AS varchar),
       cast(round(100.0 * count_if(a2_ibk = 1 AND a2_e1 = 1)
                / nullif(count_if(a2_ibk = 1), 0), 2) AS varchar) || ' % perdido'
FROM cli GROUP BY codmes

-- ------------------------------------------------- 3. contra la tabla publicada
-- No tiene por que cuadrar exacto: la publicada aplica ademas max_saldo>0 (sistema,
-- sobre m1..m12) y la exclusion por nombre de entidad. Es orden de magnitud.
UNION ALL SELECT '3. VS PUBLICADA', 'IBK en t_dan_mrm_admbankbpe_altas_rep',
       cast(count(*) AS varchar), 'mismas 3 cohortes'
FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
WHERE p_codmes IN ('202601','202602','202603')
  AND cod_instit_financiera = '00002'
UNION ALL SELECT '3. VS PUBLICADA', 'mi "queda IBK" (bloque 2)',
       cast(count_if(a2_ibk = 1 AND a2_e1 = 0) AS varchar),
       'comparar con la fila de arriba'
FROM cli

ORDER BY 1, 2
