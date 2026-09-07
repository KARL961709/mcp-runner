-- d_dirty_miss. Los admitidos TC que el DESPLEGADO marca dirty (flg_clean=0) pero MI dirty=0 (los 973 miss),
--   desglosados por su categoria desplegada dsc_flg_malo_12m (de enr_admtcbk_2_v2). Dice EXACTAMENTE que brazos me faltan.
--   Ej.: si la mayor es GARANTIA HIP.->join GH roto . CASTIGADO_U24M->ventana castigo . BANCARIZADO->patron bank. 202607, flg_ibk=1.
WITH dp AS (
  SELECT cod_tip_doc, key_value, flg_dirty_tc
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608_dirty_pilot
)
SELECT e.dsc_flg_malo_12m, COUNT(*) AS n_miss
FROM disc_model_owner.altas_adm_tcbank_cal a
JOIN dp d ON d.cod_tip_doc = CAST(a.tip_doc AS varchar) AND d.key_value = a.key_value
JOIN disc_model_owner.enr_admtcbk_2_v2 e
  ON e.tip_doc = a.tip_doc AND e.key_value = a.key_value
 AND CAST(e.codmes AS varchar) = CAST(a.codmes AS varchar) AND e.flg_ibk = 1
WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) = '202607'
  AND a.flg_clean = 0 AND COALESCE(d.flg_dirty_tc, 0) = 0
GROUP BY e.dsc_flg_malo_12m
ORDER BY n_miss DESC
