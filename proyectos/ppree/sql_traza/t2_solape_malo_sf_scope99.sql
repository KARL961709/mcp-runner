-- T2. DESCOMPONE 61 malo_sf firmados -> 58 dirty medidos
-- La diferencia se atribuye a precedencia del bucket 99 en el CASE de 70_cal,
-- pero eso es aritmetica, no medicion. Esto lo MIDE: cuantos malo_sf caen en 99
-- y por cual filtro de scope.
SELECT
  SUM(filtro_malo_sf)                                                        AS n_malo_sf,
  SUM(CASE WHEN filtro_malo_sf = 1 AND flg_clean = 99 THEN 1 ELSE 0 END)     AS malo_sf_en_99,
  SUM(CASE WHEN filtro_malo_sf = 1 AND flg_clean = 0  THEN 1 ELSE 0 END)     AS malo_sf_en_dirty,
  SUM(CASE WHEN filtro_malo_sf = 1 AND flg_clean = 99 AND filtro_gtia_hip = 1 THEN 1 ELSE 0 END) AS por_gtia_hip,
  SUM(CASE WHEN filtro_malo_sf = 1 AND flg_clean = 99 AND filtro_colab    = 1 THEN 1 ELSE 0 END) AS por_colab,
  SUM(CASE WHEN filtro_malo_sf = 1 AND flg_clean = 99 AND filtro_mto_pend = 1 THEN 1 ELSE 0 END) AS por_mto_pend,
  SUM(filtro_malo_origen)                                                    AS n_malo_origen,
  SUM(CASE WHEN filtro_malo_origen = 1 AND flg_clean = 99 THEN 1 ELSE 0 END) AS malo_origen_en_99
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
