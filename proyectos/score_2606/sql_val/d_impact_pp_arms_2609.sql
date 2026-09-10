-- d_impact_pp_arms_2609. Atribucion: entre los que HOY son clean (flg_dirty_pp=0), cuantos tripea cada brazo portable.
--   Dice cual brazo mueve mas gente clean->dirty. n_any = union = total que pasaria a dirty con la correccion.
--   Nota: a_bank_pp es por presencia (no saldo) -> n_bank es cota ALTA. En el build fiel el bancarizado va por saldo>0.
SELECT
  COUNT(*) AS n_clean_actual,
  SUM(d.a_cast)   AS n_castigo,
  SUM(d.a_ref)    AS n_refin,
  SUM(d.a_ree_pp) AS n_reest,
  SUM(d.a_jud)    AS n_judicial,
  SUM(d.a_bank_pp) AS n_bancarizado,
  SUM(d.a_edad)   AS n_edad,
  SUM(d.a_ent4)   AS n_entidad,
  SUM(CASE WHEN d.a_cast = 1 OR d.a_ref = 1 OR d.a_ree_pp = 1 OR d.a_jud = 1
             OR d.a_bank_pp = 1 OR d.a_edad = 1 OR d.a_ent4 = 1 THEN 1 ELSE 0 END) AS n_any
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609 s
JOIN disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_dirty d
  ON d.codmes = s.codmes AND d.key_value = s.key_value AND d.cod_tip_doc = s.cod_tip_doc
WHERE s.flg_dirty_pp = 0
