-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C20_gate_nivel_vs_forma.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C20_gate_nivel_vs_forma.sql
--   sha256  : c7eb8de6db8f   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : GATE decisivo: re-ancla vs refit para dirty-PNN. Gini + ratio RD por cuartil
-- =====================================================================================
-- =====================================================================================
-- C20_gate_nivel_vs_forma.sql | GATE: ¿a dirty-PNN le alcanza RE-ANCLA o necesita REFIT?
--
-- La decision C (3 objetos) trata dirty-PNN con un OVERLAY DE NIVEL (re-ancla al LRA dirty,
-- reusando la forma del clean). Eso es correcto SOLO si:
--   * el pd_raw DISCRIMINA dentro del dirty (ordena riesgo) — si no, la forma no sirve, y
--   * la curva RD-vs-pd_raw del dirty es la del clean DESPLAZADA (misma pendiente, otro nivel)
--     — si la pendiente difiere, un re-ancla plano no alcanza y hay que segmentar por motivo.
--
-- COMO SE LEE
--   Bloque 1 · AUC/Gini por personeria x bloque: el score ordena riesgo dentro de cada celda?
--     Gini dirty-PNN decente (>~0.2) -> hay forma que reusar -> re-ancla viable.
--   Bloque 2 · curva de calibracion: RD por cuartil de pd_raw, dentro de clean y dentro de dirty.
--   Bloque 3 · EL VEREDICTO: ratio RD(dirty)/RD(clean) por cuartil.
--     ratio ~CONSTANTE entre cuartiles -> desplazamiento paralelo -> RE-ANCLA de nivel BASTA.
--     ratio que CRECE con el cuartil     -> pendiente distinta -> SEGMENTAR dirty-PNN por motivo.
--
-- pd_raw con desfase p_codmes = codmes_alta - 1. Cosecha normal 2207-2303.
-- Base = clean + dirty (sin garantizados). Cuartiles de pd_raw POR PERSONERIA (clean+dirty).
-- OJO n: dirty-PNN ~605 obs / 147 def -> ~37 def/cuartil, al limite. dirty-PJJ mas fino.
-- ~24 filas. READ-ONLY.
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
    AND cast(codmes AS int) BETWEEN 202207 AND 202303
),
sc AS (
  SELECT tip_doc, key_value, p_codmes, max(probabilidad) AS pd_raw
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN '202206' AND '202302'
  GROUP BY 1,2,3
),
j AS (
  SELECT p.personeria, p.y,
         CASE WHEN p.n16 = 0 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque,
         cast(sc.pd_raw AS double) AS pd_raw
  FROM pob p
  JOIN sc ON sc.tip_doc = p.tip_doc AND sc.key_value = p.key_value
        AND p.codmes = cast(date_format(date_parse(cast(sc.p_codmes AS varchar),'%Y%m')
                                        + interval '1' month,'%Y%m') AS int)
  WHERE p.gar = 0
),
r AS (
  SELECT *,
         rank() OVER (PARTITION BY personeria, bloque ORDER BY pd_raw) AS rk,
         ntile(4) OVER (PARTITION BY personeria ORDER BY pd_raw) AS q
  FROM j
)

-- 1 · discriminacion: AUC / Gini por personeria x bloque
SELECT '1. GINI' AS bloque, personeria || ' · ' || j.bloque AS celda,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS def,
       cast(round((sum(CASE WHEN y=1 THEN rk END) - count_if(y=1)*(count_if(y=1)+1)/2.0)
                  / nullif(count_if(y=1)*count_if(y=0),0), 4) AS varchar) AS auc,
       'Gini ' || cast(round(2*(sum(CASE WHEN y=1 THEN rk END) - count_if(y=1)*(count_if(y=1)+1)/2.0)
                  / nullif(count_if(y=1)*count_if(y=0),0) - 1, 3) AS varchar) AS gini
FROM r j GROUP BY personeria, j.bloque
HAVING count_if(y=1) >= 10

-- 2 · curva de calibracion: RD por cuartil de pd_raw, dentro de cada celda
UNION ALL
SELECT '2. CURVA ' || personeria, 'q' || cast(q AS varchar) || ' · ' || bloque, '',
       cast(count(*) AS varchar),
       cast(round(100.0*avg(pd_raw),1) AS varchar) || ' % pd_raw',
       'RD ' || cast(round(100.0*avg(y),1) AS varchar) || ' % (' || cast(sum(y) AS varchar) || ' def)'
FROM r WHERE bloque IN ('CLEAN','DIRTY') GROUP BY personeria, q, bloque

-- 3 · EL VEREDICTO: ratio RD(dirty)/RD(clean) por cuartil, por personeria
UNION ALL
SELECT '3. RATIO dirty/clean', personeria, 'q' || cast(q AS varchar),
       cast(count_if(bloque='DIRTY') AS varchar) || ' d / ' || cast(count_if(bloque='CLEAN') AS varchar) || ' c',
       'RD ' || cast(round(100.0*avg(CASE WHEN bloque='DIRTY' THEN y END),1) AS varchar) || ' / '
              || cast(round(100.0*avg(CASE WHEN bloque='CLEAN' THEN y END),1) AS varchar),
       'ratio ' || cast(round(avg(CASE WHEN bloque='DIRTY' THEN y END)
                            / nullif(avg(CASE WHEN bloque='CLEAN' THEN y END),0), 2) AS varchar)
FROM r GROUP BY personeria, q

ORDER BY 1, 2
