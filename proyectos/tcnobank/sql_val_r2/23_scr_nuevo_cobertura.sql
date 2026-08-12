-- 23_scr_nuevo_cobertura.sql | cobertura del score nuevo sobre la poblacion del molde vigente y correlacion entre ambos scores, en cuatro meses maduros
SELECT f.p_codmes,
       count(*)                                                                              AS n_est,
       sum(CASE WHEN s.key_value IS NOT NULL THEN 1 ELSE 0 END)                              AS con_scr_nuevo,
       round(100.0 * sum(CASE WHEN s.key_value IS NOT NULL THEN 1 ELSE 0 END) / count(*), 2) AS pct_cobertura,
       round(avg(TRY_CAST(f.score AS DOUBLE)), 1)                                            AS scr_vigente_medio,
       round(avg(TRY_CAST(s.puntuacion AS DOUBLE)), 1)                                       AS scr_nuevo_medio,
       round(100.0 * avg(TRY_CAST(s.prob_model AS DOUBLE)), 4)                               AS pd_raw_media,
       round(corr(TRY_CAST(f.score AS DOUBLE), TRY_CAST(s.puntuacion AS DOUBLE)), 4)         AS corr_scores
FROM e_perm_aws.ds_flg_admtcnobk1_rsk f
LEFT JOIN e_perm_aws.scr_vcnbank_rsk s
       ON s.cod_tip_doc = f.tip_doc
      AND s.key_value = f.id_value
      AND s.p_codmes = f.codmes_scr
      AND s.p_codmes IN ('202404', '202410', '202504', '202510')
WHERE f.flg_est = 1
  AND f.p_codmes IN ('202406', '202412', '202506', '202512')
GROUP BY f.p_codmes
ORDER BY f.p_codmes
