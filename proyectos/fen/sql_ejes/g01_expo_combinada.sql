-- 01 exposicion combinada r_nivel x f_lluvia
WITH z AS (
    SELECT d.ubigeo_reniec, f.r_nivel, f.d_nivel, f.f_lluvia, f.tipo_actividad,
           f.r_nivel * f.f_lluvia AS expo
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
    SELECT CAST(codmes AS INTEGER) AS codmes, id_value, flg_target_pp_12m AS y
    FROM disc_model_owner.pp_vc_ds_po_origpp
    WHERE flg_calib_rd = 1
      AND CAST(codmes AS INTEGER) BETWEEN 201901 AND 202504
      AND subproducto_ = '5.P FACIL'
      AND cod_instit_financiera = '00002'
)
, base AS (
    SELECT p.codmes, p.y,
           CASE WHEN z.r_nivel = 0 THEN 'E0'
                WHEN z.expo <= 3   THEN 'E1'
                WHEN z.expo <= 5   THEN 'E2'
                ELSE 'E3' END AS g
    FROM po p JOIN geo ON p.id_value = geo.key_value JOIN z ON geo.ubi = z.ubigeo_reniec
)
SELECT codmes,
       sum(CASE WHEN g='E0' THEN 1 ELSE 0 END) AS n_E0,
       round(100.0*sum(CASE WHEN g='E0' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='E0' THEN 1 ELSE 0 END),0), 4) AS rd_E0
,
       sum(CASE WHEN g='E1' THEN 1 ELSE 0 END) AS n_E1,
       round(100.0*sum(CASE WHEN g='E1' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='E1' THEN 1 ELSE 0 END),0), 4) AS rd_E1
,
       sum(CASE WHEN g='E2' THEN 1 ELSE 0 END) AS n_E2,
       round(100.0*sum(CASE WHEN g='E2' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='E2' THEN 1 ELSE 0 END),0), 4) AS rd_E2
,
       sum(CASE WHEN g='E3' THEN 1 ELSE 0 END) AS n_E3,
       round(100.0*sum(CASE WHEN g='E3' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='E3' THEN 1 ELSE 0 END),0), 4) AS rd_E3
FROM base GROUP BY codmes ORDER BY codmes
