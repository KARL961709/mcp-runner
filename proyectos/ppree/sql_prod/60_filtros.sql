-- ============================================================================
-- 60. FILTROS - un filtro_i por rama, 0/1, nunca NULL
--   El staging ya viene al grano (codmes, id_value, tip_doc): aca NO se agrega (P3).
--   Cada predicado lleva el pin de mes ADENTRO de la expresion, no solo en el ON (O4).
--   De este archivo se extraen los expr_ref del yaml, no al reves.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_60_filtros AS
SELECT
  po.codmes_mrm,
  po.tip_doc,
  po.id_value,

  CAST(CASE WHEN mar.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                     AS filtro_scope_ree,

  CAST(CASE WHEN gh.codmes = po.codmes_mrm AND gh.flg_gtia_hip = 1
            THEN 1 ELSE 0 END AS INTEGER)                                               AS filtro_gtia_hip,

  CAST(CASE WHEN cl.codmes = DATE_FORMAT(DATE_ADD('month', -2, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m')
             AND cl.flg_colab = 1
            THEN 1 ELSE 0 END AS INTEGER)                                               AS filtro_colab,

  CAST(CASE WHEN sf.codmes = po.codmes_mrm AND sf.cond_max > 60
            THEN 1 ELSE 0 END AS INTEGER)                                               AS filtro_malo_sf,

  CAST(CASE WHEN (dm.codmes = po.codmes_mrm AND dm.dm_max > 60)
              OR (rf.codmes = po.codmes_mrm AND rf.flg_refi = 1)
              OR (cst.codmes = po.codmes_mrm AND cst.flg_castigo = 1)
            THEN 1 ELSE 0 END AS INTEGER)                                               AS filtro_malo_origen,

  CAST(CASE WHEN dm.as_of_mes = po.codmes_mrm AND dm.flg_alguna_cta_saldo_cero = 1
            THEN 1 ELSE 0 END AS INTEGER)                                               AS filtro_mto_pend,

  CAST(CASE WHEN dm.as_of_mes = po.codmes_mrm AND dm.flg_alguna_cta_cuc_nulo = 1
            THEN 1 ELSE 0 END AS INTEGER)                                               AS filtro_baja,

  CAST(CASE WHEN dm.codmes IS NULL THEN 1 ELSE 0 END AS INTEGER)                        AS falla_foto_t0,

  CAST(CASE WHEN CAST(po.codmes_mrm AS INT) BETWEEN 201905 AND 202403
            THEN 1 ELSE 0 END AS INTEGER)                                               AS valida_colab,

  CAST(COALESCE(dm.flg_asof_igual_codmes, 0) AS INTEGER)                                AS ctrl_asof_igual_codmes,
  CAST(COALESCE(dm.n_cuentas, 0) AS INTEGER)                                            AS ctrl_n_cuentas

FROM disc_model_owner.ds_stk_ree_pp_10_po po
LEFT JOIN disc_model_owner.ds_stk_ree_pp_11_marca mar
       ON mar.id_value = po.id_value
      AND mar.codmes_mrm = po.codmes_mrm
LEFT JOIN disc_model_owner.ds_stk_ree_pp_20_dm dm
       ON dm.id_value = po.id_value AND dm.tip_doc = po.tip_doc
      AND dm.codmes = po.codmes_mrm
LEFT JOIN disc_model_owner.ds_stk_ree_pp_21_gh gh
       ON gh.id_value = po.id_value AND gh.tip_doc = po.tip_doc
      AND gh.codmes = po.codmes_mrm
LEFT JOIN disc_model_owner.ds_stk_ree_pp_22_rf rf
       ON rf.id_value = po.id_value AND rf.tip_doc = po.tip_doc
      AND rf.codmes = po.codmes_mrm
LEFT JOIN disc_model_owner.ds_stk_ree_pp_23_cst cst
       ON cst.id_value = po.id_value AND cst.tip_doc = po.tip_doc
      AND cst.codmes = po.codmes_mrm
LEFT JOIN disc_model_owner.ds_stk_ree_pp_24_colab cl
       ON cl.id_value = po.id_value AND cl.tip_doc = po.tip_doc
      AND cl.codmes = DATE_FORMAT(DATE_ADD('month', -2, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m')
LEFT JOIN disc_model_owner.ds_stk_ree_pp_25_sf sf
       ON sf.id_value = po.id_value AND sf.tip_doc = po.tip_doc
      AND sf.codmes = po.codmes_mrm
