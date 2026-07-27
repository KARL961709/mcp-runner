-- ============================================================================
-- 20. CIERRE MENSUAL, SCOPE PP HPC - foto por (codmes, llave)
--   scope [ENR#L213]: prod 06% AND subprod <> Cre.Efec.GH AND aplicativo HPC
--   la agregacion por cuenta vive ACA; 60_filtros no vuelve a agregar (P3)
--   los saldos van SIN COALESCE: el Recibido (#L237) suma crudo, y un NULL hace que
--   la rama NO dispare. Envolverlos convertia 'saldo desconocido' en 'saldo cero' y
--   mandaba al 99 a quien no correspondia. ctrl_saldo_nulo deja el caso visible.
--   expone codmes Y as_of_mes: el Recibido pinnea con as_of_date en #L237-238
--   y con codmes en #L234. flg_asof_igual_codmes mide si difieren (P5)
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_20_dm AS
SELECT
  CAST(codmes AS VARCHAR)                                        AS codmes,
  CAST(key_value AS VARCHAR)                                     AS id_value,
  CAST(tip_doc AS VARCHAR)                                       AS tip_doc,
  COUNT(*)                                                       AS n_cuentas,
  MAX(dm)                                                        AS dm_max,
  MAX(CASE WHEN vig + ven + jud + castigado = 0
           THEN 1 ELSE 0 END)                                    AS flg_alguna_cta_saldo_cero,
  MAX(CASE WHEN vig IS NULL OR ven IS NULL OR jud IS NULL OR castigado IS NULL
           THEN 1 ELSE 0 END)                                    AS ctrl_saldo_nulo,
  MAX(CASE WHEN cuc IS NULL THEN 1 ELSE 0 END)                   AS flg_alguna_cta_cuc_nulo,
  MAX(DATE_FORMAT(DATE_PARSE(as_of_date, '%Y-%m-%d'), '%Y%m'))   AS as_of_mes,
  MIN(CASE WHEN DATE_FORMAT(DATE_PARSE(as_of_date, '%Y-%m-%d'), '%Y%m') = CAST(codmes AS VARCHAR)
           THEN 1 ELSE 0 END)                                    AS flg_asof_igual_codmes
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
  AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
GROUP BY 1, 2, 3
