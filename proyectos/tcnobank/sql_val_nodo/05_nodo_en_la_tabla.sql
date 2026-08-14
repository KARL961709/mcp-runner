-- 05_nodo_en_la_tabla.sql | mide el nodo DIRECTO sobre la tabla viva para reconciliar contra el parquet local. Es el chequeo que decide si lo que se valido es lo que hay: si una sola fila difiere, el parquet es de otra generacion y todo lo medido encima se cae. Comparar celda por celda contra el bloque que ya se midio localmente sobre master_tcnb_v2
SELECT codmes_mrm                                                                   AS codmes,
       count(*)                                                                     AS n,
       sum(CASE WHEN nodo_final = 'N1' THEN 1 ELSE 0 END)                           AS n_n1,
       sum(CASE WHEN nodo_final = 'N2' THEN 1 ELSE 0 END)                           AS n_n2,
       sum(CASE WHEN nodo_final = 'N3' THEN 1 ELSE 0 END)                           AS n_n3,
       sum(CASE WHEN nodo_final NOT IN ('N1', 'N2', 'N3') OR nodo_final IS NULL
                THEN 1 ELSE 0 END)                                                  AS n_otro,
       sum(ctrl_sin_360)                                                            AS n_sin_360,
       sum(ctrl_sin_cta_sueldo)                                                     AS n_sin_cta_sueldo,
       sum(ctrl_sin_plin)                                                           AS n_sin_plin,
       sum(flag_pasivos_afp_f)                                                      AS n_pasivo_uno,
       sum(flg_cs_v2)                                                               AS n_cs_uno,
       sum(flg_plinero_u3m)                                                         AS n_plin_uno
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE codmes_mrm >= '202301'
GROUP BY codmes_mrm
ORDER BY 1
