-- ============================================================================
-- u01 nodos 202609 PILOTO (LIMIT, sin dirty): enriquecimiento (02_Logica_nodos VERBATIM) + insumo(scr v3 LEFT SBS)
--   + tipo_ingreso + flg_dirty_tc/pp (JOIN ..._2609_dirty) [OMITIDO en piloto] + 4 nodos.
--   Driver disc_riesgos.scr_vcbankv3_repro_ (poda p_codmes). Ventana 202609-202609 LIMIT 50000. pd_raw de score_vc_new_v2.
-- ============================================================================
CREATE TABLE disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_nodos_pilot
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes']) AS
WITH insumo AS (
  SELECT
    CAST(a.codmes AS VARCHAR) AS codmes,
    a.key_value,
    CAST(a.cod_tip_doc AS VARCHAR) AS tipdoc,
    b.sbs_value,
    b.cod_sbs AS codsbs,
    CAST(NULL AS varchar) AS sub_producto,
    1000 * (1 - a.probabilidad) AS score_vc_new_v2,
    CASE WHEN a.probabilidad IS NOT NULL THEN 1 ELSE 0 END AS flg_vc_new_v2
  FROM (
    SELECT codmes, key_value, cod_tip_doc, probabilidad,
           ROW_NUMBER() OVER (PARTITION BY codmes, key_value, cod_tip_doc ORDER BY probabilidad DESC) AS rn
    FROM (
      SELECT CAST(codmes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc, probabilidad
      FROM disc_riesgos.scr_vcbankv3_repro_
      WHERE probabilidad IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
        AND CAST(p_codmes AS varchar) = '202609'
        AND CAST(codmes AS varchar) BETWEEN '202609' AND '202609'
      LIMIT 50000
    )
  ) a
  LEFT JOIN (
    SELECT tip_doc, key_value, sbs_value, cod_sbs,
           ROW_NUMBER() OVER (PARTITION BY tip_doc, key_value ORDER BY fch_actualizacion DESC) AS rn_b
    FROM e_perm_aws.t_mst_ctarcc_rsk
    WHERE tip_doc = '1' AND tip_persona = '1' AND key_value IS NOT NULL AND sbs_value IS NOT NULL
  ) b ON CAST(a.cod_tip_doc AS varchar) = CAST(b.tip_doc AS varchar) AND a.key_value = b.key_value AND b.rn_b = 1
  WHERE a.rn = 1
),
snrp AS (
    SELECT key_value, tipdoc, COUNT(*) AS nro_inmuebles
    FROM e_perm_aws.t_sunarp_inmueble
    GROUP BY key_value, tipdoc
),

-- ================================================================================================
-- FUENTE 2 - SUNEDU  ->  nivel_profesional, flg_top25
--   REFERENCIA: [G1] CTE "sunedu" (L202-230) , cat nivel_profesional (L252-258), flg_top25 (L268-276).
--   Tabla:  e_perm_aws.t_maestra_profesiones   |   Cruce: key_value + tipdoc + (fecfin <= codmes)
--   Se conserva: min_cod_nivel_profesional y min_institucioneducativa (mismos nombres que [G1]).
-- ================================================================================================
sunedu AS (
    SELECT i.codmes, i.key_value, i.tipdoc,
           MIN(b.cod_nivel_profesional) AS min_cod_nivel_profesional,
           MIN(CAST(b.cod_nivel_profesional AS varchar) || b.institucioneducativa) AS min_institucioneducativa
    FROM insumo i
    INNER JOIN (   -- subquery "x" de [G1] L217-228: codifica nivel y deriva codmes_fecfin
        SELECT key_value, tipdoc, institucioneducativa,
               CASE WHEN nivel_profesional = 'BACHILLER' THEN 5
                    WHEN nivel_profesional = 'TITULO PROFESIONAL' THEN 4
                    WHEN nivel_profesional = 'TITULO DE SEGUNDA ESPECIALIDAD PROFESIONAL' THEN 3
                    WHEN nivel_profesional = 'MAESTRO' THEN 2
                    WHEN nivel_profesional = 'DOCTOR' THEN 1 END AS cod_nivel_profesional,
               CASE WHEN fecfin IS NULL OR fecfin = '' THEN '195001'
                    ELSE date_format(date_parse(fecfin, '%Y-%m-%d'), '%Y%m') END AS codmes_fecfin
        FROM e_perm_aws.t_maestra_profesiones
    ) b
      ON i.key_value = b.key_value
     AND CAST(i.tipdoc AS int) = CAST(b.tipdoc AS int)
     AND b.codmes_fecfin <= i.codmes
    GROUP BY i.codmes, i.key_value, i.tipdoc
),

-- ================================================================================================
-- FUENTE 3 - RCC STOCK (gestion de portafolio)  ->  cant_uso_tc_tot_5porc_u6m
--   REFERENCIA: [G1] CTE "rcc_tc_u6m" (L89-114) , flags flg_uso_tc_tot_Nm_5porc (L145-150),
--               flg_tc_u6m (L138-143), categorizacion (L161-170).
--   Tabla:  e_perm_aws.t_rsk_rcc_stock   |   Cruce: codsbs (trim) + linea_tc>0 + cartera=1
--   Ventana U6M: stock del mes b alineado con +2..+7 -> m1=codmes-2 ... m6=codmes-7. Nombres [G1].
-- ================================================================================================
rcc_tc AS (
    SELECT i.codmes, i.key_value, i.tipdoc,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',2,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.linea_tc  ELSE 0 END) AS linea_tc_tot_m1,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',3,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.linea_tc  ELSE 0 END) AS linea_tc_tot_m2,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',4,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.linea_tc  ELSE 0 END) AS linea_tc_tot_m3,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',5,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.linea_tc  ELSE 0 END) AS linea_tc_tot_m4,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',6,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.linea_tc  ELSE 0 END) AS linea_tc_tot_m5,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',7,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.linea_tc  ELSE 0 END) AS linea_tc_tot_m6,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',2,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.deuda_vig ELSE 0 END) AS deuda_tc_tot_m1,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',3,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.deuda_vig ELSE 0 END) AS deuda_tc_tot_m2,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',4,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.deuda_vig ELSE 0 END) AS deuda_tc_tot_m3,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',5,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.deuda_vig ELSE 0 END) AS deuda_tc_tot_m4,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',6,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.deuda_vig ELSE 0 END) AS deuda_tc_tot_m5,
        SUM(CASE WHEN i.codmes = date_format(date_add('month',7,date_parse(CAST(b.codmes AS varchar)||'01','%Y%m%d')),'%Y%m') THEN b.deuda_vig ELSE 0 END) AS deuda_tc_tot_m6
    FROM insumo i
    LEFT JOIN e_perm_aws.t_rsk_rcc_stock b -- 201601-202607
      ON b.linea_tc > 0 AND b.cartera = 1 AND trim(i.codsbs) = trim(b.codsbs) AND CAST(b.p_codmes AS varchar) BETWEEN '202602' AND '202607'
    GROUP BY i.codmes, i.key_value, i.tipdoc
),

-- ================================================================================================
-- FUENTE 4 - TRANSACCIONES PLIN/YAPE  ->  cant_trx_out_tot_u3m, cant_trx_in_out_tot_u3m,
--                                          cant_trx_in_out_tot_u6m, cant_trx_out_yap_u6m
--   REFERENCIA: [G1] CTE "trx_plin" (L326-393) + "var_plin" (L395-419) -- aqui colapsados en "plin".
--   Se conservan los nombres de salida de var_plin: trx_out_tot, trx_in_tot, trx_out_yap.
--   Tabla:  e_perm_aws.t_agg_retail_user_trx_plin   |   Cruce: cif_key(=key_value) + desfase de mes
--   trx_out_tot = Enviadas (bim+con+ibk+cce+yap) , trx_in_tot = Recibidas (idem + izi) , trx_out_yap = Enviadas Yape
-- ================================================================================================
plin AS (
    SELECT codmes, cif_key AS key_value,
        SUM(CASE WHEN tipo_transf='Enviadas'  AND banco IN ('BIM','Alfin Banco','BanBif','BBVA','Scotiabank','Consorcio','Interbank','Caja Arequipa','Caja Huancayo','Caja Ica','Caja Sullana','Financiera Confianza','Ligo Wallet','Otros bancos','Yape') THEN numero_trx ELSE 0 END) AS trx_out_tot,
        SUM(CASE WHEN tipo_transf='Recibidas' AND banco IN ('BIM','Alfin Banco','BanBif','BBVA','Scotiabank','Consorcio','Interbank','Caja Arequipa','Caja Huancayo','Caja Ica','Caja Sullana','Financiera Confianza','Ligo Wallet','Otros bancos','QR IzipayYa','Yape') THEN numero_trx ELSE 0 END) AS trx_in_tot,
        SUM(CASE WHEN tipo_transf='Enviadas'  AND banco = 'Yape' THEN numero_trx ELSE 0 END) AS trx_out_yap
    FROM (   -- [G1] L388-390: normalizacion de numero_trx
        SELECT codmes, tipo_transf, banco, cif_key,
               CAST(CAST(trim(numero_trx) AS decimal(10,2)) AS int) AS numero_trx
        FROM e_perm_aws.t_agg_retail_user_trx_plin
        WHERE CAST(p_codmes AS varchar) BETWEEN '202603' AND '202608' -- 202301-202608
    )
    GROUP BY codmes, cif_key
),

-- ================================================================================================
-- ENSAMBLE 1 (vars_raw) - trae cada variable al insumo y calcula FLAGS mensuales / valores crudos
--   REFERENCIA: [G1] joins finales L769-780 (p1..p6, cs_v2, casc) ,
--               flags trx flg_trx_*_mN (L473-507) , CASE flg_cs_v2 rama BANK (L522-628) ,
--               flg_inmueble (L264), flg_uso_tc_tot_Nm_5porc (L145-150), flg_tc_u6m (L138-143),
--               flg_top25 (L268-276).
-- ================================================================================================
vars_raw AS (
    SELECT
        i.codmes, i.key_value, i.tipdoc, i.codsbs, i.sub_producto, i.score_vc_new_v2, i.flg_vc_new_v2,

        -- ---- SUNARP ([G1] L264-265) ----
        CASE WHEN snrp.key_value IS NOT NULL THEN 1 ELSE 0 END AS flg_inmueble,
        COALESCE(snrp.nro_inmuebles,0) AS nro_inmuebles_num,

        -- ---- SUNEDU: nivel + flg_top25 ([G1] L252-258 y L268-276) ----
        sunedu.min_cod_nivel_profesional,
        CASE WHEN SUBSTR(sunedu.min_institucioneducativa,2,200) IN (
                'UNIVERSIDAD DEL PACIFICO','PONTIFICIA UNIVERSIDAD CATOLICA DEL PERU','UNIVERSIDAD CATOLICA SAN PABLO','UNIVERSIDAD DE LIMA',
                'UNIVERSIDAD ESAN','UNIVERSIDAD DE PIURA','UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS','UNIVERSIDAD NACIONAL DEL ALTIPLANO',
                'UNIVERSIDAD NACIONAL JORGE BASADRE GROHMANN','UNIVERSIDAD NACIONAL DE INGENIERIA','UNIVERSIDAD PERUANA DE CIENCIAS APLICADAS S. A. C.',
                'UNIVERSIDAD NACIONAL AGRARIA LA MOLINA','UNIVERSIDAD SAN IGNACIO DE LOYOLA S. R. L.','UNIVERSIDAD NACIONAL DE SAN AGUSTIN DE AREQUIPA',
                'UNIVERSIDAD PERUANA CAYETANO HEREDIA','UNIVERSIDAD CONTINENTAL S. A. C.','UNIVERSIDAD TECNOLOGICA DEL PERU S. A. C.',
                'UNIVERSIDAD NACIONAL FEDERICO VILLARREAL','UNIVERSIDAD DE SAN MARTIN DE PORRES','UNIVERSIDAD NACIONAL DEL CALLAO',
                'UNIVERSIDAD RICARDO PALMA','UNIVERSIDAD NACIONAL DE TRUJILLO','UNIVERSIDAD PRIVADA DEL NORTE S. A. C.','UNIVERSIDAD NACIONAL DE SAN ANTONIO ABAD DEL CUSCO',
                'UNIVERSIDAD CIENTIFICA DEL SUR S. A. C.') THEN 1 ELSE 0 END AS flg_top25,

        -- ---- RCC uso TC ([G1] L145-150 flags fullero , L138-143 flg_tc_u6m) ----
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m1,0)=0 THEN 0 WHEN rcc_tc.deuda_tc_tot_m1/rcc_tc.linea_tc_tot_m1 <= 0.05 THEN 1 ELSE 0 END AS flg_uso_tc_tot_1m_5porc,
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m2,0)=0 THEN 0 WHEN rcc_tc.deuda_tc_tot_m2/rcc_tc.linea_tc_tot_m2 <= 0.05 THEN 1 ELSE 0 END AS flg_uso_tc_tot_2m_5porc,
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m3,0)=0 THEN 0 WHEN rcc_tc.deuda_tc_tot_m3/rcc_tc.linea_tc_tot_m3 <= 0.05 THEN 1 ELSE 0 END AS flg_uso_tc_tot_3m_5porc,
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m4,0)=0 THEN 0 WHEN rcc_tc.deuda_tc_tot_m4/rcc_tc.linea_tc_tot_m4 <= 0.05 THEN 1 ELSE 0 END AS flg_uso_tc_tot_4m_5porc,
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m5,0)=0 THEN 0 WHEN rcc_tc.deuda_tc_tot_m5/rcc_tc.linea_tc_tot_m5 <= 0.05 THEN 1 ELSE 0 END AS flg_uso_tc_tot_5m_5porc,
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m6,0)=0 THEN 0 WHEN rcc_tc.deuda_tc_tot_m6/rcc_tc.linea_tc_tot_m6 <= 0.05 THEN 1 ELSE 0 END AS flg_uso_tc_tot_6m_5porc,
        CASE WHEN COALESCE(rcc_tc.linea_tc_tot_m1,0)+COALESCE(rcc_tc.linea_tc_tot_m2,0)+COALESCE(rcc_tc.linea_tc_tot_m3,0)
                 +COALESCE(rcc_tc.linea_tc_tot_m4,0)+COALESCE(rcc_tc.linea_tc_tot_m5,0)+COALESCE(rcc_tc.linea_tc_tot_m6,0) = 0 THEN '00.NO_TC' ELSE '01.SI_TC' END AS flg_tc_u6m,

        -- ---- PLIN: flags mensuales ([G1] L473-507) ----
        CASE WHEN COALESCE(p1.trx_out_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_tot_m1,
        CASE WHEN COALESCE(p2.trx_out_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_tot_m2,
        CASE WHEN COALESCE(p3.trx_out_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_tot_m3,
        CASE WHEN COALESCE(p1.trx_out_tot,0)+COALESCE(p1.trx_in_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_in_out_tot_m1,
        CASE WHEN COALESCE(p2.trx_out_tot,0)+COALESCE(p2.trx_in_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_in_out_tot_m2,
        CASE WHEN COALESCE(p3.trx_out_tot,0)+COALESCE(p3.trx_in_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_in_out_tot_m3,
        CASE WHEN COALESCE(p4.trx_out_tot,0)+COALESCE(p4.trx_in_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_in_out_tot_m4,
        CASE WHEN COALESCE(p5.trx_out_tot,0)+COALESCE(p5.trx_in_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_in_out_tot_m5,
        CASE WHEN COALESCE(p6.trx_out_tot,0)+COALESCE(p6.trx_in_tot,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_in_out_tot_m6,
        CASE WHEN COALESCE(p1.trx_out_yap,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_yap_m1,
        CASE WHEN COALESCE(p2.trx_out_yap,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_yap_m2,
        CASE WHEN COALESCE(p3.trx_out_yap,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_yap_m3,
        CASE WHEN COALESCE(p4.trx_out_yap,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_yap_m4,
        CASE WHEN COALESCE(p5.trx_out_yap,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_yap_m5,
        CASE WHEN COALESCE(p6.trx_out_yap,0) >= 1 THEN 1 ELSE 0 END AS flg_trx_out_yap_m6,

        -- ---- CUENTA SUELDO: flg_cs_v2 rama BANK ([G1] L522-628, verbatim) ----
        CASE
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig < 2500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Verde%'    AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig < 2500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Amarillo%' AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig < 2500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Naranja%'  AND cs_v2.MTO_ABONO_1M >= 800 AND cs_v2.MTO_ABONO_2M >= 800 AND cs_v2.MTO_ABONO_3M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig < 2500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Rojo%'     AND cs_v2.MTO_ABONO_1M >= 800 AND cs_v2.MTO_ABONO_2M >= 800 AND cs_v2.MTO_ABONO_3M >= 800 AND cs_v2.MTO_ABONO_4M >= 800 AND cs_v2.MTO_ABONO_5M >= 800 AND cs_v2.MTO_ABONO_6M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 2500 AND casc.ing_net_vig < 3500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Verde%'    AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 2500 AND casc.ing_net_vig < 3500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Amarillo%' AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 2500 AND casc.ing_net_vig < 3500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Naranja%'  AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 2500 AND casc.ing_net_vig < 3500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Rojo%'     AND cs_v2.MTO_ABONO_1M >= 800 AND cs_v2.MTO_ABONO_2M >= 800 AND cs_v2.MTO_ABONO_3M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 3500 AND casc.ing_net_vig < 7500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Verde%'    AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 3500 AND casc.ing_net_vig < 7500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Amarillo%' AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 3500 AND casc.ing_net_vig < 7500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Naranja%'  AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 3500 AND casc.ing_net_vig < 7500 AND cs_v2.DESC_COLOR_EMPRESA LIKE '%Rojo%'     AND cs_v2.MTO_ABONO_1M >= 800 AND cs_v2.MTO_ABONO_2M >= 800 AND cs_v2.MTO_ABONO_3M >= 800 THEN 1
            WHEN i.flg_vc_new_v2 = 1 AND casc.ing_net_vig >= 7500 AND cs_v2.MTO_ABONO_1M >= 800 THEN 1
            ELSE 0
        END AS flg_cs_v2

    FROM insumo i
    -- SUNARP: [G1] L288
    LEFT JOIN snrp
           ON i.key_value = snrp.key_value AND CAST(i.tipdoc AS varchar) = snrp.tipdoc
    -- SUNEDU: [G1] L287
    LEFT JOIN sunedu
           ON i.codmes = sunedu.codmes AND i.key_value = sunedu.key_value AND i.tipdoc = sunedu.tipdoc
    -- RCC stock: [G1] L156 (join a rcc_tc)
    LEFT JOIN rcc_tc
           ON i.codmes = rcc_tc.codmes AND i.key_value = rcc_tc.key_value AND i.tipdoc = rcc_tc.tipdoc
    -- PLIN p1..p6 con desfase de mes: [G1] L771-776
    LEFT JOIN plin p1 ON p1.key_value = i.key_value AND i.codmes = date_format(date_add('month',1,date_parse(substring(p1.codmes,1,6),'%Y%m')),'%Y%m')
    LEFT JOIN plin p2 ON p2.key_value = i.key_value AND i.codmes = date_format(date_add('month',2,date_parse(substring(p2.codmes,1,6),'%Y%m')),'%Y%m')
    LEFT JOIN plin p3 ON p3.key_value = i.key_value AND i.codmes = date_format(date_add('month',3,date_parse(substring(p3.codmes,1,6),'%Y%m')),'%Y%m')
    LEFT JOIN plin p4 ON p4.key_value = i.key_value AND i.codmes = date_format(date_add('month',4,date_parse(substring(p4.codmes,1,6),'%Y%m')),'%Y%m')
    LEFT JOIN plin p5 ON p5.key_value = i.key_value AND i.codmes = date_format(date_add('month',5,date_parse(substring(p5.codmes,1,6),'%Y%m')),'%Y%m')
    LEFT JOIN plin p6 ON p6.key_value = i.key_value AND i.codmes = date_format(date_add('month',6,date_parse(substring(p6.codmes,1,6),'%Y%m')),'%Y%m')
    -- CUENTA SUELDO cs_v2: [G1] L779  (cod_mes = codmes-1)
    LEFT JOIN e_perm_aws.t_fact_rsk_cuenta_sueldo cs_v2
           ON cs_v2.cod_tip_doc = '1' AND cs_v2.key_value = i.key_value
          AND cs_v2.cod_mes = date_format(date_add('month',-1,date_parse(i.codmes,'%Y%m')),'%Y%m')
    -- RENTA casc: [G1] L778 (verbatim, incl. filtro de periodos). Nota: [G1] usa awsdatacatalog.e_perm_aws.<tabla> (mismo esquema).
    LEFT JOIN (
        SELECT periodo, substring(subject_id,1,1) AS tipdoc, substring(subject_id,3,80) AS key_value, ing_net_vig, numcarga
        FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
        WHERE (periodo >= '202401' AND periodo <= '202510')
           OR (periodo = '202511' AND p_fecinformacion IN ('20251107'))
           OR periodo >= '202512'
    ) casc
           ON casc.key_value = i.key_value AND casc.tipdoc = '1' AND casc.numcarga = 2 AND casc.periodo = i.codmes
),

-- ================================================================================================
-- ENSAMBLE 2 (vars) - CATEGORIZA cada variable a su string final
--   REFERENCIA: [G1] cant_trx_*_u3m/u6m (L789-869) , cant_uso_tc_tot_5porc_u6m (L161-170) ,
--               nivel_profesional (L252-258) , nro_inmuebles (L265). Mismos nombres y cortes.
-- ================================================================================================
vars AS (
    SELECT
        codmes, key_value, tipdoc, sub_producto, score_vc_new_v2, flg_vc_new_v2,
        flg_inmueble,
        flg_cs_v2,
        flg_top25,
        CASE WHEN nro_inmuebles_num = 0 THEN '00.=0' WHEN nro_inmuebles_num = 1 THEN '01.=1' WHEN nro_inmuebles_num > 1 THEN '02.>1' END AS nro_inmuebles,
        CASE WHEN min_cod_nivel_profesional = 5 THEN '01.BACH'
             WHEN min_cod_nivel_profesional = 4 THEN '02.TITU'
             WHEN min_cod_nivel_profesional = 3 THEN '03.TITU_2NDO'
             WHEN min_cod_nivel_profesional = 2 THEN '04.MAGI'
             WHEN min_cod_nivel_profesional = 1 THEN '05.DOCT' END AS nivel_profesional,
        CASE
            WHEN flg_tc_u6m = '00.NO_TC' THEN '00.NO_TC'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 0 THEN '01.=0'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 1 THEN '01.=1'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 2 THEN '02.=2'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 3 THEN '03.=3'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 4 THEN '04.=4'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 5 THEN '05.=5'
            WHEN (flg_uso_tc_tot_1m_5porc+flg_uso_tc_tot_2m_5porc+flg_uso_tc_tot_3m_5porc+flg_uso_tc_tot_4m_5porc+flg_uso_tc_tot_5m_5porc+flg_uso_tc_tot_6m_5porc) = 6 THEN '06.=6'
        END AS cant_uso_tc_tot_5porc_u6m,
        CASE (flg_trx_out_tot_m1+flg_trx_out_tot_m2+flg_trx_out_tot_m3)
            WHEN 3 THEN '03.3_U3M' WHEN 2 THEN '02.2_U3M' WHEN 1 THEN '01.1_U3M' WHEN 0 THEN '00.0_U3M' END AS cant_trx_out_tot_u3m,
        CASE (flg_trx_in_out_tot_m1+flg_trx_in_out_tot_m2+flg_trx_in_out_tot_m3)
            WHEN 3 THEN '03.3_U3M' WHEN 2 THEN '02.2_U3M' WHEN 1 THEN '01.1_U3M' WHEN 0 THEN '00.0_U3M' END AS cant_trx_in_out_tot_u3m,
        CASE (flg_trx_in_out_tot_m1+flg_trx_in_out_tot_m2+flg_trx_in_out_tot_m3+flg_trx_in_out_tot_m4+flg_trx_in_out_tot_m5+flg_trx_in_out_tot_m6)
            WHEN 6 THEN '06.6_U6M' WHEN 5 THEN '05.5_U6M' WHEN 4 THEN '04.4_U6M' WHEN 3 THEN '03.3_U6M'
            WHEN 2 THEN '02.2_U6M' WHEN 1 THEN '01.1_U6M' WHEN 0 THEN '00.0_U6M' END AS cant_trx_in_out_tot_u6m,
        CASE (flg_trx_out_yap_m1+flg_trx_out_yap_m2+flg_trx_out_yap_m3+flg_trx_out_yap_m4+flg_trx_out_yap_m5+flg_trx_out_yap_m6)
            WHEN 6 THEN '06.6_U6M' WHEN 5 THEN '05.5_U6M' WHEN 4 THEN '04.4_U6M' WHEN 3 THEN '03.3_U6M'
            WHEN 2 THEN '02.2_U6M' WHEN 1 THEN '01.1_U6M' WHEN 0 THEN '00.0_U6M' END AS cant_trx_out_yap_u6m
    FROM vars_raw
),

-- ================================================================================================
-- BINNING (bins) - agrupa cada categoria en B1/B2/B3 y el score en quintiles G1..G5
--   REFERENCIA: [G2] CTE "bins" (L64-178): grupos_quintil (L66-106) y todos los bin_* (L108-178).
--   Nombres de columna identicos a [G2].
-- ================================================================================================
bins AS (
    SELECT v.*,
        CASE
            WHEN sub_producto = 'TC_ALTAS' THEN CASE WHEN score_vc_new_v2>=942 THEN 'G1' WHEN score_vc_new_v2>=903 THEN 'G2' WHEN score_vc_new_v2>=862 THEN 'G3' WHEN score_vc_new_v2>=807 THEN 'G4' ELSE 'G5' END
            WHEN sub_producto = 'PP_FACIL' THEN CASE WHEN score_vc_new_v2>=954 THEN 'G1' WHEN score_vc_new_v2>=927 THEN 'G2' WHEN score_vc_new_v2>=895 THEN 'G3' WHEN score_vc_new_v2>=847 THEN 'G4' ELSE 'G5' END
            WHEN sub_producto = 'PP_CD'    THEN CASE WHEN score_vc_new_v2>=967 THEN 'G1' WHEN score_vc_new_v2>=950 THEN 'G2' WHEN score_vc_new_v2>=930 THEN 'G3' WHEN score_vc_new_v2>=896 THEN 'G4' ELSE 'G5' END
            WHEN sub_producto = 'EC'       THEN CASE WHEN score_vc_new_v2>=943 THEN 'G1' WHEN score_vc_new_v2>=913 THEN 'G2' WHEN score_vc_new_v2>=878 THEN 'G3' WHEN score_vc_new_v2>=826 THEN 'G4' ELSE 'G5' END
            WHEN sub_producto = 'CDD'      THEN CASE WHEN score_vc_new_v2>=948 THEN 'G1' WHEN score_vc_new_v2>=918 THEN 'G2' WHEN score_vc_new_v2>=881 THEN 'G3' WHEN score_vc_new_v2>=821 THEN 'G4' ELSE 'G5' END
        END AS grupos_quintil,
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
    FROM vars v
),
tipoing AS (
  SELECT codmes, key_value, tipdoc,
    CASE WHEN tipo_ingreso = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO_DEP' END AS tipo_ingreso
  FROM (
    SELECT codmes, key_value, tipdoc,
      CASE WHEN sit_lab = 'DEPENDIENTE' AND fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
           WHEN sit_lab = 'DEPENDIENTE' AND fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
           WHEN sit_lab = 'MIXTO' THEN 'MIXTO' ELSE 'INDEPENDIENTE' END AS tipo_ingreso,
      ROW_NUMBER() OVER (PARTITION BY key_value, codmes, tipdoc ORDER BY p_fecinformacion DESC) AS rn
    FROM (
      SELECT a.periodo AS codmes, SUBSTR(a.subject_id, 3) AS key_value, CAST(a.tip_doc AS varchar) AS tipdoc,
             a.fuente, a.sit_lab, a.p_fecinformacion
      FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
      WHERE CAST(a.numcarga AS INT) = 1
        AND CAST(a.periodo AS varchar) BETWEEN '202609' AND '202609'
    )
  )
  WHERE rn = 1
)
SELECT
    b.tipdoc AS cod_tip_doc,
    b.key_value,
    (1 - b.score_vc_new_v2 / 1000.0) AS pd_raw,
    ti.tipo_ingreso,
    0 AS flg_dirty_tc,
    0 AS flg_dirty_pp,
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
             ELSE 'NODO 3'
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
             ELSE 'NODO 3'
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
             ELSE 'NODO 3'
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
             ELSE 'NODO 2'
           END AS nodo_ppcd,
    b.codmes
FROM bins b
LEFT JOIN tipoing ti ON ti.codmes = b.codmes AND ti.key_value = b.key_value AND ti.tipdoc = b.tipdoc