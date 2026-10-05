-- w2610_01. GATING: cobertura del opt (driver + pd_raw) por p_codmes recientes.
--   Confirma si scr_vcbankv3_repro_opt_ ya tiene 202610 y que prob_model esta poblado. Read-only.
-- Correr:  .\Go.ps1 -SqlDir proyectos/score_2606/sql_val -Only w2610_01_opt_cobertura
SELECT
    CAST(p_codmes AS varchar) AS p_codmes,
    COUNT(*) AS n,
    COUNT(prob_model) AS n_prob_model,
    COUNT(DISTINCT key_value) AS n_kv
FROM disc_riesgos.scr_vcbankv3_repro_opt_
WHERE CAST(p_codmes AS varchar) >= '202606'
GROUP BY CAST(p_codmes AS varchar)
ORDER BY p_codmes
