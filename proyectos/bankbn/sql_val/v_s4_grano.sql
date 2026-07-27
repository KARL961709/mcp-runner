-- v_s4_grano.sql | unicidad de (p_codmes,tip_doc,key_value): si duplica, el LEFT JOIN infla el MAD
WITH d AS (
    SELECT p_codmes, tip_doc, key_value, count(1) AS n
    FROM e_perm_aws.scr_admbankbpe_rsk
    GROUP BY 1,2,3
    HAVING count(1) > 1
)
SELECT count(1)  AS granos_duplicados,
       sum(n)    AS filas_afectadas,
       max(n)    AS max_repeticiones
FROM d
