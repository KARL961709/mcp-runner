-- d_comp_dirty_tc2. Composicion EXACTA del dirty DESPLEGADO (altas_adm_tcbank_cal flg_clean=0) por dsc_flg_malo_12m.
--   Join altas (poblacion desplegada, 1/persona) x enr_admtcbk_2_v2 (categoria). Total n_pers debe ~= 18240.
--   Dice EXACTAMENTE que categorias hay que replicar para el match (vs la composicion de enr_2 que incluye lo excluido).
SELECT e.dsc_flg_malo_12m,
  COUNT(*) AS n,
  COUNT(DISTINCT a.tip_doc || '|' || a.key_value || '|' || CAST(a.codmes AS varchar)) AS n_pers
FROM disc_model_owner.altas_adm_tcbank_cal a
JOIN disc_model_owner.enr_admtcbk_2_v2 e
  ON e.tip_doc = a.tip_doc AND e.key_value = a.key_value
 AND CAST(e.codmes AS varchar) = CAST(a.codmes AS varchar) AND e.flg_ibk = 1
WHERE a.flg_ibk = 1 AND a.flg_clean = 0 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202607'
GROUP BY e.dsc_flg_malo_12m
ORDER BY n_pers DESC
