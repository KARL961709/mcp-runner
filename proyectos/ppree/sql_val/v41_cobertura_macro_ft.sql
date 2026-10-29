-- ============================================================================
-- v41. HASTA QUE MES RESUELVE CADA f_t, y por que
--
--   La cadena de V2 en el CTAS compone la interanual sobre 12 meses de porc_ipc
--   y despues promedia 3 con LAG 0: para codmes_drv = M necesita porc_ipc del
--   PROPIO M. Y lleva HAVING COUNT(yy) = 3 sobre HAVING COUNT(porc_ipc) = 12, asi
--   que si falta un mes no devuelve una aproximacion -- no devuelve fila, el LEFT
--   JOIN deja f_t_v2 en NULL y prob_modelo_cal_v2 sale NULL para ese mes.
--
--   V1 no tiene ese problema: su ventana va de M-10 a M-5, siempre pasado.
--
--   Esto NO es un defecto del CTAS: es el costo operativo de la spec lag0 de
--   PP VC, que pide la inflacion del mes corriente cuando todavia no se publico.
--   Con lag2 llegaria dos meses mas lejos. Es una decision, no un bug, pero hay
--   que saber a partir de que mes la PD de V2 deja de existir.
--
--   Se reporta: la frontera de porc_ipc, y cuantas filas de la tabla creada
--   quedaron con cada f_t nulo, por mes.
-- ============================================================================
WITH mac AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cod_mes
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE porc_ipc IS NOT NULL
),
front AS (
  SELECT MIN(cod_mes) AS primer_mes,
         MAX(cod_mes) AS ultimo_mes,
         COUNT(*)     AS n_meses
  FROM mac
),
t AS (
  SELECT CAST(codmes_drv AS VARCHAR) AS codmes_drv,
         COUNT(*)                                                      AS n,
         SUM(CASE WHEN trf_f_t_v1 IS NULL THEN 1 ELSE 0 END)           AS n_ft_v1_nulo,
         SUM(CASE WHEN trf_f_t_v2 IS NULL THEN 1 ELSE 0 END)           AS n_ft_v2_nulo,
         SUM(CASE WHEN prob_modelo_cal_v1 IS NULL THEN 1 ELSE 0 END)   AS n_pd_v1_nula,
         SUM(CASE WHEN prob_modelo_cal_v2 IS NULL THEN 1 ELSE 0 END)   AS n_pd_v2_nula,
         ROUND(MAX(trf_f_t_v1), 6)                                     AS ft_v1,
         ROUND(MAX(trf_f_t_v2), 6)                                     AS ft_v2
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2
  GROUP BY CAST(codmes_drv AS VARCHAR)
)
SELECT t.codmes_drv,
       t.n,
       t.n_ft_v1_nulo,
       t.n_ft_v2_nulo,
       t.n_pd_v1_nula,
       t.n_pd_v2_nula,
       t.ft_v1,
       t.ft_v2,
       f.ultimo_mes AS ultimo_mes_con_porc_ipc,
       f.n_meses    AS n_meses_porc_ipc
FROM t
CROSS JOIN front f
WHERE t.codmes_drv >= '202601'
ORDER BY 1
