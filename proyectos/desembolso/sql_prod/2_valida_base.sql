-- 2_valida_base.sql | valida la base b46029_desemb_base_202609: por producto, cuenta filas, clientes con pd_raw (cobertura del score BPE), sin_pd, y estadisticos del pd_raw crudo (media, min, max) para confirmar que el as-of trajo el score bien antes de agregar el target. READ-ONLY
SELECT desc_producto,
       count(*) AS n,
       sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END) AS con_pd,
       round(100.0 * sum(CASE WHEN sin_pd = 0 THEN 1 ELSE 0 END) / count(*), 1) AS pct_con_pd,
       sum(flg_impulsa) AS n_impulsa,
       round(100.0 * avg(CASE WHEN sin_pd = 0 THEN pd_raw END), 3) AS pd_raw_medio_pct,
       round(100.0 * min(CASE WHEN sin_pd = 0 THEN pd_raw END), 3) AS pd_min_pct,
       round(100.0 * max(CASE WHEN sin_pd = 0 THEN pd_raw END), 3) AS pd_max_pct
FROM disc_model_owner.b46029_desemb_base_202609
GROUP BY desc_producto
ORDER BY n DESC
