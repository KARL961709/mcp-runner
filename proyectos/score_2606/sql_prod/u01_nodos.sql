-- ============================================================================
-- u01. Universo VC (scr_vcadmbnk enriquecida) -> bins + 4 nodos por sub_producto.
--      Arbol EXTRAIDO de 02_Logica_nodos.sql (TC_ALTAS/EC/PP_FACIL/PP_CD). Ventana 202606-202608.
--      Lee bloque B (tipo_ingreso, flg_dirty_*, 10 features del nodo). Emite nodo_tc/_ec/_ppfacil/_ppcd.
-- ============================================================================
CREATE TABLE disc_model_owner.univ_vc_nodos
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes'],
      external_location = '<S3_DATOS>/univ_vc_nodos/') AS
WITH bins AS (
  SELECT
    codmes, cod_tip_doc, key_value, probabilidad AS pd_raw, tipo_ingreso, flg_dirty_tc, flg_dirty_pp,
    CASE WHEN flg_inmueble >= 0.5 THEN 'B1' WHEN flg_inmueble < 0.5 THEN 'B2' ELSE 'NA' END AS bin_flg_inmueble,
    CASE WHEN nivel_profesional IN ('02.TITU','03.TITU_2NDO','04.MAGI','05.DOCT') THEN 'B1'
    WHEN nivel_profesional IN ('01.BACH') THEN 'B2'
    WHEN nivel_profesional IS NULL THEN 'B3' ELSE 'NA' END AS bin_nivel_profesional,
    CASE WHEN cant_trx_out_tot_u3m IN ('00.0_U3M') THEN 'B1'
    WHEN cant_trx_out_tot_u3m IN ('01.1_U3M','02.2_U3M') THEN 'B2'
    WHEN cant_trx_out_tot_u3m IN ('03.3_U3M') THEN 'B3' ELSE 'NA' END AS bin_cant_trx_out_tot_u3m,
    CASE WHEN cant_trx_in_out_tot_u3m IN ('03.3_U3M') THEN 'B1'
    WHEN cant_trx_in_out_tot_u3m IN ('01.1_U3M','02.2_U3M') THEN 'B2'
    WHEN cant_trx_in_out_tot_u3m IN ('00.0_U3M') THEN 'B3' ELSE 'NA' END AS bin_cant_trx_in_out_tot_u3m,
    CASE WHEN flg_cs_v2 >= 0.5 THEN 'B1' WHEN flg_cs_v2 < 0.5 THEN 'B2' ELSE 'NA' END AS bin_flg_cs_v2,
    CASE WHEN cant_uso_tc_tot_5porc_u6m IN ('02.=2','03.=3','04.=4','05.=5','06.=6') THEN 'B1'
    WHEN cant_uso_tc_tot_5porc_u6m IN ('01.=0','01.=1') THEN 'B2'
    WHEN cant_uso_tc_tot_5porc_u6m IN ('00.NO_TC') THEN 'B3' ELSE 'NA' END AS cant_uso_tc_tot_5porc_u6m_tc,
    CASE WHEN cant_trx_in_out_tot_u6m IN ('05.5_U6M','06.6_U6M') THEN 'B1'
    WHEN cant_trx_in_out_tot_u6m IN ('02.2_U6M','03.3_U6M','04.4_U6M') THEN 'B2'
    WHEN cant_trx_in_out_tot_u6m IN ('00.0_U6M','01.1_U6M') THEN 'B3' ELSE 'NA' END AS bin_cant_trx_in_out_tot_u6m,
    CASE WHEN nro_inmuebles IN ('02.>1') THEN 'B1'
    WHEN nro_inmuebles IN ('01.=1') THEN 'B2'
    WHEN nro_inmuebles IN ('00.=0') THEN 'B3' ELSE 'NA' END AS bin_nro_inmuebles,
    CASE WHEN cant_trx_out_yap_u6m IN ('04.4_U6M','05.5_U6M','06.6_U6M') THEN 'B1'
    WHEN cant_trx_out_yap_u6m IN ('01.1_U6M','02.2_U6M','03.3_U6M') THEN 'B2'
    WHEN cant_trx_out_yap_u6m IN ('00.0_U6M') THEN 'B3' ELSE 'NA' END AS bin_cant_trx_out_yap_u6m,
    CASE WHEN cant_uso_tc_tot_5porc_u6m IN ('03.=3','04.=4','05.=5','06.=6') THEN 'B1'
    WHEN cant_uso_tc_tot_5porc_u6m IN ('00.NO_TC','01.=0','01.=1','02.=2') THEN 'B2' ELSE 'NA' END AS cant_uso_tc_tot_5porc_u6m_ppcd,
    CASE WHEN flg_top25 >= 0.5 THEN 'B1' WHEN flg_top25 < 0.5 THEN 'B2' ELSE 'NA' END AS bin_flg_top25
  FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk
  WHERE CAST(codmes AS varchar) BETWEEN '202606' AND '202608'
    AND probabilidad IS NOT NULL
    AND cod_tip_doc = '1'
)
SELECT b.*,
    CASE
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B2' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B2' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B2' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B3' THEN 'NODO 1'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B1' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B2' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B1' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B2' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B3' AND bin_cant_trx_in_out_tot_u6m='B1' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B3' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             WHEN cant_uso_tc_tot_5porc_u6m_tc='B2' AND bin_cant_trx_in_out_tot_u6m='B2' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             ELSE 'SIN_NODO'
           END AS nodo_tc,
    CASE
             WHEN bin_flg_inmueble='B1' AND bin_cant_trx_in_out_tot_u3m='B3' AND bin_flg_cs_v2='B2' THEN 'NODO 1'
             WHEN bin_flg_inmueble='B1' AND bin_cant_trx_in_out_tot_u3m='B3' AND bin_flg_cs_v2='B1' THEN 'NODO 1'
             WHEN bin_flg_inmueble='B1' AND bin_cant_trx_in_out_tot_u3m='B2' AND bin_flg_cs_v2='B2' THEN 'NODO 1'
             WHEN bin_flg_inmueble='B1' AND bin_cant_trx_in_out_tot_u3m='B2' AND bin_flg_cs_v2='B1' THEN 'NODO 1'
             WHEN bin_flg_inmueble='B1' AND bin_cant_trx_in_out_tot_u3m='B1' AND bin_flg_cs_v2='B2' THEN 'NODO 1'
             WHEN bin_flg_inmueble='B1' AND bin_cant_trx_in_out_tot_u3m='B1' AND bin_flg_cs_v2='B1' THEN 'NODO 1'
             WHEN bin_flg_inmueble='B2' AND bin_cant_trx_in_out_tot_u3m='B3' AND bin_flg_cs_v2='B1' THEN 'NODO 2'
             WHEN bin_flg_inmueble='B2' AND bin_cant_trx_in_out_tot_u3m='B2' AND bin_flg_cs_v2='B1' THEN 'NODO 2'
             WHEN bin_flg_inmueble='B2' AND bin_cant_trx_in_out_tot_u3m='B1' AND bin_flg_cs_v2='B2' THEN 'NODO 2'
             WHEN bin_flg_inmueble='B2' AND bin_cant_trx_in_out_tot_u3m='B1' AND bin_flg_cs_v2='B1' THEN 'NODO 2'
             WHEN bin_flg_inmueble='B2' AND bin_cant_trx_in_out_tot_u3m='B3' AND bin_flg_cs_v2='B2' THEN 'NODO 3'
             WHEN bin_flg_inmueble='B2' AND bin_cant_trx_in_out_tot_u3m='B2' AND bin_flg_cs_v2='B2' THEN 'NODO 3'
             ELSE 'SIN_NODO'
           END AS nodo_ec,
    CASE
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B2' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B3' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B2' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B3' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B1' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B1' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B1' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B3' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B2' THEN 'NODO 3'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B1' THEN 'NODO 3'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B2' THEN 'NODO 3'
             WHEN bin_nro_inmuebles='B3' AND bin_cant_trx_out_yap_u6m='B2' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             WHEN bin_nro_inmuebles='B2' AND bin_cant_trx_out_yap_u6m='B3' AND bin_nivel_profesional='B3' THEN 'NODO 3'
             ELSE 'SIN_NODO'
           END AS nodo_ppfacil,
    CASE
             WHEN bin_nro_inmuebles='B3' AND cant_uso_tc_tot_5porc_u6m_ppcd='B1' AND bin_flg_top25='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B2' AND cant_uso_tc_tot_5porc_u6m_ppcd='B2' AND bin_flg_top25='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B2' AND cant_uso_tc_tot_5porc_u6m_ppcd='B1' AND bin_flg_top25='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND cant_uso_tc_tot_5porc_u6m_ppcd='B2' AND bin_flg_top25='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND cant_uso_tc_tot_5porc_u6m_ppcd='B1' AND bin_flg_top25='B2' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B1' AND cant_uso_tc_tot_5porc_u6m_ppcd='B1' AND bin_flg_top25='B1' THEN 'NODO 1'
             WHEN bin_nro_inmuebles='B3' AND cant_uso_tc_tot_5porc_u6m_ppcd='B2' AND bin_flg_top25='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B3' AND cant_uso_tc_tot_5porc_u6m_ppcd='B2' AND bin_flg_top25='B1' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B3' AND cant_uso_tc_tot_5porc_u6m_ppcd='B1' AND bin_flg_top25='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B2' AND cant_uso_tc_tot_5porc_u6m_ppcd='B2' AND bin_flg_top25='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B2' AND cant_uso_tc_tot_5porc_u6m_ppcd='B1' AND bin_flg_top25='B2' THEN 'NODO 2'
             WHEN bin_nro_inmuebles='B1' AND cant_uso_tc_tot_5porc_u6m_ppcd='B2' AND bin_flg_top25='B2' THEN 'NODO 2'
             ELSE 'SIN_NODO'
           END AS nodo_ppcd
FROM bins b