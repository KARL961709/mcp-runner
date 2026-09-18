-- QA[1] CONTEO: filas calibradas == fuente (ADMBANKBPE, prob not null, p_codmes 202401-202608)
SELECT (SELECT COUNT(*) FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608) AS n_cal,
  (SELECT COUNT(*) FROM e_perm_aws.scr_admbankbpe_rsk WHERE probabilidad IS NOT NULL AND modelo='ADMBANKBPE' AND CAST(p_codmes AS INT) BETWEEN 202401 AND 202608) AS n_fuente
