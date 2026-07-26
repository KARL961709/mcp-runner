-- e9 GAP: caracterizacion de los 3,389 que estan en el universo del desarrollador y no en el nuestro
WITH nuestro AS (
    SELECT DISTINCT tip_doc, key_value FROM disc_model_owner.ds_adm_bpe_bankbn_po WHERE codmes='202405'
),
suyo AS (
    SELECT tip_doc, key_value, cod_instit_financiera, nombre_instit_financiera, max_saldo, saldo_m0
    FROM disc_riesgos.universo_bank_bpe_202301_202507_uni WHERE codmes='202405'
)
SELECT
    COALESCE(s.nombre_instit_financiera,'(SIN NOMBRE EN DIM)') AS entidad,
    COUNT(*) AS n_faltante,
    SUM(CASE WHEN s.max_saldo > 0 THEN 1 ELSE 0 END) AS con_maxsaldo,
    SUM(CASE WHEN s.saldo_m0 > 0 THEN 1 ELSE 0 END) AS con_saldo_m0
FROM suyo s
LEFT JOIN nuestro n ON n.tip_doc = s.tip_doc AND n.key_value = s.key_value
WHERE n.key_value IS NULL
GROUP BY 1
ORDER BY 2 DESC
