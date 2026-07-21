-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C5_dirty_por_motivo.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C5_dirty_por_motivo.sql
--   sha256  : d26ec51fb493   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : riesgo vs politica dentro del dirty — explica el 0.97x de PJJ
-- =====================================================================================
-- =====================================================================================
-- C5_dirty_por_motivo.sql | ¿por que el corte clean/dirty no separa riesgo en PJJ?
--
-- M3 dio: PNN DIRTY/CLEAN 1.87x  ·  PJJ DIRTY/CLEAN 0.97x
-- En jurídicas el corte no separa. La hipotesis es que DIRTY no es "los mas riesgosos"
-- sino "todo lo demas", y mezcla dos naturalezas:
--
--   RIESGO    rcc_perimetro · rcc_adverso · rrll_castigo · watchlist
--             dicen algo del comportamiento crediticio
--   POLITICA  monto_chico · sunat_knockout · giro_restringido · edad
--             son elegibilidad. Un cliente de 24 anios no incumple mas por tener 24.
--
-- Si el dirty de PJJ esta dominado por ramas de POLITICA, el 0.97x es esperable y no
-- es un defecto del corte: es que en PJJ el corte esta haciendo otra cosa.
--
-- La cascada es VERBATIM de q3b_pdraw_dirty0.sql:12-21. El orden importa: gana la
-- primera rama que matchea, asi que un cliente con castigo Y edad cuenta como
-- rcc_adverso. Los conteos son "motivo principal", no exclusivos.
--
-- Ventana 202207-202505 (12m cerrados), sin impulsa ni reactiva_puro: la misma
-- poblacion sobre la que se ajustaron los coeficientes.
--
-- ~30 filas. READ-ONLY.
-- =====================================================================================

WITH d AS (
  SELECT personeria,
         coalesce(flg_calib_m2, 0) AS clean,
         cast(target_12m AS double) AS y,
         CASE
           WHEN coalesce(flg_calib_m2,0) = 1 THEN 'CLEAN'
           WHEN coalesce(flg_monto,0) = 0 THEN 'monto_chico'
           WHEN coalesce(flg_novig_1m_m2,0)=1 OR coalesce(flg_novig_12m_m2,0)=1
                OR coalesce(flg_clasif_m2,0)=1 THEN 'rcc_perimetro_m2'
           WHEN coalesce(flg_org_castigo_m2,0)=1 OR coalesce(flg_org_jud_m2,0)=1
                OR coalesce(flg_org_refin_m2,0)=1 OR coalesce(flg_org_reestr_m2,0)=1
                OR coalesce(flg_org_atraso_m2,0)=1 OR coalesce(flg_org_clasif_m2,0)=1
                THEN 'rcc_adverso_m2'
           WHEN coalesce(flg_pnsn,0)=1 OR coalesce(flg_estado_ruc,0)=1 THEN 'sunat_knockout'
           WHEN coalesce(flg_giro,0)=1 THEN 'giro_restringido'
           WHEN coalesce(flg_edad_tit,0)=1 OR coalesce(flg_edad_rl,0)=1 THEN 'edad'
           WHEN coalesce(flg_rrll_castigo_m2,0)=1 THEN 'rrll_castigo'
           WHEN coalesce(flg_esp_tit,0)=1 OR coalesce(flg_esp_cny,0)=1 THEN 'watchlist'
           ELSE 'otro' END AS motivo
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1
    AND top4_entidad = 'TOP4'
    AND coalesce(flg_impulsa,0) = 0
    AND coalesce(flg_reactiva_puro,0) = 0
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
m AS (
  SELECT *, CASE
    WHEN motivo = 'CLEAN' THEN '0 · clean'
    WHEN motivo IN ('rcc_perimetro_m2','rcc_adverso_m2','rrll_castigo','watchlist') THEN '1 · RIESGO'
    WHEN motivo IN ('monto_chico','sunat_knockout','giro_restringido','edad') THEN '2 · POLITICA'
    ELSE '3 · otro' END AS naturaleza
  FROM d
)

-- ------------------------------------------------------- 1. por motivo x personeria
SELECT '1. MOTIVO' AS bloque, naturaleza || ' / ' || motivo AS detalle, personeria,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS def,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd
FROM m GROUP BY naturaleza, motivo, personeria

-- ------------------------------------------------------- 2. RIESGO vs POLITICA
-- Aqui esta la respuesta. Si en PJJ la rama POLITICA es grande y su RD se parece a la
-- del clean, el 0.97x queda explicado.
UNION ALL
SELECT '2. NATURALEZA', naturaleza, personeria,
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM m GROUP BY naturaleza, personeria

-- ------------------------------------------------------- 3. el contrafactico
-- RD del dirty si se contara SOLO lo excluido por riesgo. Es el corte que el modelo
-- deberia estar haciendo si clean/dirty pretende ordenar riesgo.
UNION ALL
SELECT '3. CONTRAFACTICO', 'dirty SOLO riesgo', personeria,
       cast(count_if(naturaleza = '1 · RIESGO') AS varchar),
       cast(sum(CASE WHEN naturaleza = '1 · RIESGO' THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN naturaleza = '1 · RIESGO' THEN y ELSE 0 END)
                / nullif(count_if(naturaleza = '1 · RIESGO'), 0), 2) AS varchar) || ' %'
FROM m GROUP BY personeria
UNION ALL
SELECT '3. CONTRAFACTICO', 'dirty completo (como esta hoy)', personeria,
       cast(count_if(motivo <> 'CLEAN') AS varchar),
       cast(sum(CASE WHEN motivo <> 'CLEAN' THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN motivo <> 'CLEAN' THEN y ELSE 0 END)
                / nullif(count_if(motivo <> 'CLEAN'), 0), 2) AS varchar) || ' %'
FROM m GROUP BY personeria
UNION ALL
SELECT '3. CONTRAFACTICO', 'clean (referencia)', personeria,
       cast(count_if(motivo = 'CLEAN') AS varchar),
       cast(sum(CASE WHEN motivo = 'CLEAN' THEN y ELSE 0 END) AS varchar),
       cast(round(100.0 * sum(CASE WHEN motivo = 'CLEAN' THEN y ELSE 0 END)
                / nullif(count_if(motivo = 'CLEAN'), 0), 2) AS varchar) || ' %'
FROM m GROUP BY personeria

ORDER BY 1, 2, 3
