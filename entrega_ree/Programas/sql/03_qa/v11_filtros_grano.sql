-- ============================================================================
-- V11. G11 sobre 60_filtros directamente: grano, dominio 0/1 y NULL.
--      Es la unica tabla del build que ninguna otra QA tocaba.
--      Todo falla_* debe dar 0. Corre DESPUES de 60_filtros.
-- ============================================================================
SELECT
  COUNT(*)                                                                        AS n,
  COUNT(DISTINCT codmes_mrm)                                                      AS n_meses,
  MIN(codmes_mrm)                                                                 AS mn,
  MAX(codmes_mrm)                                                                 AS mx,
  COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value)      AS falla_dup_grano,
  SUM(CASE WHEN filtro_gtia_hip    NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_gtia_hip,
  SUM(CASE WHEN filtro_colab       NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_colab,
  SUM(CASE WHEN filtro_malo_sf     NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_malo_sf,
  SUM(CASE WHEN filtro_malo_origen NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_malo_origen,
  SUM(CASE WHEN filtro_mto_pend    NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_mto_pend,
  SUM(CASE WHEN filtro_baja        NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_baja,
  SUM(CASE WHEN flg_scope_ree      NOT IN (0,1) THEN 1 ELSE 0 END)                AS falla_dom_scope,
  SUM(CASE WHEN filtro_gtia_hip IS NULL OR filtro_colab IS NULL OR filtro_malo_sf IS NULL
             OR filtro_malo_origen IS NULL OR filtro_mto_pend IS NULL OR filtro_baja IS NULL
             OR flg_scope_ree IS NULL OR falla_foto_t0 IS NULL
           THEN 1 ELSE 0 END)                                                     AS falla_algun_null,
  MAX(filtro_gtia_hip)                                                            AS max_gtia_hip,
  MAX(filtro_colab)                                                               AS max_colab,
  MAX(filtro_malo_sf)                                                             AS max_malo_sf,
  MAX(filtro_malo_origen)                                                         AS max_malo_origen,
  MAX(filtro_mto_pend)                                                            AS max_mto_pend,
  MAX(filtro_baja)                                                                AS max_baja
FROM disc_model_owner.ds_stk_ree_pp_60_filtros
