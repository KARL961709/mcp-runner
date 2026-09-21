-- QA[1] conteo total y por match V2 (debe ~= scr_admbankbpe_rsk 202501+)
SELECT COUNT(*) AS n_total, SUM(flg_match_v2) AS n_v2, SUM(CASE WHEN grupos_cal IS NULL THEN 1 ELSE 0 END) AS grupo_null, SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END) AS pcal_null FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608
