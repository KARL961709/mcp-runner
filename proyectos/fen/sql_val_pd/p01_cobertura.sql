-- p01 ¿Con qué contamos? Meses disponibles, y si RENIEC cruza con las altas.
-- Sin esto no se puede diseñar el resto: si el backtest tiene un solo mes, no hay ventana FEN.
SELECT 'meses_score'  AS que, CAST(count(DISTINCT cod_mes) AS VARCHAR) AS valor,
       min(cod_mes) AS desde, max(cod_mes) AS hasta, count(*) AS filas
FROM disc_model_owner.scr_origenpp_altas_backtest
UNION ALL
SELECT 'meses_target', CAST(count(DISTINCT CAST(codmes AS VARCHAR)) AS VARCHAR),
       min(CAST(codmes AS VARCHAR)), max(CAST(codmes AS VARCHAR)), count(*)
FROM disc_model_owner.ds_po_origpp_CS_cal_final
WHERE flg_calib = 1 AND subproducto_ = '5.P FACIL'
