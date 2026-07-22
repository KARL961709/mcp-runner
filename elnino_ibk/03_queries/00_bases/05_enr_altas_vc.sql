-- ============================================================
-- 05 · BASE Altas (originaciones)  ->  disc_model_owner.ENR_VC_FEM_3
-- ============================================================
-- Grano: originación (cohorte = codmes de alta) desde universo_altas_tc_pp_vc_.
-- Tres targets a 12m: DEF12_TC, DEF12_PP, DEF12_VC_ (NULL si codmes>202503).
-- tipo_producto separa SOLO_TC / SOLO_PP. Historia: 202301-202503.
-- Reniec restringido a deptos de zonas afectadas (optimización del join).
-- ============================================================
DROP TABLE IF EXISTS disc_model_owner.ENR_VC_FEM_3;

CREATE TABLE disc_model_owner.ENR_VC_FEM_3 AS
WITH BASE AS (
  SELECT
    A.codmes, A.key_value, B.TIP_DOC, A.sbs_value,
    A.tipo_producto, A.tipo_cliente_tc, A.tipo_cliente_PP,
    CASE WHEN A.codmes > 202503 THEN NULL ELSE A.DEF12_TC END AS DEF12_TC,
    CASE WHEN A.codmes > 202503 THEN NULL ELSE A.DEF12_PP END AS DEF12_PP,
    CASE WHEN A.codmes > 202503 THEN NULL ELSE A.DEF12_VC_ END AS DEF12_VC_,
    B.cod_ubi_domicilio,
    TRIM(UPPER(B.dis_ubi_domicilio)) AS dis_ubi_domicilio,
    TRIM(UPPER(B.pro_ubi_domicilio)) AS pro_ubi_domicilio,
    TRIM(UPPER(B.dep_ubi_domicilio)) AS dep_ubi_domicilio,
    CASE WHEN B.key_value IS NOT NULL THEN 1 ELSE 0 END AS FLG_CRUCE
  FROM disc_model_owner.universo_altas_tc_pp_vc_ A
  LEFT JOIN (SELECT * FROM e_perm_aws.t_mst_reniec_rsk
             WHERE dep_ubi_domicilio IN (SELECT DISTINCT DESC_DEPARTAMENTO FROM d_perm_aws.t_mst_zonas_afectadas_tmp)) B
    ON A.key_value = B.key_value AND B.TIP_DOC='1'
  WHERE A.dups = 0
    AND A.tipo_producto IN ('SOLO_PP','SOLO_TC')
    AND (A.tipo_cliente_tc IN ('2.MALO','5.BUENO') OR A.tipo_cliente_PP IN ('BUENO','MALO'))
    AND (A.flg_entidad_pp = 1 OR A.flg_entidad_tc = 1)
),
tabla_lluvias AS (
  SELECT cod_ubigeo,
    TRIM(UPPER(desc_departamento)) AS desc_departamento,
    TRIM(UPPER(desc_provincia))    AS desc_provincia,
    TRIM(UPPER(desc_distrito))     AS desc_distrito,
    max(cast(desc_nivel AS integer)) AS desc_nivel,
    max(cast(flg_ze_ds AS integer))  AS flg_ze_ds,
    MAX(CASE WHEN desc_distrito IN ('YANAHUARA','CAYMA','CERRO COLORADO') THEN '4'
      WHEN cod_ubigeo IN ('040126','040103','040104','040109','131203','140117','021014','130201',
        '130801','040129','040117','130103','130402','020504','040107','130808','140304',
        '140102','140303','140308','020111','130202','130601','040307','130102','040501',
        '130403','130803','130809','200105','021101','022003','130106','131201','131202',
        '020201','130208','130611','200110','200401','140205','200114','200706','110104') THEN '4'
      ELSE desc_nivel END) AS nivel
  FROM d_perm_aws.t_mst_zonas_afectadas_tmp GROUP BY 1,2,3,4
)
SELECT A.*, B.nivel,
  CASE WHEN B.cod_ubigeo IS NOT NULL THEN 1 ELSE 0 END AS FLG_CRUCE_2
FROM BASE A
LEFT JOIN tabla_lluvias B
  ON A.dep_ubi_domicilio = B.desc_departamento
 AND A.pro_ubi_domicilio = B.desc_provincia
 AND A.dis_ubi_domicilio = B.desc_distrito;
