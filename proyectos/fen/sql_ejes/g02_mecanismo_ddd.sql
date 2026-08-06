-- 02 mecanismo: agro/pesca vs servicios, dentro y fuera del gate Pacifico
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
           CASE WHEN z.r_nivel >= 3 THEN 'G' ELSE 'N' END ||
           CASE WHEN z.tipo_actividad IN ('AGRICOLA','AGRO_PLURAL','PESQUERO')
                THEN 'A' ELSE 'S' END AS g
    FROM po p JOIN geo ON p.id_value = geo.key_value JOIN z ON geo.ubi = z.ubigeo_reniec
)
SELECT codmes,
       sum(CASE WHEN g='GA' THEN 1 ELSE 0 END) AS n_GA,
       round(100.0*sum(CASE WHEN g='GA' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='GA' THEN 1 ELSE 0 END),0), 4) AS rd_GA
,
       sum(CASE WHEN g='GS' THEN 1 ELSE 0 END) AS n_GS,
       round(100.0*sum(CASE WHEN g='GS' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='GS' THEN 1 ELSE 0 END),0), 4) AS rd_GS
,
       sum(CASE WHEN g='NA' THEN 1 ELSE 0 END) AS n_NA,
       round(100.0*sum(CASE WHEN g='NA' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='NA' THEN 1 ELSE 0 END),0), 4) AS rd_NA
,
       sum(CASE WHEN g='NS' THEN 1 ELSE 0 END) AS n_NS,
       round(100.0*sum(CASE WHEN g='NS' THEN y ELSE 0 END)
             / nullif(sum(CASE WHEN g='NS' THEN 1 ELSE 0 END),0), 4) AS rd_NS
FROM base GROUP BY codmes ORDER BY codmes
