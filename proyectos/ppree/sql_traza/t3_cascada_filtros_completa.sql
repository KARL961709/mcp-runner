-- T3. CASCADA DE FILTROS COMPLETA, marginal y con solapes
-- Cierra la trazabilidad del embudo: hoy 178+58+119018=119254 cierra en total
-- pero el desglose 143/25/10 del bucket 99 es por filtro AISLADO y no reporta
-- cuantos registros disparan DOS filtros a la vez.
SELECT
  COUNT(*)                                                                   AS n_scope,
  SUM(filtro_gtia_hip)                                                       AS f_gtia_hip,
  SUM(filtro_colab)                                                          AS f_colab,
  SUM(filtro_mto_pend)                                                       AS f_mto_pend,
  SUM(CASE WHEN filtro_gtia_hip + filtro_colab + filtro_mto_pend >= 2 THEN 1 ELSE 0 END) AS con_dos_o_mas_scope,
  SUM(CASE WHEN filtro_gtia_hip = 1 AND filtro_colab    = 1 THEN 1 ELSE 0 END)           AS gtia_y_colab,
  SUM(CASE WHEN filtro_gtia_hip = 1 AND filtro_mto_pend = 1 THEN 1 ELSE 0 END)           AS gtia_y_mto,
  SUM(CASE WHEN filtro_colab    = 1 AND filtro_mto_pend = 1 THEN 1 ELSE 0 END)           AS colab_y_mto,
  SUM(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                            AS bucket_99,
  SUM(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END)                            AS bucket_dirty,
  SUM(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                            AS bucket_clean,
  SUM(filtro_baja)                                                           AS f_baja_debe_ser_0
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
