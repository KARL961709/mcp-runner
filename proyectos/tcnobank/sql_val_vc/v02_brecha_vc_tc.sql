-- ============================================================================
-- 02. BRECHA MENSUAL VC vs TC
--   scan: d_perm_aws.ds_vc_mvp_no_bank_gdp_target_kat + disc_model_owner.ds_adm_vcnbank_tc_cal
--   VC = dsc_flg_malo_12m del original, mora del sistema y todos los creditos
--   TC = target_12m nuestro, mora de la entidad de alta y solo tarjeta
--   El original esta deduplicado a UNA fila por cliente, asi que la union es por
--   cliente y cohorte, no por entidad. n_misma_ent mide cuantas veces el original
--   eligio justo la entidad de nuestra alta.
--   LEFT JOIN a proposito: sin_match cuantifica la cobertura, y la matriz 2x2 solo
--   cuenta lo emparejado -o.malo_vc NULL no entra en ninguna de las cuatro celdas-.
-- ============================================================================
SELECT c.codmes,
       count(*)                                                                  AS n,
       sum(CASE WHEN o.malo_vc IS NULL THEN 1 ELSE 0 END)                        AS sin_match,
       sum(o.malo_vc)                                                            AS n_vc,
       sum(CASE WHEN o.malo_vc IS NOT NULL THEN c.target_12m ELSE 0 END)         AS n_tc,
       sum(CASE WHEN o.malo_vc = 1 AND c.target_12m = 1 THEN 1 ELSE 0 END)       AS ambos,
       sum(CASE WHEN o.malo_vc = 1 AND c.target_12m = 0 THEN 1 ELSE 0 END)       AS solo_vc,
       sum(CASE WHEN o.malo_vc = 0 AND c.target_12m = 1 THEN 1 ELSE 0 END)       AS solo_tc,
       sum(CASE WHEN o.malo_vc = 0 AND c.target_12m = 0 THEN 1 ELSE 0 END)       AS ninguno,
       sum(CASE WHEN o.entidad = c.entidad THEN 1 ELSE 0 END)                    AS n_misma_ent
  FROM ( SELECT codmes, tip_doc, id_value, entidad, target_12m
           FROM disc_model_owner.ds_adm_vcnbank_tc_cal
          WHERE flg_calib = 1 AND flg_clean = 1 ) c
  LEFT JOIN ( SELECT cod_mes,
                     cod_tip_doc,
                     key_value,
                     ltrim(rtrim(CAST(codempresa AS VARCHAR)))                   AS entidad,
                     CASE WHEN dsc_flg_malo_12m = '14.Malo_60' THEN 1 ELSE 0 END AS malo_vc
                FROM d_perm_aws.ds_vc_mvp_no_bank_gdp_target_kat
               WHERE dsc_flg_malo_12m IN ('14.Malo_60','13.Indeterm_60','15.Bueno') ) o
    ON o.cod_tip_doc = c.tip_doc
   AND o.key_value   = c.id_value
   AND o.cod_mes     = c.codmes
 GROUP BY c.codmes
 ORDER BY c.codmes
