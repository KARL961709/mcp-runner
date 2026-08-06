-- 05 mecanismo a nivel cliente: independiente vs dependiente, dentro y fuera del gate
WITH z AS (
    SELECT d.ubigeo_reniec, f.r_nivel
    FROM disc_model_owner.fen_score_v6 f
    JOIN e_perm_aws.t_mst_ubigeos_rsk d ON f.cod_ubigeo = d.ubigeo_sunat
)
, geo AS (
    SELECT key_value, max_by(cod_ubi_domicilio, fec_dato) AS ubi
    FROM e_perm_aws.t_mst_reniec_rsk
    WHERE cod_ubi_domicilio IS NOT NULL AND cod_ubi_domicilio <> ''
    GROUP BY key_value
)
, po AS (
    SELECT CAST(codmes AS INTEGER) AS codmes, id_value, flg_target_pp_12m AS y,
           CASE WHEN upper(tipo_ingreso) LIKE 'NO%' THEN 'I' ELSE 'D' END AS ing
    FROM disc_model_owner.pp_vc_ds_po_origpp
    WHERE flg_calib_rd = 1
      AND CAST(codmes AS INTEGER) BETWEEN 201901 AND 202504
      AND subproducto_ = '5.P FACIL'
      AND cod_instit_financiera = '00002'
      AND tipo_ingreso IS NOT NULL
)
, base AS (
    SELECT p.codmes, p.y,
           CASE WHEN z.r_nivel >= 3 THEN 'g' ELSE 'n' END || p.ing AS g
    FROM po p JOIN geo ON p.id_value = geo.key_value JOIN z ON geo.ubi = z.ubigeo_reniec
)
SELECT codmes,
       sum(CASE WHEN g='gI' THEN 1 ELSE 0 END) AS n_gI,
       round(100.0*sum(CASE WHEN g='gI' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='gI' THEN 1 ELSE 0 END),0), 4) AS rd_gI
,
       sum(CASE WHEN g='gD' THEN 1 ELSE 0 END) AS n_gD,
       round(100.0*sum(CASE WHEN g='gD' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='gD' THEN 1 ELSE 0 END),0), 4) AS rd_gD
,
       sum(CASE WHEN g='nI' THEN 1 ELSE 0 END) AS n_nI,
       round(100.0*sum(CASE WHEN g='nI' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='nI' THEN 1 ELSE 0 END),0), 4) AS rd_nI
,
       sum(CASE WHEN g='nD' THEN 1 ELSE 0 END) AS n_nD,
       round(100.0*sum(CASE WHEN g='nD' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='nD' THEN 1 ELSE 0 END),0), 4) AS rd_nD
FROM base GROUP BY codmes ORDER BY codmes
