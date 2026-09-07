-- d_comp_dirty_tc. Composicion de la categoria desplegada (dsc_flg_malo_12m) de los admitidos TC (IBK, 202606-207).
--   Muestra que categorias arman el dirty (todo lo que NO es INDETERMINADO/INSUFICIENTE/BUENO/MALO/UNCASHED).
--   Sirve para saber QUE brazos replicar en el universo (bancarizado / ventanas / fraude / convenio / GH / entidades).
--   n = filas del join, n_pers = personas distintas (detecta fan-out del join a enr_admtcbk_1_v2).
SELECT e.dsc_flg_malo_12m,
  COUNT(*) AS n,
  COUNT(DISTINCT a.tip_doc || '|' || a.key_value || '|' || CAST(a.codmes AS varchar)) AS n_pers
FROM disc_model_owner.altas_adm_tcbank_cal a
JOIN disc_model_owner.enr_admtcbk_1_v2 e
  ON CAST(e.tip_doc AS varchar) = CAST(a.tip_doc AS varchar)
 AND e.key_value = a.key_value
 AND CAST(e.codmes AS varchar) = CAST(a.codmes AS varchar)
WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) BETWEEN '202606' AND '202607'
GROUP BY e.dsc_flg_malo_12m
ORDER BY n_pers DESC
