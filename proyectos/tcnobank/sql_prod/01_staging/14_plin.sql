-- ============================================================================
-- 14. PLIN - ACTIVIDAD Y CONSISTENCIA EN U3M
--   scan: e_perm_aws.t_agg_retail_user_trx_plin en [codmes-3, codmes-1]
--   ancla: ventana [M-3, M-1] medida contra el csv de nodos: u3m da 57.03 por ciento
--          en IBK clean contra 56.7 del csv, incluir M se va a 65.9. La llave es
--          cif_key = id_value DIRECTO: cif_key es un hash de 64, no el cuc numerico
--   numero_trx viene como string y no castea a INTEGER en el 100 por ciento de las
--   filas, asi que va TRY_CAST a DOUBLE. tipo_transf tiene dos valores medidos
--   Se emiten las dos variantes de umbral, mayor-igual y estricto, porque el pie del
--   grafico dice mayor y la cabecera dice mayor-igual: el csv decide cual es
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_14_plin AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value,
           date_format(date_add('month', -3, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m03,
           date_format(date_add('month', -1, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m01
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
m AS (
    SELECT k.codmes_mrm,
           k.tip_doc,
           k.id_value,
           a.p_codmes,
           sum(coalesce(TRY_CAST(a.numero_trx AS DOUBLE), 0))                           AS n_trx_tot,
           sum(CASE WHEN a.tipo_transf = 'Enviadas'
                    THEN coalesce(TRY_CAST(a.numero_trx AS DOUBLE), 0) ELSE 0 END)      AS n_trx_out,
           sum(CASE WHEN a.tipo_transf = 'Enviadas'
                    THEN coalesce(TRY_CAST(a.monto_transf AS DOUBLE), 0) ELSE 0 END)    AS mto_out
    FROM po k
    INNER JOIN e_perm_aws.t_agg_retail_user_trx_plin a
           ON CAST(a.cif_key AS VARCHAR) = k.id_value
          AND a.p_codmes BETWEEN k.m03 AND k.m01
    GROUP BY k.codmes_mrm, k.tip_doc, k.id_value, a.p_codmes
)
SELECT tip_doc,
       id_value,
       CAST(count(CASE WHEN n_trx_tot > 0 THEN 1 END) AS INTEGER)                       AS cant_trx_u3m,
       CAST(count(CASE WHEN n_trx_out > 0 THEN 1 END) AS INTEGER)                       AS cant_meses_out,
       CAST(count(CASE WHEN n_trx_out > 0 AND mto_out / n_trx_out >= 30
                       THEN 1 END) AS INTEGER)                                          AS cant_30_prm_out,
       CAST(count(CASE WHEN n_trx_out > 0 AND mto_out / n_trx_out  > 30
                       THEN 1 END) AS INTEGER)                                          AS cant_30_prm_out_estricto,
       CAST(count(CASE WHEN n_trx_out >= 20 THEN 1 END) AS INTEGER)                     AS cant_20_trx_out,
       CAST(count(CASE WHEN n_trx_out  > 20 THEN 1 END) AS INTEGER)                     AS cant_20_trx_out_estricto,
       round(sum(n_trx_out), 0)                                                          AS n_trx_out_u3m,
       round(sum(mto_out), 2)                                                            AS mto_out_u3m,
       codmes_mrm
FROM m
GROUP BY tip_doc, id_value, codmes_mrm
