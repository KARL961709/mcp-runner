-- q04 verifica ft por mes: ft aplicado en la tabla vs ft desplegado (a01/coef_ft_mes.csv). d_ft debe ser 0 y n_ft_dist=1 en los 30 meses. Read-only.
WITH esp(codmes, ft_esp) AS (VALUES
    (CAST('202401' AS varchar), CAST(0.0500972213 AS double)),
    ('202402', 0.0440745632),
    ('202403', 0.0406915311),
    ('202404', 0.0301055976),
    ('202405', 0.0074309607),
    ('202406', -0.0059308542),
    ('202407', -0.0111093089),
    ('202408', -0.0105964341),
    ('202409', -0.0195734232),
    ('202410', -0.0216574414),
    ('202411', -0.0174731004),
    ('202412', -0.0141084397),
    ('202501', -0.0168804423),
    ('202502', -0.0308578411),
    ('202503', -0.0380481625),
    ('202504', -0.0380481625),
    ('202505', -0.0380481625),
    ('202506', -0.0354839315),
    ('202507', -0.0348337153),
    ('202508', -0.0380481625),
    ('202509', -0.0380481625),
    ('202510', -0.0380481625),
    ('202511', -0.0380481625),
    ('202512', -0.0380481625),
    ('202601', -0.0380481625),
    ('202602', -0.0285946781),
    ('202603', 0.0117854736),
    ('202604', 0.0524730939),
    ('202605', 0.0822142922),
    ('202606', 0.0858088723),
    ('202607', 0.0867060744),
    ('202608', 0.0952213996)
),
tab AS (
  SELECT CAST(codmes AS varchar) AS codmes, MAX(ft_macro_pp) AS ft_tab, COUNT(DISTINCT ft_macro_pp) AS n_ft_dist, COUNT(*) AS n
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202608
  GROUP BY CAST(codmes AS varchar)
)
SELECT COALESCE(t.codmes, e.codmes) AS codmes, t.n, t.n_ft_dist, e.ft_esp, t.ft_tab, round(COALESCE(t.ft_tab,0) - e.ft_esp, 12) AS d_ft
FROM esp e FULL OUTER JOIN tab t ON t.codmes = e.codmes
ORDER BY codmes
