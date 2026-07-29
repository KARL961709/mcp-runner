-- x3  contrato fisico de las llaves del join, medido en la tabla nueva
-- El join de 50_pd castea key_value, cod_tip_doc y codmes a VARCHAR: si el
-- formato difiere del de la PO el cruce falla en silencio y pd_raw queda nulo
SELECT 'key_value' AS col,
       CAST(MIN(LENGTH(CAST(key_value AS VARCHAR))) AS VARCHAR) AS len_min,
       CAST(MAX(LENGTH(CAST(key_value AS VARCHAR))) AS VARCHAR) AS len_max,
       CAST(SUM(CASE WHEN CAST(key_value AS VARCHAR) <> TRIM(CAST(key_value AS VARCHAR)) THEN 1 ELSE 0 END) AS VARCHAR) AS con_espacios,
       CAST(COUNT(DISTINCT CAST(key_value AS VARCHAR)) AS VARCHAR) AS n_distintos
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
UNION ALL
SELECT 'cod_tip_doc',
       CAST(MIN(LENGTH(CAST(cod_tip_doc AS VARCHAR))) AS VARCHAR),
       CAST(MAX(LENGTH(CAST(cod_tip_doc AS VARCHAR))) AS VARCHAR),
       CAST(SUM(CASE WHEN CAST(cod_tip_doc AS VARCHAR) LIKE '0%' THEN 1 ELSE 0 END) AS VARCHAR),
       CAST(COUNT(DISTINCT CAST(cod_tip_doc AS VARCHAR)) AS VARCHAR)
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
UNION ALL
SELECT 'codmes',
       CAST(MIN(LENGTH(CAST(codmes AS VARCHAR))) AS VARCHAR),
       CAST(MAX(LENGTH(CAST(codmes AS VARCHAR))) AS VARCHAR),
       '0',
       CAST(COUNT(DISTINCT CAST(codmes AS VARCHAR)) AS VARCHAR)
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
