-- d_dirty_arms. Desglose por brazo (usa ..._dirty_pilot 202607, columnas a_*):
--   pp_extra = admitidos PP que el desplegado dice CLEAN (flg_clean<>0) pero mi dirty=1 -> QUE brazo sobre-marca.
--   tc_cov   = TODOS los admitidos TC -> cuantos prende cada brazo (si gh/conv=0 -> el join a t_consolidado_rsk esta roto = fuente del miss TC).
WITH dp AS (
  SELECT cod_tip_doc, key_value, flg_dirty_tc, flg_dirty_pp,
         a_clas_tc, a_clas_pp, a_cast, a_ref, a_ree_tc, a_ree_pp, a_jud, a_bank_tc, a_bank_pp, a_gh, a_conv, a_edad, a_ent4
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608_dirty_pilot
)
SELECT 'pp_extra' AS caso, COUNT(*) AS n,
  SUM(d.a_clas_pp) AS clas, SUM(d.a_cast) AS castigo, SUM(d.a_ref) AS ref, SUM(d.a_ree_pp) AS ree,
  SUM(d.a_jud) AS jud, SUM(d.a_bank_pp) AS bank, SUM(d.a_edad) AS edad, SUM(d.a_ent4) AS ent4,
  CAST(0 AS bigint) AS gh, CAST(0 AS bigint) AS conv
FROM disc_model_owner.altas_adm_pp_cdpp_cal a
JOIN dp d ON d.cod_tip_doc = CAST(a.tip_doc AS varchar) AND d.key_value = a.key_value
WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) = '202607' AND a.flg_clean <> 0 AND d.flg_dirty_pp = 1
UNION ALL
SELECT 'tc_cov', COUNT(*),
  SUM(d.a_clas_tc), SUM(d.a_cast), SUM(d.a_ref), SUM(d.a_ree_tc),
  SUM(d.a_jud), SUM(d.a_bank_tc), SUM(d.a_edad), SUM(d.a_ent4), SUM(d.a_gh), SUM(d.a_conv)
FROM disc_model_owner.altas_adm_tcbank_cal a
JOIN dp d ON d.cod_tip_doc = CAST(a.tip_doc AS varchar) AND d.key_value = a.key_value
WHERE a.flg_ibk = 1 AND CAST(a.codmes AS varchar) = '202607'
