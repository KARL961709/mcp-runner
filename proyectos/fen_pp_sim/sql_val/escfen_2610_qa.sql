-- QA escfen 2610: grano, FEN>=PIT (shift>=0, detecta zona muerta rec_d), geo, nulls. Solo agregados.
SELECT codmes, COUNT(*) AS n, COUNT(DISTINCT cod_tip_doc || key_value) AS n_dist,
  ROUND(AVG(r_reest),3) AS avg_r, ROUND(AVG(s_norm),3) AS avg_s, ROUND(AVG(rec_d),3) AS avg_recd, ROUND(AVG(ep),3) AS avg_ep,
  SUM(CASE WHEN ubigeo = 'SIN_GEO' THEN 1 ELSE 0 END) AS sin_geo,
  ROUND(AVG(pd_pit_ppfacil),4) AS pit_ppf, ROUND(AVG(pd_pit_fen_ppfacil),4) AS fen_ppf,
  ROUND(AVG(pd_pit_ec),4) AS pit_ec, ROUND(AVG(pd_pit_fen_ec),4) AS fen_ec,
  ROUND(AVG(pd_pit_ppcd),4) AS pit_ppcd, ROUND(AVG(pd_pit_fen_ppcd),4) AS fen_ppcd,
  SUM(CASE WHEN pd_pit_fen_ppfacil < pd_pit_ppfacil - 1e-9 THEN 1 ELSE 0 END) AS n_fen_menor_pit_ppf,
  SUM(CASE WHEN pd_pit_fen_ppfacil IS NULL OR pd_pit_ppfacil IS NULL OR pd_pit_fen_ec IS NULL OR pd_pit_fen_ppcd IS NULL THEN 1 ELSE 0 END) AS n_null,
  SUM(CASE WHEN puntuacion_pit_fen_ppfacil < 0 OR puntuacion_pit_fen_ppfacil > 1000 THEN 1 ELSE 0 END) AS punt_oob
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2610_escfen
GROUP BY codmes
ORDER BY codmes
