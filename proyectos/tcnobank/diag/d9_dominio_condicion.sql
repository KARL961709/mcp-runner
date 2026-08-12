-- ============================================================================
-- D9. CONTRATO FISICO DE CONDICION - ES DIAS DE ATRASO O UN CODIGO
--   scan: e_perm_aws.t_fact_report_rcc_rsk en 202412, solo filas de TC
--   ancla: dm_tc = max(condicion) y el target compara contra 60. Si condicion fuera un
--          codigo y no dias, todo el target esta mal. Nunca se midio su dominio
-- ============================================================================
SELECT typeof(a.condicion)                                                              AS tipo,
       CASE WHEN TRY_CAST(a.condicion AS INTEGER) IS NULL          THEN '0.no numerico'
            WHEN TRY_CAST(a.condicion AS INTEGER) =   0            THEN '1.cero'
            WHEN TRY_CAST(a.condicion AS INTEGER) <=  8            THEN '2.uno a ocho'
            WHEN TRY_CAST(a.condicion AS INTEGER) <= 30            THEN '3.nueve a treinta'
            WHEN TRY_CAST(a.condicion AS INTEGER) <= 60            THEN '4.treintaiuno a sesenta'
            WHEN TRY_CAST(a.condicion AS INTEGER) <= 90            THEN '5.sesentaiuno a noventa'
            WHEN TRY_CAST(a.condicion AS INTEGER) <= 360           THEN '6.noventaiuno a trescientos sesenta'
            ELSE                                                        '7.mayor a trescientos sesenta' END AS tramo,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 4)                                AS pct,
       min(TRY_CAST(a.condicion AS INTEGER))                                             AS v_min,
       max(TRY_CAST(a.condicion AS INTEGER))                                             AS v_max,
       count(DISTINCT a.condicion)                                                       AS n_valores
FROM e_perm_aws.t_fact_report_rcc_rsk a
WHERE a.p_codmes = '202412'
  AND substr(a.cod_cuenta_rcc,1,2) = '14'
  AND a.tipo_credito IN ('11','12')
GROUP BY 1, 2
ORDER BY 1, 2
