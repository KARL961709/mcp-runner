-- k05 check del motor de escenarios: aplica la formula EXACTA del overlay a una grilla sintetica (sin depender de ninguna tabla) y devuelve pd_estres por escenario, para cruzar 1-a-1 contra el simulador ANTES del CTAS grande de s05. Si los numeros cuadran con el artifact, s05 es confiable. Read-only, corre en segundos. Grilla: (pd0, r=r_reest, s, pac, ibk)
WITH cli AS (
  SELECT * FROM (VALUES
    (CAST(0.0591 AS double), CAST(3.0 AS double), CAST(0.20 AS double), CAST(1.0 AS double), CAST(0.0 AS double)),
    (0.0965, 5.0, 0.65, 1.0, 0.0),
    (0.0349, 1.0, 0.00, 1.0, 0.5),
    (0.0186, 0.0, 0.20, 0.0, 0.0),
    (0.1319, 2.0, 0.40, 1.0, 0.9),
    (0.0040, 4.0, 0.65, 1.0, 0.0)
  ) AS t(pd0, r, s, pac, ibk)
),
esc AS (
  SELECT * FROM (VALUES
    (CAST('ESC1' AS varchar), CAST(4.2 AS double), CAST(0.5 AS double), CAST(0.5 AS double), CAST(0.0 AS double)),
    ('ESC2',  3.0, 0.5, 0.5, 0.3),
    ('ESC21', 3.0, 0.6, 0.4, 0.3),
    ('ESC22', 3.0, 0.5, 0.5, 0.5),
    ('ESC31', 2.0, 0.6, 0.4, 0.3),
    ('ESC32', 2.0, 0.5, 0.5, 0.5)
  ) AS t(escenario, gamma, wf, wa, recup)
)
SELECT
  cli.pd0, cli.r, cli.s, cli.pac, cli.ibk, esc.escenario,
  round(normal_cdf(0.0, 1.0,
    inverse_normal_cdf(0.0, 1.0, cli.pd0)
    + sqrt(0.0332/(1-0.0332)) * esc.gamma * cli.pac
      * ((esc.wf*(cli.r/5.0) + esc.wa*cli.s + 0.25*(cli.r/5.0)*cli.s)
         * (1 - least(greatest(esc.recup + 0.02*greatest(cli.ibk,0.0), 0.0), 1.0)))
  ), 5) AS pd_estres
FROM cli CROSS JOIN esc
ORDER BY cli.pd0, esc.escenario
