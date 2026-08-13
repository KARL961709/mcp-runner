-- ============================================================================
-- V9. PASIVOS - DONDE SE PIERDE EL FLAG
--   scan: __T___11_po_key U __T___13_pasivos, entidad 00002 en [202410,202504]
--   ancla: el csv da 26.08 por ciento de flag_pasivos_afp_f sobre IBK en esos 7 meses
--          y nosotros 17.3 sobre 28 meses de clean. Se parte por n_meses_360 para ver
--          si el que falla es el requisito de 6 meses seguidos o el umbral de 900,
--          y se mide el efecto de la exclusion AFP por separado
-- ============================================================================
WITH b AS (
    SELECT k.entidad,
           k.codmes_mrm,
           p.n_meses_360,
           p.saldo_pasivo_m0,
           p.flg_pasivo_6m,
           p.ctrl_retiro_afp,
           p.flag_pasivos_afp_f,
           p.ctrl_sin_360
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key k
    INNER JOIN disc_model_owner.ds_adm_vcnbank_tc_13_pasivos p
            ON p.codmes_mrm = k.codmes_mrm AND p.tip_doc = k.tip_doc AND p.id_value = k.id_value
    WHERE k.entidad = '00002'
      AND k.codmes_mrm BETWEEN '202410' AND '202504'
)
SELECT CAST(n_meses_360 AS VARCHAR)                                                     AS meses_con_360,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)                               AS pct,
       round(100.0 * avg(CASE WHEN saldo_pasivo_m0 >= 900 THEN 1.0 ELSE 0.0 END), 3)    AS pct_saldo_m0_900,
       round(100.0 * avg(CAST(flg_pasivo_6m AS DOUBLE)), 3)                             AS pct_pasivo_6m,
       round(100.0 * avg(CAST(ctrl_retiro_afp AS DOUBLE)), 3)                           AS pct_retiro_afp,
       round(100.0 * avg(CAST(flag_pasivos_afp_f AS DOUBLE)), 3)                        AS pct_flag_final,
       round(approx_percentile(saldo_pasivo_m0, 0.5), 0)                                AS saldo_m0_p50,
       round(approx_percentile(saldo_pasivo_m0, 0.9), 0)                                AS saldo_m0_p90
FROM b
GROUP BY CAST(n_meses_360 AS VARCHAR)
ORDER BY meses_con_360
