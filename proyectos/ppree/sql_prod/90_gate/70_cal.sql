-- ============================================================================
-- 70. ENSAMBLADO FINAL - ds_stk_ree_pp_cal
--   flg_clean sale de UNA expresion, con dos sumas (forma tomada de la
--   referencia BankBN 4b_cal.sql#L98-111): CASO3 > 0 -> 99; honestas = 0 -> 1;
--   resto -> 0. Reconcilia #99 + #1 + #0 = universo por construccion.
--   flg_scope_ree es EJE aparte y NO entra al gate (A36).
--   Ningun filtro se escribe como constante: los seis salen de 60_filtros.
--   La ventana no es un WHERE: entran las 90 cohortes y el recorte lo hace el flag.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_cal AS
WITH base AS (
  SELECT
    f.codmes_mrm,
    f.tip_doc,
    f.id_value,
    p.codmes_scr,

    f.flg_scope_ree,

    f.filtro_gtia_hip,
    f.filtro_colab,
    f.filtro_mto_pend,
    f.filtro_baja,
    f.filtro_malo_sf,
    f.filtro_malo_origen,

    f.falla_foto_t0,
    f.valida_colab,
    CAST(CASE WHEN CAST(f.codmes_mrm AS INT) BETWEEN 201901 AND 202604 THEN 1 ELSE 0 END AS INTEGER) AS valida_scope,
    f.ctrl_asof_igual_codmes,
    f.ctrl_n_cuentas,

    t.target_01m_60, t.target_02m_60, t.target_03m_60, t.target_04m_60,
    t.target_05m_60, t.target_06m_60, t.target_07m_60, t.target_08m_60,
    t.target_09m_60, t.target_10m_60, t.target_11m_60, t.target_12m_60,
    t.target_01m_30, t.target_02m_30, t.target_03m_30, t.target_04m_30,
    t.target_05m_30, t.target_06m_30, t.target_07m_30, t.target_08m_30,
    t.target_09m_30, t.target_10m_30, t.target_11m_30, t.target_12m_30,
    t.max_dm_01, t.max_dm_03, t.max_dm_06, t.max_dm_09, t.max_dm_12,
    t.miss_06, t.miss_12t,
    COALESCE(t.falla_madurez_12, 1) AS falla_madurez_12,
    COALESCE(t.falla_madurez_09, 1) AS falla_madurez_09,
    COALESCE(t.falla_madurez_06, 1) AS falla_madurez_06,
    COALESCE(t.falla_madurez_03, 1) AS falla_madurez_03,
    COALESCE(t.falla_madurez_01, 1) AS falla_madurez_01,

    d.tipo_ingreso,
    d.tipo_ingreso_dep,
    d.flg_cs,
    d.sit_lab_cs_4v,
    d.sit_lab_cs_5v,
    d.falla_sin_tipo_ingreso,
    d.falla_sin_cta_sueldo,
    d.ctrl_fuente_nueva,

    p.pd_raw,
    p.score_raw,
    p.flg_ree_v4,
    COALESCE(p.falla_cruce_pd, 1) AS falla_cruce_pd,
    COALESCE(p.falla_pd_rango, 0) AS falla_pd_rango,

    m.n_filas                                                                   AS ctrl_n_filas_cierre,
    CAST(CASE WHEN t.codmes_mrm IS NULL THEN 1 ELSE 0 END AS INTEGER)           AS falla_sin_target,
    CAST(CASE WHEN f.flg_scope_ree = 1 AND p.flg_ree_v4 IS NOT NULL
                   AND p.flg_ree_v4 <> 1 THEN 1 ELSE 0 END AS INTEGER)          AS falla_scope_vs_v4,
    CAST(CASE WHEN COUNT(1) OVER (PARTITION BY f.codmes_mrm, f.tip_doc, f.id_value) > 1
              THEN 1 ELSE 0 END AS INTEGER)                                     AS falla_dup
  FROM disc_model_owner.ds_stk_ree_pp_60_filtros f
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_35_target t
         ON t.codmes_mrm = f.codmes_mrm AND t.tip_doc = f.tip_doc AND t.id_value = f.id_value
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_40_drivers d
         ON d.codmes_mrm = f.codmes_mrm AND d.tip_doc = f.tip_doc AND d.id_value = f.id_value
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_50_pd p
         ON p.codmes_mrm = f.codmes_mrm AND p.tip_doc = f.tip_doc AND p.id_value = f.id_value
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_26_meses m
         ON m.codmes = f.codmes_mrm
),
gate AS (
  SELECT b.*,
    CASE
      WHEN b.filtro_gtia_hip + b.filtro_colab + b.filtro_mto_pend + b.filtro_baja
         + b.falla_foto_t0 > 0 THEN 99
      WHEN b.filtro_malo_sf + b.filtro_malo_origen = 0 THEN 1
      ELSE 0
    END AS flg_clean
  FROM base b
)
SELECT
  g.*,
  CAST(CASE
    WHEN g.flg_clean <> 99
     AND g.falla_cruce_pd = 0
     AND g.falla_madurez_12 = 0
     AND g.falla_dup = 0 THEN 1
    ELSE 0
  END AS INTEGER) AS flg_calib,
  g.codmes_mrm AS p_codmes
FROM gate g
