-- 117_reconcilia_pd_pit.sql | misma pd_pit bajo cada definicion posible. OJO: flg_clean en esta tabla es el BINARIO que redefine 5b_cal_scored.sql, no el de la calibracion. El original con bucket 99 es flg_clean_calib. Ambos van en la salida
SELECT codmes,
       pob,
       count(*)                                                                          AS n_total,
       round(100.0 * avg(pit), 4)                                                        AS a_total,
       round(100.0 * avg(CASE WHEN flg_clean = 1 THEN pit END), 4)                       AS b_clean_bin,
       round(100.0 * avg(CASE WHEN flg_clean = 0 THEN pit END), 4)                       AS c_dirty_bin,
       round(100.0 * avg(CASE WHEN flg_clean_calib = 1  THEN pit END), 4)                AS d_clean_calib,
       round(100.0 * avg(CASE WHEN flg_clean_calib = 0  THEN pit END), 4)                AS e_dirty_calib,
       round(100.0 * avg(CASE WHEN flg_clean_calib = 99 THEN pit END), 4)                AS f_bucket99,
       round(100.0 * avg(CASE WHEN flg_clean_calib <> 99 THEN pit END), 4)               AS g_clean_mas_dirty,
       round(100.0 * avg(CASE WHEN flg_calib = 1 THEN pit END), 4)                       AS h_calib1,
       round(100.0 * avg(CASE WHEN flg_ppjj = 0 THEN pit END), 4)                        AS i_pnn,
       round(100.0 * avg(CASE WHEN flg_ppjj = 1 THEN pit END), 4)                        AS j_pjj,
       round(100.0 * avg(pit) * 1.15148849492598418, 4)                                  AS k_total_con_moc_v2,
       round(100.0 * avg(praw), 4)                                                       AS l_pd_raw_total,
       round(100.0 * avg(pcal), 4)                                                       AS m_pd_cal_total,
       round(avg(punt), 1)                                                               AS n_puntuacion,
       sum(CASE WHEN flg_clean_calib = 1  THEN 1 ELSE 0 END)                             AS n_clean_calib,
       sum(CASE WHEN flg_clean_calib = 0  THEN 1 ELSE 0 END)                             AS n_dirty_calib,
       sum(CASE WHEN flg_clean_calib = 99 THEN 1 ELSE 0 END)                             AS n_99
FROM (
    SELECT CAST(codmes AS VARCHAR)                    AS codmes,
           CASE WHEN entidad = 'OTRO' THEN 'SSFF'
                WHEN entidad = 'IBK'  THEN 'IBK'
                ELSE 'RESTO_TOP4' END                 AS pob,
           flg_clean,
           flg_clean_calib,
           flg_calib,
           flg_ppjj,
           TRY_CAST(prob_modelo_cal AS DOUBLE)        AS pit,
           TRY_CAST(pd_raw AS DOUBLE)                 AS praw,
           TRY_CAST(pd_cal AS DOUBLE)                 AS pcal,
           TRY_CAST(puntuacion_modelo AS DOUBLE)      AS punt
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
    WHERE prob_modelo_cal IS NOT NULL
      AND codmes BETWEEN '202504' AND '202606'
) q
GROUP BY codmes, pob
ORDER BY codmes, pob
