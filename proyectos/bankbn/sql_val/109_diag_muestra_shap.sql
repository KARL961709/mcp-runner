-- 109_diag_muestra_shap.sql | embudo del export SHAP paso a paso para ubicar en que etapa se pierden las filas
SELECT paso, filas, detalle
FROM (
    SELECT 1 AS ord,
           'A  cal 202407-202606 con pd_raw' AS paso,
           count(*) AS filas,
           min(CAST(codmes AS VARCHAR)) || ' a ' || max(CAST(codmes AS VARCHAR)) AS detalle
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
    WHERE codmes BETWEEN '202407' AND '202606'
      AND pd_raw IS NOT NULL
    UNION ALL
    SELECT 2,
           'B  score p_codmes 202406-202605',
           count(*),
           min(CAST(p_codmes AS VARCHAR)) || ' a ' || max(CAST(p_codmes AS VARCHAR))
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202406' AND '202605'
    UNION ALL
    SELECT 3,
           'C  score TODAS las particiones',
           count(*),
           min(CAST(p_codmes AS VARCHAR)) || ' a ' || max(CAST(p_codmes AS VARCHAR))
    FROM e_perm_aws.scr_admbankbpe_rsk
    UNION ALL
    SELECT 4,
           'D  join con desfase +1 mes',
           count(*),
           CAST(count(DISTINCT g.pob) AS VARCHAR) || ' poblaciones'
    FROM e_perm_aws.scr_admbankbpe_rsk s
    JOIN (
        SELECT CAST(tip_doc AS VARCHAR) AS td, CAST(key_value AS VARCHAR) AS kv,
               CAST(codmes AS VARCHAR) AS cm,
               CASE WHEN entidad = 'IBK' THEN 'IBK'
                    WHEN entidad = 'OTRO' THEN 'SSFF'
                    ELSE 'RESTO_TOP4' END AS pob
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
        WHERE codmes BETWEEN '202407' AND '202606'
          AND pd_raw IS NOT NULL
    ) g
      ON g.td = CAST(s.tip_doc AS VARCHAR)
     AND g.kv = CAST(s.key_value AS VARCHAR)
     AND g.cm = CAST(DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(s.p_codmes AS VARCHAR), '%Y%m')), '%Y%m') AS VARCHAR)
    WHERE s.p_codmes BETWEEN '202406' AND '202605'
    UNION ALL
    SELECT 5,
           'E  join SIN desfase',
           count(*),
           CAST(count(DISTINCT g.pob) AS VARCHAR) || ' poblaciones'
    FROM e_perm_aws.scr_admbankbpe_rsk s
    JOIN (
        SELECT CAST(tip_doc AS VARCHAR) AS td, CAST(key_value AS VARCHAR) AS kv,
               CAST(codmes AS VARCHAR) AS cm,
               CASE WHEN entidad = 'IBK' THEN 'IBK'
                    WHEN entidad = 'OTRO' THEN 'SSFF'
                    ELSE 'RESTO_TOP4' END AS pob
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
        WHERE codmes BETWEEN '202407' AND '202606'
          AND pd_raw IS NOT NULL
    ) g
      ON g.td = CAST(s.tip_doc AS VARCHAR)
     AND g.kv = CAST(s.key_value AS VARCHAR)
     AND g.cm = CAST(s.p_codmes AS VARCHAR)
    WHERE s.p_codmes BETWEEN '202406' AND '202605'
) t
ORDER BY ord
