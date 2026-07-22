-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C19_pdraw_capta_bloque.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C19_pdraw_capta_bloque.sql
--   sha256  : 2e5d860c4726   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : EL GATE del refit: el pd_raw ya recoge el nivel dirty/clean por personeria? EC por celda
-- =====================================================================================
-- =====================================================================================
-- C19_pdraw_capta_bloque.sql | ¿el pd_raw ya recoge el nivel dirty vs clean, por personeria?
--
-- LA PREGUNTA QUE DECIDE refit vs re-ancla vs extrapolar:
--   Si el pd_raw MEDIO del dirty-PNN es mas alto que el del clean-PNN en proporcion a su RD
--   (23.37% vs 12.13% = 1.93x), el modelo YA recoge el nivel -> alcanza re-anclar/extrapolar.
--   Si el pd_raw es SIMILAR entre dirty y clean pese a la RD distinta, el gap esta SIN capturar
--   -> el bloque dirty es imprescindible (hay que calibrar su nivel aparte).
--
-- El diagnostico central es el EC por celda = mean(pd_raw) / RD - 1:
--   * EC parecido entre clean y dirty  -> el pd_raw sigue a la RD (recoge el nivel)
--   * EC MUY negativo en dirty-PNN      -> pd_raw plano mientras la RD sube: NO recoge -> refit
--
-- pd_raw con desfase de produccion: p_codmes = codmes_alta - 1 (igual que C8).
-- Ventana: cosecha normal 2207-2303 (donde la RD es medible) + pooled 2207-2505 de control.
-- Base = clean + dirty (sin garantizados). Definicion final: 16 exclusiones.
--
-- ~16 filas. READ-ONLY.
-- =====================================================================================

WITH pob AS (
  SELECT cast(codmes AS int) AS codmes, personeria, tip_doc, key_value,
         cast(target_12m AS double) AS y,
         CASE WHEN coalesce(flg_impulsa,0)=1 OR coalesce(flg_reactiva_puro,0)=1 THEN 1 ELSE 0 END AS gar,
         (CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END)
       + coalesce(flg_novig_1m_m2,0) + coalesce(flg_novig_12m_m2,0) + coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0) + coalesce(flg_org_jud_m2,0) + coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0) + coalesce(flg_org_atraso_m2,0) + coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0) + coalesce(flg_estado_ruc,0)
       + coalesce(flg_edad_tit,0) + coalesce(flg_edad_rl,0) + coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0) + coalesce(flg_esp_cny,0)          AS n16
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
sc AS (
  SELECT tip_doc, key_value, p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202504'
  GROUP BY 1,2,3
),
j AS (
  SELECT p.codmes, p.personeria, p.y,
         CASE WHEN p.gar = 1 THEN 'SINBLOQUE' WHEN p.n16 = 0 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque,
         cast(sc.pd_raw AS double) AS pd_raw
  FROM pob p
  JOIN sc ON sc.tip_doc = p.tip_doc AND sc.key_value = p.key_value
        AND p.codmes = cast(date_format(date_parse(cast(sc.p_codmes AS varchar),'%Y%m')
                                        + interval '1' month,'%Y%m') AS int)
  WHERE p.gar = 0
)

-- 1 · COSECHA NORMAL 2207-2303: pd_raw medio vs RD, por personeria x bloque
SELECT '1. COSECHA NORMAL' AS bloque, personeria || ' · ' || bloque AS celda,
       cast(count(*) AS varchar) AS n,
       cast(round(100.0 * avg(pd_raw), 2) AS varchar) || ' %' AS pd_raw_medio,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'      AS rd_obs,
       cast(round(100.0 * (avg(pd_raw) / nullif(avg(y), 0) - 1), 0) AS varchar) || ' % EC' AS ec
FROM j WHERE codmes BETWEEN 202207 AND 202303
GROUP BY personeria, bloque

-- 2 · el salto de pd_raw dirty/clean vs el salto de RD (por personeria)
UNION ALL
SELECT '2. SALTO dirty/clean', personeria,
       'pd_raw',
       cast(round(100.0 * avg(CASE WHEN bloque='DIRTY' THEN pd_raw END), 2) AS varchar) || ' d / '
       || cast(round(100.0 * avg(CASE WHEN bloque='CLEAN' THEN pd_raw END), 2) AS varchar) || ' c',
       'RD ' || cast(round(100.0 * avg(CASE WHEN bloque='DIRTY' THEN y END), 2) AS varchar) || ' d / '
       || cast(round(100.0 * avg(CASE WHEN bloque='CLEAN' THEN y END), 2) AS varchar) || ' c',
       'ratio pd_raw ' || cast(round(
            avg(CASE WHEN bloque='DIRTY' THEN pd_raw END) / nullif(avg(CASE WHEN bloque='CLEAN' THEN pd_raw END),0), 2) AS varchar)
       || ' vs RD ' || cast(round(
            avg(CASE WHEN bloque='DIRTY' THEN y END) / nullif(avg(CASE WHEN bloque='CLEAN' THEN y END),0), 2) AS varchar)
FROM j WHERE codmes BETWEEN 202207 AND 202303
GROUP BY personeria

-- 3 · POOLED 2207-2505 de control (mas n)
UNION ALL
SELECT '3. POOLED control', personeria || ' · ' || bloque, 'pooled',
       cast(round(100.0 * avg(pd_raw), 2) AS varchar) || ' % pd_raw',
       cast(round(100.0 * avg(y), 2) AS varchar) || ' % RD',
       cast(round(100.0 * (avg(pd_raw) / nullif(avg(y), 0) - 1), 0) AS varchar) || ' % EC'
FROM j GROUP BY personeria, bloque

ORDER BY 1, 2
