-- c04 evolutivo niveles PP Facil por RAW (score = round(1000*(1-prob_modelo)) = pd_raw), cortes 985/955/947/912/892/864, clean. pct_N por G + pd_raw media.
SELECT codmes,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G1' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g1,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G2' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g2,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G3' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g3,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G4' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g4,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G5' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g5,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G6' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g6,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'GR' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_gr,
       ROUND(AVG(prob_modelo) * 100, 2) AS pd_raw_pct
FROM (
  SELECT codmes, prob_modelo,
    CASE WHEN CAST(round(1000.0 * (1 - prob_modelo)) AS integer) >= 985 THEN 'G1'
         WHEN CAST(round(1000.0 * (1 - prob_modelo)) AS integer) >= 955 THEN 'G2'
         WHEN CAST(round(1000.0 * (1 - prob_modelo)) AS integer) >= 947 THEN 'G3'
         WHEN CAST(round(1000.0 * (1 - prob_modelo)) AS integer) >= 912 THEN 'G4'
         WHEN CAST(round(1000.0 * (1 - prob_modelo)) AS integer) >= 892 THEN 'G5'
         WHEN CAST(round(1000.0 * (1 - prob_modelo)) AS integer) >= 864 THEN 'G6'
         ELSE 'GR' END AS nivel
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202608
  WHERE flg_clean = 1
)
GROUP BY codmes
ORDER BY codmes
