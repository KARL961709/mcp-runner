-- e7 EQUIVALENCIA: nuestra PO (desde RCC) vs universo del desarrollador (codmes=202405)
WITH nuestro AS (
    SELECT DISTINCT tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
    WHERE codmes = '202405'
),
suyo AS (
    SELECT DISTINCT tip_doc, key_value
    FROM disc_riesgos.universo_bank_bpe_202301_202507_uni
    WHERE codmes = '202405'
)
SELECT
    (SELECT COUNT(*) FROM nuestro) AS n_nuestro,
    (SELECT COUNT(*) FROM suyo)    AS n_suyo,
    (SELECT COUNT(*) FROM nuestro n INNER JOIN suyo s ON n.tip_doc=s.tip_doc AND n.key_value=s.key_value) AS n_comun,
    (SELECT COUNT(*) FROM nuestro n LEFT JOIN suyo s ON n.tip_doc=s.tip_doc AND n.key_value=s.key_value WHERE s.key_value IS NULL) AS solo_nuestro,
    (SELECT COUNT(*) FROM suyo s LEFT JOIN nuestro n ON n.tip_doc=s.tip_doc AND n.key_value=s.key_value WHERE n.key_value IS NULL) AS solo_suyo
