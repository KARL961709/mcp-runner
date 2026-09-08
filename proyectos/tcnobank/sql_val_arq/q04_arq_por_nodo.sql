-- ============================================================================
-- Q04. ARQUETIPO DENTRO DEL NODO - LA CELDA QUE EL PASO 06 REALMENTE OPTIMIZA
--   scan: ds_adm_vcnbank_tc_cal U scr_adm_vcnbank_tc_cal
--   pregunta: la senal del arquetipo sobrevive al condicionar por nodo
--
--   El objetivo del paso 06 suma brechas al cuadrado sobre celdas de arquetipo
--   Y sobre celdas de nodo. Si el arquetipo solo estuviera reordenando gente
--   entre nodos, la ganancia seria del nodo y no del arquetipo. Este corte lo
--   separa.
--
--   OJO CON EL NODO EN SS.FF. nodo_calc se arma con cinco banderas que salen de
--   fuentes internas de Interbank. Un cliente de otro banco que no tiene
--   producto en IBK no aparece en ninguna, sus cinco banderas son cero por
--   AUSENCIA y cae en N3. Fuera de IBK, N3 mezcla riesgo con ceguera. La
--   columna n_nodo_n3 esta para leer el peso de esa mezcla en cada grupo.
--
--   Cohortes maduras solamente.
-- ============================================================================
WITH d AS (
     SELECT tip_doc, id_value, entidad, codmes_mrm,
            coalesce(seg_arq_salud, '(nulo)')                                                AS arq,
            target_12m,
            CASE WHEN entidad = '00002'                             THEN '1_IBK'
                 WHEN entidad IN ('00001','00004','00006','00142')  THEN '2_PANEL_RESTO'
                 ELSE                                                    '3_OTRAS_SSFF' END  AS grp,
            CASE WHEN f_banc_u12m = 1 OR f_sin_linea = 1 THEN 99
                 WHEN f_edad_rango + f_cast_ori + f_jud_ori + f_ref_ori + f_ree_ori
                    + f_malo_ori + f_cast_u24m + f_jud_u24m + f_ref_u6m + f_mayor_cpp
                    + f_gar_conv + f_fraude + f_swap_u12m = 0 THEN 1 ELSE 0 END              AS clean_sf
       FROM disc_model_owner.ds_adm_vcnbank_tc_cal
     ),
s AS (
     SELECT tip_doc, id_value, entidad, codmes_mrm, nodo_calc, prob_modelo_cal,
            ctrl_nodo_n_fuentes
       FROM disc_model_owner.scr_adm_vcnbank_tc_cal
      WHERE prob_modelo_cal IS NOT NULL
     )
SELECT d.grp,
       s.nodo_calc,
       d.arq,
       count(*)                                                                  AS n,
       round(100.0 * avg(d.target_12m), 4)                                       AS rd_12m,
       round(100.0 * avg(s.prob_modelo_cal), 4)                                  AS pd_cal_media,
       round(10000.0 * (avg(s.prob_modelo_cal) - avg(d.target_12m)), 1)          AS gap_bps,
       round(avg(CAST(s.ctrl_nodo_n_fuentes AS DOUBLE)), 3)                      AS fuentes_media
  FROM d
  JOIN s ON s.tip_doc = d.tip_doc AND s.id_value = d.id_value
        AND s.entidad = d.entidad AND s.codmes_mrm = d.codmes_mrm
 WHERE d.clean_sf = 1
   AND d.target_12m IS NOT NULL
   AND d.codmes_mrm >= '202411'
 GROUP BY d.grp, s.nodo_calc, d.arq
 ORDER BY d.grp, s.nodo_calc, d.arq
