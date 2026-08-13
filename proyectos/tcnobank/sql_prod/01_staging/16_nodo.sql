-- ============================================================================
-- 16. NODO DE POLITICA - REPLICA DE nodos_tc_nb_f6
--   scan: 11_po_key U 13_pasivos U 14_plin U 15_cta_sueldo
--   ancla: las 20 ramas salen del CASE de SCRIPT TC NO BANK - LOGICA NODOS linea 3481
--          a 3503, marcado ahi como PROPUESTA GANADORA
--   solo aplica a la entidad 00002: cif_key es la identidad de cliente de IBK y la
--   cobertura de PLIN es 57 por ciento ahi contra 10 a 18 en las otras cuatro. Calcular
--   el nodo fuera de IBK daria N3 masivo y falso, porque la ausencia de dato no es
--   ausencia de comportamiento
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_16_nodo AS
WITH b AS (
    SELECT k.codmes_mrm,
           k.tip_doc,
           k.id_value,
           k.entidad,
           coalesce(a.flag_pasivos_afp_f, 0)                                            AS pasivo,
           coalesce(c.flg_cs_v2, 0)                                                     AS cs,
           coalesce(c.flg_cs_estado, 'SIN_DATO')                                        AS cs_estado,
           CAST(CASE WHEN coalesce(p.cant_trx_u3m, 0) >= 1 THEN 1 ELSE 0 END AS INTEGER) AS plin,
           CAST(CASE WHEN coalesce(p.cant_30_prm_out, 0) >= 1 THEN 1 ELSE 0 END AS INTEGER) AS f1,
           CAST(CASE WHEN coalesce(p.cant_20_trx_out, 0) >= 1 THEN 1 ELSE 0 END AS INTEGER) AS f2,
           CAST(CASE WHEN coalesce(p.cant_30_prm_out_estricto, 0) >= 1 THEN 1 ELSE 0 END AS INTEGER) AS f1_estricto,
           CAST(CASE WHEN coalesce(p.cant_20_trx_out_estricto, 0) >= 1 THEN 1 ELSE 0 END AS INTEGER) AS f2_estricto,
           coalesce(a.ctrl_sin_360, 1)                                                  AS ctrl_sin_360,
           coalesce(c.ctrl_sin_cta_sueldo, 1)                                           AS ctrl_sin_cta_sueldo,
           CAST(CASE WHEN p.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)              AS ctrl_sin_plin,
           coalesce(a.ctrl_retiro_afp, 0)                                               AS ctrl_retiro_afp,
           coalesce(a.ctrl_retiro_afp_abonado, 0)                                       AS ctrl_retiro_afp_abonado
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key k
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_13_pasivos    a ON a.codmes_mrm = k.codmes_mrm AND a.tip_doc = k.tip_doc AND a.id_value = k.id_value
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_14_plin       p ON p.codmes_mrm = k.codmes_mrm AND p.tip_doc = k.tip_doc AND p.id_value = k.id_value
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_15_cta_sueldo c ON c.codmes_mrm = k.codmes_mrm AND c.tip_doc = k.tip_doc AND c.id_value = k.id_value
)
SELECT tip_doc,
       id_value,
       entidad,
       pasivo                                                                           AS flag_pasivos_afp_f,
       cs                                                                               AS flg_cs_v2,
       cs_estado                                                                        AS flg_cs_estado,
       plin                                                                             AS flg_plinero_u3m,
       f1                                                                               AS flg_plin_f1,
       f2                                                                               AS flg_plin_f2,
       f1_estricto,
       f2_estricto,
       ctrl_sin_360,
       ctrl_sin_cta_sueldo,
       ctrl_sin_plin,
       ctrl_retiro_afp,
       ctrl_retiro_afp_abonado,
       CASE WHEN entidad <> '00002' THEN 'SIN_ALCANCE'
            ELSE CASE
            WHEN pasivo = 1 AND cs = 1 AND plin = 1 AND f1 = 1 AND f2 = 1 THEN 'N1'
            WHEN pasivo = 1 AND cs = 1 AND plin = 1 AND f1 = 1 AND f2 = 0 THEN 'N1'
            WHEN pasivo = 1 AND cs = 1 AND plin = 1 AND f1 = 0 AND f2 = 1 THEN 'N1'
            WHEN pasivo = 1 AND cs = 1 AND plin = 1 AND f1 = 0 AND f2 = 0 THEN 'N1'
            WHEN pasivo = 1 AND cs = 0 AND plin = 1 AND f1 = 1 AND f2 = 1 THEN 'N1'
            WHEN pasivo = 1 AND cs = 0 AND plin = 1 AND f1 = 1 AND f2 = 0 THEN 'N1'
            WHEN pasivo = 1 AND cs = 0 AND plin = 1 AND f1 = 0 AND f2 = 1 THEN 'N2'
            WHEN pasivo = 1 AND cs = 0 AND plin = 1 AND f1 = 0 AND f2 = 0 THEN 'N1'
            WHEN pasivo = 0 AND cs = 1 AND plin = 1 AND f1 = 1 AND f2 = 1 THEN 'N1'
            WHEN pasivo = 0 AND cs = 1 AND plin = 1 AND f1 = 1 AND f2 = 0 THEN 'N1'
            WHEN pasivo = 0 AND cs = 1 AND plin = 1 AND f1 = 0 AND f2 = 1 THEN 'N3'
            WHEN pasivo = 0 AND cs = 1 AND plin = 1 AND f1 = 0 AND f2 = 0 THEN 'N2'
            WHEN pasivo = 0 AND cs = 0 AND plin = 1 AND f1 = 1 AND f2 = 1 THEN 'N3'
            WHEN pasivo = 0 AND cs = 0 AND plin = 1 AND f1 = 1 AND f2 = 0 THEN 'N2'
            WHEN pasivo = 0 AND cs = 0 AND plin = 1 AND f1 = 0 AND f2 = 1 THEN 'N3'
            WHEN pasivo = 0 AND cs = 0 AND plin = 1 AND f1 = 0 AND f2 = 0 THEN 'N3'
            WHEN pasivo = 1 AND cs = 1 AND plin = 0 THEN 'N2'
            WHEN pasivo = 1 AND cs = 0 AND plin = 0 THEN 'N2'
            WHEN pasivo = 0 AND cs = 1 AND plin = 0 THEN 'N2'
            WHEN pasivo = 0 AND cs = 0 AND plin = 0 THEN 'N3'
                 END END                                                                AS nodo_final,
       codmes_mrm
FROM b
