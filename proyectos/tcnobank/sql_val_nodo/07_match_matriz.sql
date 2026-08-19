-- 07. MATRIZ DE COINCIDENCIA 1 A 1 DEL NODO
--   filas = nuestro nodo_final, columnas = el del csv. La diagonal es el match.
--   Se abre ademas por si cuenta sueldo coincide: si toda la discrepancia del
--   nodo vive en las filas donde esa bandera difiere, la logica esta bien y lo
--   que falla es el insumo
SELECT d.nodo_final                                                              AS nodo_nuestro,
       c.nodo_final                                                              AS nodo_csv,
       CASE WHEN d.flg_cs_v2 = CAST(TRY_CAST(c.flg_cs_v2 AS INTEGER) AS INTEGER)
            THEN 'cs coincide' ELSE 'cs DIFIERE' END                             AS cta_sueldo,
       COUNT(*)                                                                  AS n
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal d
  INNER JOIN disc_model_owner.aux_nodos_recibido c
          ON c.tip_doc   = d.tip_doc
         AND c.key_value = d.id_value
         AND c.codmes    = d.codmes_mrm
 WHERE d.entidad = '00002'
 GROUP BY d.nodo_final, c.nodo_final,
       CASE WHEN d.flg_cs_v2 = CAST(TRY_CAST(c.flg_cs_v2 AS INTEGER) AS INTEGER)
            THEN 'cs coincide' ELSE 'cs DIFIERE' END
 ORDER BY 3, 1, 2
