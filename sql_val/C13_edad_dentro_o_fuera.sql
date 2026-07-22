-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C13_edad_dentro_o_fuera.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C13_edad_dentro_o_fuera.sql
--   sha256  : f7ca43df432a   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : mismo test que giro para edad_tit/edad_rl: RD historica decide si se libera
-- =====================================================================================
-- =====================================================================================
-- C13_edad_dentro_o_fuera.sql | ¿flg_edad debe seguir siendo exclusion? (mismo test que giro)
--
-- CONTEXTO
--   La familia edad en el dirty (C12) tiene RD 7.58%, por debajo del clean (8.57%). Igual
--   que el giro antes de liberarlo, huele a POLITICA de elegibilidad, no a riesgo.
--   Son DOS flags distintos y hay que separarlos:
--     flg_edad_tit  titular <=25 o >=75    fuente t_mst_reniec_rsk         (aplica a PNN)
--     flg_edad_rl   algun RL <=25 o >=75   t_mst_rep_legal_sunat_rsk + reniec (aplica a PJJ)
--
--   Timing: se mide en m0 (año(codmes)-año(nacimiento)). Para edad eso es CORRECTO y no es
--   look-ahead: la fecha de nacimiento es determinista, conocida al decidir. La discrepancia
--   m0 vs m0-2 de otras maestras es inmaterial aca.
--   Defecto de calculo conocido: es año-año, ignora el mes -> ruido de +-1 anio en el borde.
--   Fail-open: sin fila RENIEC -> COALESCE(...,30) -> flag 0 -> pasa clean.
--
-- CUATRO GRUPOS MUTUAMENTE EXCLUYENTES (impulsa/reactiva_puro ya afuera: SIN BLOQUE)
--   CLEAN         las 18 en cero
--   EDAD solo     (edad_tit OR edad_rl)=1 y las OTRAS 16 en cero  <- candidatos a entrar
--   EDAD + otros  edad=1 y algo mas encendido
--   DIRTY sin edad
--
-- COMO SE DECIDE (bloque 2, por anio y pooled)
--   RD "EDAD solo" <= RD clean  -> la exclusion no se justifica por riesgo. Liberar.
--   RD "EDAD solo" >  RD clean   -> se sostiene, y el numero es el sustento.
--   Bloque 3 abre edad_tit vs edad_rl: pueden decidirse distinto.
--   Bloque 4 mira si el scorecard ya los precifica.
--
-- Ventana 202207-202505, altas TOP4, flg_ibk=1, sin impulsa/reactiva_puro.
-- ~30 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(cast(codmes AS int) / 100 AS varchar) AS anio,
         personeria, tip_doc, key_value,
         cast(target_12m AS double) AS y,
         coalesce(flg_edad_tit,0) AS f_et,
         coalesce(flg_edad_rl,0)  AS f_er,
         -- las 16 exclusiones que NO son edad ni giro ni ubigeo (giro ya liberado en C11)
         (CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END)
       + coalesce(flg_novig_1m_m2,0) + coalesce(flg_novig_12m_m2,0) + coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0) + coalesce(flg_org_jud_m2,0) + coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0) + coalesce(flg_org_atraso_m2,0) + coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0) + coalesce(flg_estado_ruc,0)
       + coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0) + coalesce(flg_esp_cny,0)        AS n_otros16
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND coalesce(flg_impulsa,0) = 0 AND coalesce(flg_reactiva_puro,0) = 0
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
g AS (
  SELECT *,
         CASE WHEN (f_et = 1 OR f_er = 1) = false AND n_otros16 = 0 THEN '1 CLEAN'
              WHEN (f_et = 1 OR f_er = 1)         AND n_otros16 = 0 THEN '2 EDAD solo'
              WHEN (f_et = 1 OR f_er = 1)                          THEN '3 EDAD + otros'
              ELSE                                                     '4 DIRTY sin edad' END AS grupo,
         CASE WHEN f_et = 1 AND f_er = 1 THEN 'tit + rl'
              WHEN f_et = 1 THEN 'solo tit'
              WHEN f_er = 1 THEN 'solo rl' END AS cual
  FROM b
),
sc AS (
  SELECT tip_doc, key_value, p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202504'
  GROUP BY 1,2,3
),
gp AS (
  SELECT g.*, cast(sc.pd_raw AS double) AS pd_raw
  FROM g LEFT JOIN sc
    ON sc.tip_doc = g.tip_doc AND sc.key_value = g.key_value
   AND cast(g.codmes AS varchar) = cast(date_format(
         date_parse(cast(sc.p_codmes AS varchar),'%Y%m') + interval '1' month,'%Y%m') AS varchar)
)

-- ------------------------------------------------- 1. grupos
SELECT '1. GRUPOS' AS bloque, grupo AS detalle, 'TODOS' AS corte,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS def,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd
FROM g GROUP BY grupo

-- ------------------------------------------------- 2. LA DECISION: edad vs clean por anio
UNION ALL
SELECT '2. EDAD vs CLEAN', anio, grupo,
       cast(count(*) AS varchar), cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM g WHERE grupo IN ('1 CLEAN','2 EDAD solo') GROUP BY anio, grupo
UNION ALL
SELECT '2. EDAD vs CLEAN', 'POOLED', grupo,
       cast(count(*) AS varchar), cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM g WHERE grupo IN ('1 CLEAN','2 EDAD solo') GROUP BY grupo

-- ------------------------------------------------- 3. tit vs rl (pueden decidirse distinto)
UNION ALL
SELECT '3. TIT vs RL', coalesce(cual, '(otro)'), personeria,
       cast(count(*) AS varchar), cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM g WHERE grupo = '2 EDAD solo' GROUP BY cual, personeria

-- ------------------------------------------------- 4. ¿el scorecard ya los precifica?
UNION ALL
SELECT '4. pd_raw', grupo, personeria,
       cast(count_if(pd_raw IS NOT NULL) AS varchar),
       cast(round(100.0 * avg(pd_raw), 2) AS varchar) || ' % pd_raw',
       'RD ' || cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM gp WHERE grupo IN ('1 CLEAN','2 EDAD solo') AND pd_raw IS NOT NULL
GROUP BY grupo, personeria

-- ------------------------------------------------- 5. contrafactico
UNION ALL
SELECT '5. SI ENTRA', 'clean HOY (18 excl)', personeria,
       cast(count_if(grupo = '1 CLEAN') AS varchar),
       cast(sum(CASE WHEN grupo = '1 CLEAN' THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo = '1 CLEAN' THEN y ELSE 0 END)
                / nullif(count_if(grupo = '1 CLEAN'), 0), 2) AS varchar) || ' %'
FROM g GROUP BY personeria
UNION ALL
SELECT '5. SI ENTRA', 'clean + EDAD solo', personeria,
       cast(count_if(grupo IN ('1 CLEAN','2 EDAD solo')) AS varchar),
       cast(sum(CASE WHEN grupo IN ('1 CLEAN','2 EDAD solo') THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo IN ('1 CLEAN','2 EDAD solo') THEN y ELSE 0 END)
                / nullif(count_if(grupo IN ('1 CLEAN','2 EDAD solo')), 0), 2) AS varchar) || ' %'
FROM g GROUP BY personeria

ORDER BY 1, 2, 3
