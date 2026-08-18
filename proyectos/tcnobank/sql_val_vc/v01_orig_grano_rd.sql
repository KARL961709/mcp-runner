-- ============================================================================
-- 01. GRANO Y TARGET DEL ORIGINAL POR COHORTE
--   scan: d_perm_aws.ds_vc_mvp_no_bank_gdp_target_kat, todas las particiones
--   cod_mes es la cohorte, p_codmes el mes de ejecucion. No emite llaves.
-- ============================================================================
SELECT cod_mes,
       count(*)                                                                        AS n_filas,
       count(DISTINCT CAST(cod_tip_doc AS VARCHAR) || '|' || CAST(key_value AS VARCHAR)) AS n_clientes,
       count(DISTINCT CAST(cod_tip_doc AS VARCHAR) || '|' || CAST(key_value AS VARCHAR) || '|' || CAST(codempresa AS VARCHAR)) AS n_cli_ent,
       count(DISTINCT p_codmes)                                                        AS n_ejec,
       sum(CASE WHEN dsc_flg_malo_12m = '14.Malo_60'      THEN 1 ELSE 0 END)            AS n_malo60,
       sum(CASE WHEN dsc_flg_malo_12m = '13.Indeterm_60'  THEN 1 ELSE 0 END)            AS n_indet,
       sum(CASE WHEN dsc_flg_malo_12m = '15.Bueno'        THEN 1 ELSE 0 END)            AS n_bueno,
       sum(CASE WHEN dsc_flg_malo_12m = '12.Insuficiente' THEN 1 ELSE 0 END)            AS n_insuf,
       sum(CASE WHEN dsc_flg_malo_12m = '09.Uncashed'     THEN 1 ELSE 0 END)            AS n_uncash,
       sum(CASE WHEN dsc_flg_malo_12m NOT IN ('14.Malo_60','13.Indeterm_60','15.Bueno',
                                              '12.Insuficiente','09.Uncashed') THEN 1 ELSE 0 END) AS n_excluido,
       sum(CASE WHEN maxdm_rcc  > 60 THEN 1 ELSE 0 END)                                 AS n_dmsf60,
       sum(CASE WHEN cc_castigos = 1 THEN 1 ELSE 0 END)                                 AS n_duro,
       sum(CASE WHEN missing     = 0 THEN 1 ELSE 0 END)                                 AS n_sin_missing
  FROM d_perm_aws.ds_vc_mvp_no_bank_gdp_target_kat
 GROUP BY cod_mes
 ORDER BY cod_mes
