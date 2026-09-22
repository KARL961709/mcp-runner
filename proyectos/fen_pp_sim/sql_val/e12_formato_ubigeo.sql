-- e12_formato_ubigeo.sql | resuelve el FORMATO de ubigeo_dep / ubigeo_prov de la campana (INEI vs RENIEC vs otro).
-- Motivo: para el fallback (10% sin R reestructurado) hay que gatearlos por su provincia contra grado_elnino_ubigeo_v3
--   (que esta en formato INEI). Si ubigeo_dep/prov viniera en RENIEC, un join directo asigna mal (trampa Piura->Puno).
-- Metodo: sobre los clientes que SI estan en reest (tienen ambos ubigeos conocidos), medir cuantos de ubigeo_dep/prov
--   de la campana cuadran contra el INEI vs el RENIEC de la tabla reest. El que empate ~total define el formato.
-- Read-only, 1 fila. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e12_formato_ubigeo
SELECT 'formato' AS bloque,
  CAST(MIN(length(c.ubigeo_dep))  AS varchar) || '-' || CAST(MAX(length(c.ubigeo_dep))  AS varchar) AS len_dep,
  CAST(MIN(length(c.ubigeo_prov)) AS varchar) || '-' || CAST(MAX(length(c.ubigeo_prov)) AS varchar) AS len_prov,
  CAST(SUM(CASE WHEN substr(c.ubigeo_dep, 1, 2)  = substr(r.ubigeo_formato_inei, 1, 2)   THEN 1 END) AS varchar) AS dep_eq_inei,
  CAST(SUM(CASE WHEN substr(c.ubigeo_dep, 1, 2)  = substr(r.ubigeo_formato_reniec, 1, 2) THEN 1 END) AS varchar) AS dep_eq_reniec,
  CAST(SUM(CASE WHEN substr(c.ubigeo_prov, 1, 4) = substr(r.ubigeo_formato_inei, 1, 4)   THEN 1 END) AS varchar) AS prov_eq_inei,
  CAST(SUM(CASE WHEN substr(c.ubigeo_prov, 1, 4) = substr(r.ubigeo_formato_reniec, 1, 4) THEN 1 END) AS varchar) AS prov_eq_reniec,
  CAST(COUNT(*) AS varchar) AS total
FROM (
  SELECT substr(subject_id, 3) AS kv, MAX(ubigeo_dep) AS ubigeo_dep, MAX(ubigeo_prov) AS ubigeo_prov
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
  GROUP BY 1
) c
JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON r.key_value = c.kv
