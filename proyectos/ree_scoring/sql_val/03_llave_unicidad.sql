-- 03. UNICIDAD DE LA LLAVE (key_value, codmes) EN LAS DOS FUENTES
--   n distinto de n_llave_kv_mes significa que key_value no basta como llave y
--   el contraste de 04 tiene fan-out: hay que sumar el tipo de documento.
SELECT 'v4'                                                                       AS fuente,
       COUNT(*)                                                                   AS n,
       COUNT(DISTINCT CAST(key_value AS VARCHAR) || '|'
                   || CAST(codmes AS VARCHAR))                                    AS n_llave_kv_mes,
       COUNT(DISTINCT CAST(codmes AS VARCHAR))                                    AS n_meses
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
 UNION ALL
SELECT 'v5',
       COUNT(*),
       COUNT(DISTINCT CAST(key_value AS VARCHAR) || '|'
                   || CAST(codmes AS VARCHAR)),
       COUNT(DISTINCT CAST(codmes AS VARCHAR))
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
