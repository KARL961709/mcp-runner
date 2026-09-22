-- d2_97. Tasa clean y cobertura RCC (hit en M-2) por codmes.
SELECT codmes, COUNT(*) AS n,
  ROUND(AVG(CAST(flg_clean AS double)), 4) AS clean_rate,
  ROUND(AVG(CAST(flg_rcc_hit AS double)), 4) AS rcc_hit_rate,
  ROUND(AVG(CAST(flg_atraso AS double)), 4) AS r_atraso,
  ROUND(AVG(CAST(flg_clasif AS double)), 4) AS r_clasif
FROM disc_model_owner.drv_clean_ppvc
GROUP BY codmes
ORDER BY codmes