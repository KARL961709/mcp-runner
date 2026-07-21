-- =====================================================================================
-- VALIDA_FLAGS.sql | contrasta FLAGS_DESDE_MADRE.sql contra el maestro CONGELADO
--
-- Es LA prueba de que el port desde fuentes madre es correcto. Sin esto, FLAGS_DESDE_MADRE
-- es codigo no verificado.
--
-- PASOS
--   1) Correr FLAGS_DESDE_MADRE.sql con:
--        {POBLACION} = (SELECT cast(codmes AS varchar) codmes, tip_doc, key_value
--                       FROM disc_model_owner.bnbpe_ibk_altas_src
--                       WHERE top4_entidad='TOP4' AND cast(codmes AS int) BETWEEN 202207 AND 202604)
--        {RCC_INI}   = '202106'      ({M_INI}=202207 menos 13)
--        {M_FIN}     = '202604'
--      Materializarlo en una tabla propia, p.ej. disc_model_owner.b46029_flags_madre.
--   2) Correr este SQL con {TABLA_FLAGS} = esa tabla.
--
-- QUE ESPERAR — el port NO debe dar 100% identico, y eso es CORRECTO:
--   * frozen=1, mio=1   OK   ambos clean
--   * frozen=0, mio=0   OK   ambos dirty
--   * frozen=0, mio=1   ESPERADO Y ACOTADO. Solo debe ocurrir por (a) flg_monto=0, que no
--                       calculo, o (b) impulsa FORWARD, que no es implementable ex-ante.
--                       El bloque 3 lo descompone: si aparece un caso SIN explicar por (a)
--                       ni (b), HAY UN BUG en el port.
--   * frozen=1, mio=0   NO DEBE OCURRIR NUNCA. Yo aplico un subconjunto de exclusiones, asi
--                       que mi clean solo puede ser MAS grande. Cualquier fila aqui = BUG.
--
-- READ-ONLY.
-- =====================================================================================

WITH f AS (
  SELECT cast(codmes AS int) AS codmes, cast(tip_doc AS varchar) AS tip_doc, key_value,
         flg_clean, flg_impulsa_bwd,
         flg_novig_1m_m2, flg_novig_12m_m2, flg_clasif_m2,
         flg_org_castigo_m2, flg_org_jud_m2, flg_org_refin_m2, flg_org_reestr_m2,
         flg_org_atraso_m2, flg_org_clasif_m2, flg_reactiva_puro,
         flg_pnsn, flg_estado_ruc, flg_giro, flg_edad_tit, flg_edad_rl,
         flg_rrll_castigo_m2, flg_esp_tit, flg_esp_cny
  FROM disc_model_owner.b46029_flags_madre
),
z AS (
  SELECT cast(codmes AS int) AS codmes, cast(tip_doc AS varchar) AS tip_doc, key_value,
         flg_calib_m2, flg_monto, flg_impulsa,
         flg_novig_1m_m2 AS z_novig_1m, flg_novig_12m_m2 AS z_novig_12m, flg_clasif_m2 AS z_clasif,
         flg_org_castigo_m2 AS z_cast, flg_org_jud_m2 AS z_jud, flg_org_refin_m2 AS z_ref,
         flg_org_reestr_m2 AS z_ree, flg_org_atraso_m2 AS z_atr, flg_org_clasif_m2 AS z_clsf,
         flg_reactiva_puro AS z_react,
         flg_pnsn AS z_pnsn, flg_estado_ruc AS z_ruc, flg_giro AS z_giro,
         flg_edad_tit AS z_edtit, flg_edad_rl AS z_edrl,
         flg_rrll_castigo_m2 AS z_rrll, flg_esp_tit AS z_esptit, flg_esp_cny AS z_espcny
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE cast(codmes AS int) BETWEEN 202207 AND 202604
),
j AS (
  SELECT f.*, z.flg_calib_m2, z.flg_monto, z.flg_impulsa,
         z.z_novig_1m, z.z_novig_12m, z.z_clasif, z.z_cast, z.z_jud, z.z_ref, z.z_ree,
         z.z_atr, z.z_clsf, z.z_react, z.z_pnsn, z.z_ruc, z.z_giro, z.z_edtit, z.z_edrl,
         z.z_rrll, z.z_esptit, z.z_espcny
  FROM f INNER JOIN z
    ON z.codmes=f.codmes AND z.tip_doc=f.tip_doc AND z.key_value=f.key_value
)

-- ===================== 1. matriz de confusion del flg_clean =====================
SELECT '1. MATRIZ' AS bloque,
       'frozen=' || cast(flg_calib_m2 AS varchar) || ' mio=' || cast(flg_clean AS varchar) AS caso,
       cast(count(*) AS varchar) AS n,
       CASE WHEN flg_calib_m2 = flg_clean THEN 'OK'
            WHEN flg_calib_m2 = 1 AND flg_clean = 0 THEN '*** BUG: no debe ocurrir ***'
            ELSE 'revisar bloque 3' END AS veredicto
FROM j GROUP BY 1,2,4

UNION ALL

-- ===================== 2. flag por flag contra el congelado =====================
-- Cada linea: cuantas filas difieren en ESE flag. Todo debe ser 0 salvo impulsa.
SELECT '2. POR FLAG', 'novig_1m_m2',   cast(count_if(flg_novig_1m_m2    <> z_novig_1m) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','novig_12m_m2', cast(count_if(flg_novig_12m_m2   <> z_novig_12m) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','clasif_m2',    cast(count_if(flg_clasif_m2      <> z_clasif) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','org_castigo',  cast(count_if(flg_org_castigo_m2 <> z_cast) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','org_jud',      cast(count_if(flg_org_jud_m2     <> z_jud) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','org_refin',    cast(count_if(flg_org_refin_m2   <> z_ref) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','org_reestr',   cast(count_if(flg_org_reestr_m2  <> z_ree) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','org_atraso',   cast(count_if(flg_org_atraso_m2  <> z_atr) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','org_clasif',   cast(count_if(flg_org_clasif_m2  <> z_clsf) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','reactiva_puro',cast(count_if(flg_reactiva_puro  <> z_react) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','pnsn',         cast(count_if(flg_pnsn           <> z_pnsn) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','estado_ruc',   cast(count_if(flg_estado_ruc     <> z_ruc) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','giro',         cast(count_if(flg_giro           <> z_giro) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','edad_tit',     cast(count_if(flg_edad_tit       <> z_edtit) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','edad_rl',      cast(count_if(flg_edad_rl        <> z_edrl) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','rrll_castigo', cast(count_if(flg_rrll_castigo_m2<> z_rrll) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','esp_tit',      cast(count_if(flg_esp_tit        <> z_esptit) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','esp_cny',      cast(count_if(flg_esp_cny        <> z_espcny) AS varchar), '' FROM j
UNION ALL SELECT '2. POR FLAG','impulsa (bwd vs fwd: DEBE diferir)',
                               cast(count_if(flg_impulsa_bwd     <> flg_impulsa) AS varchar), 'esperado >0' FROM j

UNION ALL

-- ===================== 3. descomposicion de los frozen=0 / mio=1 =====================
SELECT '3. DISCREPANCIA', 'solo flg_monto=0',
       cast(count_if(flg_monto=0 AND flg_impulsa=0) AS varchar), 'esperado' FROM j
       WHERE flg_calib_m2=0 AND flg_clean=1
UNION ALL SELECT '3. DISCREPANCIA','solo impulsa FORWARD',
       cast(count_if(flg_monto=1 AND flg_impulsa=1) AS varchar), 'esperado' FROM j
       WHERE flg_calib_m2=0 AND flg_clean=1
UNION ALL SELECT '3. DISCREPANCIA','ambos (monto=0 e impulsa=1)',
       cast(count_if(flg_monto=0 AND flg_impulsa=1) AS varchar), 'esperado' FROM j
       WHERE flg_calib_m2=0 AND flg_clean=1
UNION ALL SELECT '3. DISCREPANCIA','SIN EXPLICAR -> BUG',
       cast(count_if(flg_monto=1 AND flg_impulsa=0) AS varchar), '*** debe ser 0 ***' FROM j
       WHERE flg_calib_m2=0 AND flg_clean=1

ORDER BY 1,2
