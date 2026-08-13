-- ============================================================================
-- D21. CUAL SCORE ESTAMOS CALIBRANDO
--   scan: e_perm_aws.scr_vcnbank_rsk en [202410,202504], solo la poblacion de IBK
--   ancla: los nodos traen PROB_VC_NB_NEW_V3 con media 8.82 y p50 6.85 sobre IBK en
--          esos meses. Nuestro pd_raw da 13.4. Si al recortar a IBK la media baja a
--          8.8 la brecha era poblacion. Si sigue en 13 es OTRO score
-- ============================================================================
SELECT p_codmes                                                                         AS codmes,
       count(*)                                                                         AS n,
       round(100.0 * avg(TRY_CAST(prob_model AS DOUBLE)), 4)                            AS prob_model_media,
       round(100.0 * approx_percentile(TRY_CAST(prob_model AS DOUBLE), 0.5), 4)         AS prob_model_p50,
       round(100.0 * min(TRY_CAST(prob_model AS DOUBLE)), 4)                            AS prob_model_min,
       round(100.0 * max(TRY_CAST(prob_model AS DOUBLE)), 4)                            AS prob_model_max,
       round(100.0 * avg(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)                       AS prob_cal_media,
       round(100.0 * approx_percentile(TRY_CAST(prob_modelo_cal AS DOUBLE), 0.5), 4)    AS prob_cal_p50,
       count(DISTINCT grupo_calibracion)                                                AS n_grupos_cal
FROM e_perm_aws.scr_vcnbank_rsk s
WHERE s.p_codmes BETWEEN '202410' AND '202504'
  AND EXISTS (SELECT 1 FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
              WHERE c.tip_doc = s.cod_tip_doc AND c.id_value = s.key_value
                AND c.codmes_mrm = s.p_codmes AND c.entidad = '00002')
GROUP BY p_codmes
ORDER BY p_codmes
