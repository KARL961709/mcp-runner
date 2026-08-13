-- ============================================================================
-- 13. PASIVOS Y RETIRO AFP
--   scan: t_aws_360_cliente_mes_d3 en [codmes-5, codmes] U t_fact_edc_solicitud_retiro_afp_ibk
--   ancla: pasivo k=0 sobre 6 meses seguidos. AFP anclado en ts_solicitud <= fin de M:
--          sin esa condicion la exclusion mira al futuro. flg_abono=1 porque solicitar
--          no es cobrar, aunque medido cambia poco (96 a 99.7 por ciento cobra)
--   el 360 arranca en 202011, asi que el flag existe desde 202104. Ausencia de fila
--   significa que no es cliente del snapshot, o sea sin deposito en IBK: cuenta como 0
--   y viaja ctrl_sin_360 para poder medirlo
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_13_pasivos AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value,
           date_format(date_add('month', -5, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m05
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
s AS (
    SELECT p.codmes_mrm,
           p.tip_doc,
           p.id_value,
           CAST(a.codmes AS VARCHAR)                                                    AS codmes,
           max(coalesce(TRY_CAST(a.saldo_fdp_tot_inversion  AS DOUBLE), 0)
                     + coalesce(TRY_CAST(a.saldo_fdp_tot_millonaria AS DOUBLE), 0)
                     + coalesce(TRY_CAST(a.saldo_fdp_tot_planilla   AS DOUBLE), 0)
                     + coalesce(TRY_CAST(a.saldo_fdp_tot_plazo_fijo AS DOUBLE), 0)
                     + coalesce(TRY_CAST(a.saldo_fdp_tot_txs        AS DOUBLE), 0)
                     + coalesce(TRY_CAST(a.saldo_fdp_tot_alcancia   AS DOUBLE), 0)
                     + coalesce(TRY_CAST(a.saldo_fdp_tot_ahor_cred  AS DOUBLE), 0))                                                               AS saldo
    FROM po p
    INNER JOIN e_perm_aws.t_aws_360_cliente_mes_d3 a
           ON a.key_value = p.id_value
          AND CAST(a.cod_tipo_documento AS VARCHAR) = p.tip_doc
          AND CAST(a.codmes AS VARCHAR) BETWEEN p.m05 AND p.codmes_mrm
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, CAST(a.codmes AS VARCHAR)
),
f AS (
    SELECT codmes_mrm, tip_doc, id_value,
           count(*)                                                                     AS n_meses_360,
           min(saldo)                                                                   AS saldo_min,
           max(CASE WHEN codmes = codmes_mrm THEN saldo END)                            AS saldo_m0
    FROM s
    GROUP BY codmes_mrm, tip_doc, id_value
),
afp AS (
    SELECT DISTINCT CAST(key_value AS VARCHAR)                                          AS id_value,
           CAST(cod_tip_doc AS VARCHAR)                                                 AS tip_doc,
           date_format(ts_solicitud, '%Y%m')                                            AS codmes_retiro
    FROM e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk
    WHERE flg_abono = 1
),
r AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value,
           max(CASE WHEN a.codmes_retiro <= p.codmes_mrm THEN 1 ELSE 0 END)             AS retiro_afp
    FROM po p
    INNER JOIN afp a ON a.id_value = p.id_value AND a.tip_doc = p.tip_doc
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value
)
SELECT p.tip_doc,
       p.id_value,
       CAST(coalesce(f.n_meses_360, 0) AS INTEGER)                                      AS n_meses_360,
       coalesce(f.saldo_m0, 0)                                                          AS saldo_pasivo_m0,
       CAST(CASE WHEN f.n_meses_360 = 6 AND f.saldo_min >= 900 THEN 1 ELSE 0 END AS INTEGER) AS flg_pasivo_6m,
       CAST(coalesce(r.retiro_afp, 0) AS INTEGER)                                       AS ctrl_retiro_afp,
       CAST(CASE WHEN f.n_meses_360 = 6 AND f.saldo_min >= 900
                  AND coalesce(r.retiro_afp, 0) = 0 THEN 1 ELSE 0 END AS INTEGER)       AS flag_pasivos_afp_f,
       CAST(CASE WHEN f.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                  AS ctrl_sin_360,
       p.codmes_mrm
FROM po p
LEFT JOIN f ON f.codmes_mrm = p.codmes_mrm AND f.tip_doc = p.tip_doc AND f.id_value = p.id_value
LEFT JOIN r ON r.codmes_mrm = p.codmes_mrm AND r.tip_doc = p.tip_doc AND r.id_value = p.id_value
