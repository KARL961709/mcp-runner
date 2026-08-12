-- 24_scr_nuevo_vs_rd.sql | prueba decisiva: si el score nuevo ordena el target del molde vigente, y cuanta brecha hay entre la probabilidad cruda del modelo y la tasa de malos observada
SELECT CASE WHEN s.puntuacion IS NULL THEN '00.sin score nuevo'
            WHEN s.puntuacion < 600 THEN '01.<600'
            WHEN s.puntuacion < 650 THEN '02.600-649'
            WHEN s.puntuacion < 700 THEN '03.650-699'
            WHEN s.puntuacion < 750 THEN '04.700-749'
            WHEN s.puntuacion < 800 THEN '05.750-799'
            WHEN s.puntuacion < 850 THEN '06.800-849'
            WHEN s.puntuacion < 900 THEN '07.850-899'
            WHEN s.puntuacion < 950 THEN '08.900-949'
            ELSE '09.950+' END                                                    AS tramo_scr_nuevo,
       count(*)                                                                   AS n,
       sum(CASE WHEN f.dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)               AS n_malo,
       round(100.0 * sum(CASE WHEN f.dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)
             / count(*), 3)                                                       AS rd_12m_obs,
       round(100.0 * avg(TRY_CAST(s.prob_model AS DOUBLE)), 3)                    AS pd_raw_media,
       round(avg(TRY_CAST(f.score AS DOUBLE)), 1)                                 AS scr_vigente_medio
FROM e_perm_aws.ds_flg_admtcnobk1_rsk f
LEFT JOIN e_perm_aws.scr_vcnbank_rsk s
       ON s.cod_tip_doc = f.tip_doc
      AND s.key_value = f.id_value
      AND s.p_codmes = f.codmes_scr
      AND s.p_codmes IN ('202404', '202410', '202504', '202510')
WHERE f.p_codmes IN ('202406', '202412', '202506', '202512')
  AND f.dsc_flg_malo_12m IN ('BUENO', 'MALO')
  AND f.prelacion_12m = 1
GROUP BY 1
ORDER BY 1
