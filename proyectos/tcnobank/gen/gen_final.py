# -*- coding: utf-8 -*-
"""Cadena TCNOBANK. Estilo del motor: banner de seccion, comentarios al minimo,
el racional vive en LEEME.md. Un statement por archivo, sin punto y coma."""
import io, os, shutil

P    = r"C:\Users\CARLOS\mcp-runner\proyectos\tcnobank"
PROD = os.path.join(P, "sql_prod")
VAL  = os.path.join(P, "sql_val_cal")
T    = "disc_model_owner.ds_adm_vcnbank_tc"
LO, HI   = "201902", "202605"      # ventana de alta. Los horizontes cortos compran meses
MAXDATO  = "202606"                # ultimo codmes del RCC, medido
UMBRAL   = 60
AGG_LO, AGG_HI = "201701", "202606"

for d in (PROD, VAL):
    if os.path.isdir(d): shutil.rmtree(d)

def w(root, sub, name, titulo, sql):
    d = os.path.join(root, sub) if sub else root
    if not os.path.isdir(d): os.makedirs(d)
    ban = ("-- " + "=" * 76 + "\n-- " + titulo + "\n-- " + "=" * 76 + "\n")
    io.open(os.path.join(d, name), "w", encoding="ascii", newline="\n").write(
        ban + sql.strip().replace("__T__", T) + "\n")

def CAB(suf, part="codmes_mrm"):
    return ("WITH (\n    format              = 'PARQUET',\n    parquet_compression = 'SNAPPY',\n"
            "    partitioned_by      = ARRAY['%s'],\n"
            "    external_location   = '<S3_DATOS>/adm_vcnbank_tc_%s/'\n) AS" % (part, suf))

def mes(a, k):
    return "date_format(date_add('month', %d, date_parse(%s, '%%Y%%m')), '%%Y%%m')" % (k, a)

def meses(a, b):
    y, m = int(a[:4]), int(a[4:]); o = []
    while True:
        c = "%04d%02d" % (y, m)
        if c > b: break
        o.append(c); m += 1
        if m == 13: y, m = y + 1, 1
    return o

TC = """(    (    substr(a.cod_cuenta_rcc,1,2) = '14'
              AND a.tipo_credito IN ('11','12')
              AND (   substr(a.cod_cuenta_rcc,4,7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                       '6030202','1030209','5030209','6030209','5031902',
                                                       '1030203','5030203','6030203','1030613','4030613',
                                                       '5030613','6030613','5031908','6031908','5031998','6031998')
                   OR substr(a.cod_cuenta_rcc,4,5) IN ('10304','40304','50304','60304','40302',
                                                       '10308','40308','50308','60308') ) )
         OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923') )"""

# ============================ 05 capa agregada ============================
tt = meses(AGG_LO, AGG_HI); tr = [tt[i:i+12] for i in range(0, len(tt), 12)]
pp = []
for t in tr:
    if t[0] <= "201812" < t[-1]:
        pp.append([m for m in t if m <= "201812"]); pp.append([m for m in t if m > "201812"])
    else: pp.append(t)
tr = pp

AGG = """SELECT a.tip_doc,
       a.key_value,
       ltrim(rtrim(a.cod_instit_financiera))                                          AS entidad,
       max(CASE WHEN __TC__ THEN 1 ELSE 0 END)                                        AS flg_tc,
       max(CASE WHEN __TC__ THEN a.condicion END)                                     AS dm_tc,
       sum(CASE WHEN __TC__ THEN a.saldo END)                                         AS saldo_tc,
       sum(CASE WHEN ( (   (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) = '923')
                        OR (substr(a.cod_cuenta_rcc,1,2) || '0' || substr(a.cod_cuenta_rcc,4,3) = '720506')
                        OR (substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                        OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925')) )
                       AND a.tipo_credito IN ('11','12','13') )
                    OR (substr(a.cod_cuenta_rcc,1,2) = '81' AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925')
                        AND a.tipo_credito = '99')
                THEN a.saldo END)                                                     AS sld_bank,
       sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                 AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925') THEN a.saldo END)  AS monto_cast,
       sum(CASE WHEN ( (substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) = '4')
                     OR (substr(a.cod_cuenta_rcc,1,2) || '0' || substr(a.cod_cuenta_rcc,4,1) IN ('1405','1406')
                         AND substr(a.cod_cuenta_rcc,7,2) = '19') )
                 AND a.cod_clasificacion_deudor <> '8' THEN a.saldo END)              AS sld_ref,
       sum(CASE WHEN ( (substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) = '3')
                     OR (substr(a.cod_cuenta_rcc,1,2) || '0' || substr(a.cod_cuenta_rcc,4,1) IN ('1405','1406')
                         AND substr(a.cod_cuenta_rcc,7,2) = '22') )
                 AND a.cod_clasificacion_deudor <> '8' THEN a.saldo END)              AS sld_ree,
       sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14' AND substr(a.cod_cuenta_rcc,4,1) = '6'
                 AND a.cod_clasificacion_deudor <> '8' THEN a.saldo END)              AS sld_jud,
       max(a.cod_clasificacion_deudor)                                                AS clasif_max,
       max(CASE WHEN a.tipo_credito NOT IN ('11','12','13','99') THEN 1 ELSE 0 END)   AS flg_no_consumo,
       a.p_codmes                                                                     AS codmes
FROM __F__ a
WHERE a.p_codmes BETWEEN '__LO__' AND '__HI__'
GROUP BY a.tip_doc, a.key_value, ltrim(rtrim(a.cod_instit_financiera)), a.p_codmes"""

for i, t in enumerate(tr, 1):
    lo, hi = t[0], t[-1]
    f = "d_perm_aws.t_fact_report_rcc_rsk" if hi <= "201812" else "e_perm_aws.t_fact_report_rcc_rsk"
    verbo = ("CREATE TABLE %s_05_rcc_agg\n%s\n" % (T, CAB("05_rcc_agg", "codmes"))) if i == 1 \
            else "INSERT INTO %s_05_rcc_agg\n" % T
    w(PROD, "01_staging", "05_rcc_agg_t%02d.sql" % i,
      "05. CAPA AGREGADA DEL RCC - TRAMO %d DE %d (%s A %s)" % (i, len(tr), lo, hi),
      verbo + AGG.replace("__TC__", TC).replace("__F__", f).replace("__LO__", lo).replace("__HI__", hi))

# ============================ 10 poblacion ============================
w(PROD, "01_staging", "10_po.sql", "10. POBLACION OBJETIVO - ALTA DE TC DERIVADA DEL RCC",
"""CREATE TABLE __T___10_po
%s
WITH tc AS (
    SELECT codmes, tip_doc, key_value, entidad, saldo_tc
    FROM __T___05_rcc_agg
    WHERE flg_tc = 1
)
SELECT a.tip_doc,
       a.key_value                                                                     AS id_value,
       a.entidad,
       a.saldo_tc                                                                      AS saldo_tc_ori,
       a.codmes                                                                        AS codmes_mrm
FROM tc a
LEFT JOIN tc b
       ON b.tip_doc   = a.tip_doc
      AND b.key_value = a.key_value
      AND b.entidad   = a.entidad
      AND b.codmes   >= %s
      AND b.codmes   <= %s
WHERE a.codmes BETWEEN '%s' AND '%s'
  AND b.key_value IS NULL""" % (CAB("10_po"), mes("a.codmes", -12), mes("a.codmes", -1), LO, HI))

# ============================ 11 llaves ============================
w(PROD, "01_staging", "11_po_key.sql", "11. LLAVES - SBS_VALUE Y COD_CUC CON COBERTURA",
"""CREATE TABLE __T___11_po_key
%s
WITH sbs AS (
    SELECT tip_doc, key_value, sbs_value FROM (
        SELECT tip_doc, key_value, sbs_value,
               row_number() OVER (PARTITION BY tip_doc, key_value
                                  ORDER BY fch_creacion DESC, sbs_value ASC) AS rn
        FROM e_perm_aws.t_mst_ctarcc_rsk) x
    WHERE x.rn = 1
),
cuc AS (
    SELECT tip_doc, key_value, cod_cuc FROM (
        SELECT tip_doc, key_value, cod_cuc,
               row_number() OVER (PARTITION BY tip_doc, key_value
                                  ORDER BY fch_pricont DESC, cod_cuc ASC) AS rn
        FROM e_perm_aws.t_mst_ctaibk_rsk) x
    WHERE x.rn = 1
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       p.saldo_tc_ori,
       s.sbs_value,
       c.cod_cuc,
       CAST(CASE WHEN s.sbs_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_sbs,
       CAST(CASE WHEN c.cod_cuc   IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_cuc,
       p.codmes_mrm
FROM __T___10_po p
LEFT JOIN sbs s ON s.tip_doc = p.tip_doc AND s.key_value = p.id_value
LEFT JOIN cuc c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value""" % CAB("11_po_key"))

# ============================ 20 base en origen ============================
w(PROD, "01_staging", "20_rcc_base.sql", "20. RCC EN ORIGEN - VARIANTES M0 Y M2",
"""CREATE TABLE __T___20_rcc_base
%s
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           %s AS m02
    FROM __T___11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           sum(monto_cast) AS monto_cast,
           sum(sld_ref)    AS sld_ref,
           sum(sld_ree)    AS sld_ree,
           sum(sld_jud)    AS sld_jud
    FROM __T___05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.monto_cast > 0 THEN 1 END), 0) AS INTEGER) AS cast_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.monto_cast > 0 THEN 1 END), 0) AS INTEGER) AS cast_ori_m2,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_jud    > 0 THEN 1 END), 0) AS INTEGER) AS jud_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.sld_jud    > 0 THEN 1 END), 0) AS INTEGER) AS jud_ori_m2,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_ref    > 0 THEN 1 END), 0) AS INTEGER) AS ref_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.sld_ref    > 0 THEN 1 END), 0) AS INTEGER) AS ref_ori_m2,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_ree    > 0 THEN 1 END), 0) AS INTEGER) AS ree_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.sld_ree    > 0 THEN 1 END), 0) AS INTEGER) AS ree_ori_m2,
       CAST(coalesce(max(CASE WHEN e.codmes = p.codmes_mrm AND e.dm_tc      > 0 THEN 1 END), 0) AS INTEGER) AS malo_ori_m0,
       CAST(coalesce(max(CASE WHEN e.codmes = p.m02        AND e.dm_tc      > 0 THEN 1 END), 0) AS INTEGER) AS malo_ori_m2,
       p.codmes_mrm
FROM po p
LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
               AND c.codmes IN (p.codmes_mrm, p.m02)
LEFT JOIN __T___05_rcc_agg e ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value
               AND e.entidad = p.entidad AND e.codmes IN (p.codmes_mrm, p.m02)
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm""" % (CAB("20_rcc_base"), mes("codmes_mrm", -2)))

# ============================ 21 historicos ============================
w(PROD, "01_staging", "21_rcc_flags.sql", "21. HISTORICOS U6M U12M U24M",
"""CREATE TABLE __T___21_rcc_flags
%s
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           %s AS m02, %s AS m07, %s AS m13, %s AS m25
    FROM __T___11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           sum(monto_cast)     AS monto_cast,
           sum(sld_ref)        AS sld_ref,
           sum(sld_jud)        AS sld_jud,
           sum(sld_bank)       AS sld_bank,
           max(clasif_max)     AS clasif_max,
           max(flg_no_consumo) AS flg_no_consumo
    FROM __T___05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m13 AND p.m02 AND c.sld_bank   > 0 THEN 1 END), 0) AS INTEGER) AS banc_u12m,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.monto_cast > 0 THEN 1 END), 0) AS INTEGER) AS cast_u24m,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.sld_jud    > 0 THEN 1 END), 0) AS INTEGER) AS jud_u24m,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m07 AND p.m02 AND c.sld_ref    > 0 THEN 1 END), 0) AS INTEGER) AS ref_u6m,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02 AND c.clasif_max IN ('2','3','4') THEN 1 END), 0) AS INTEGER)    AS mayor_cpp,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.flg_no_consumo = 1 THEN 1 END), 0) AS INTEGER) AS ctrl_no_consumo,
       CAST(CASE WHEN count(c.codmes) = 0 THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_historia,
       p.codmes_mrm
FROM po p
LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
               AND c.codmes BETWEEN p.m25 AND p.m02
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm""" %
 (CAB("21_rcc_flags"), mes("codmes_mrm", -2), mes("codmes_mrm", -7), mes("codmes_mrm", -13), mes("codmes_mrm", -25)))

# ============================ 30 drivers ============================
w(PROD, "01_staging", "30_drivers.sql", "30. DRIVERS - TIPO DE INGRESO Y ARQUETIPO SALUD",
"""CREATE TABLE __T___30_drivers
%s
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value, %s AS m02
    FROM __T___11_po_key
),
cls AS (
    SELECT tip_doc, id_value, codmes, sit_lab, fuente, tipo_ingreso
    FROM (
        SELECT CAST(a.tip_doc AS VARCHAR)                                     AS tip_doc,
               substr(a.subject_id, 3)                                        AS id_value,
               CAST(a.periodo AS VARCHAR)                                     AS codmes,
               a.sit_lab,
               a.fuente,
               CASE WHEN a.sit_lab = 'DEPENDIENTE'
                     AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
                    WHEN a.sit_lab = 'DEPENDIENTE'
                     AND a.fuente     IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
                    WHEN a.sit_lab = 'MIXTO'                                                  THEN 'MIXTO'
                    ELSE 'INDEPENDIENTE' END                                  AS tipo_ingreso,
               row_number() OVER (
                   PARTITION BY substr(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
                   ORDER BY a.p_fecinformacion DESC, a.subject_id ASC)        AS rn
        FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
        WHERE CAST(a.numcarga AS INT) = 1
    ) r
    WHERE r.rn = 1
),
inca AS (
    SELECT b.tip_doc, b.key_value AS id_value, a.cod_mes,
           a.seg_arq_salud, a.region_12m_prio, a.var_cuali_far_rubrofrec_9m_v3,
           a.flg_cant_trx_rubro_hospitales_clinicas_pos_ult_12m_1             AS flg_hosp_12m
    FROM (
        SELECT party_id, cod_mes, seg_arq_salud, region_12m_prio,
               var_cuali_far_rubrofrec_9m_v3,
               flg_cant_trx_rubro_hospitales_clinicas_pos_ult_12m_1,
               row_number() OVER (PARTITION BY party_id, cod_mes
                                  ORDER BY load_date DESC) AS rn
        FROM e_perm_aws.t_inca_sa) a
    INNER JOIN (
        SELECT inter_party_id, tip_doc, key_value,
               row_number() OVER (PARTITION BY inter_party_id
                                  ORDER BY inter_load_date DESC, key_value ASC) AS rn
        FROM e_perm_aws.t_mst_inter_ibk_base_cliente) b
       ON b.inter_party_id = a.party_id AND b.rn = 1
    WHERE a.rn = 1
)
SELECT p.tip_doc,
       p.id_value,
       coalesce(c.tipo_ingreso, 'INDEPENDIENTE')                                       AS tipo_ingreso,
       CASE WHEN coalesce(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
            THEN 'DEP_VAL' ELSE 'NO_DEP_VAL' END                                       AS tipo_ingreso_dep,
       c.sit_lab                                                                       AS sit_lab_crudo,
       c.fuente                                                                        AS fuente_ingreso,
       i.seg_arq_salud,
       i.region_12m_prio,
       i.var_cuali_far_rubrofrec_9m_v3,
       i.flg_hosp_12m,
       CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                 AS falla_sin_tipo_ingreso,
       CAST(CASE WHEN i.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                 AS ctrl_inca_sin_dato,
       CAST(CASE WHEN c.fuente IN ('SUSALUD','INFERIDO_IND_MVP') THEN 1 ELSE 0 END AS INTEGER) AS ctrl_fuente_nueva,
       p.codmes_mrm
FROM po p
LEFT JOIN cls  c ON c.tip_doc = p.tip_doc AND c.id_value = p.id_value AND c.codmes  = p.codmes_mrm
LEFT JOIN inca i ON i.tip_doc = p.tip_doc AND i.id_value = p.id_value AND i.cod_mes = p.m02"""
 % (CAB("30_drivers"), mes("codmes_mrm", -2)))

# ============================ 40 pd_raw ============================
w(PROD, "01_staging", "40_pdraw.sql", "40. PD CRUDA DEL MODELO VCNBANK",
"""CREATE TABLE __T___40_pdraw
%s
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value FROM __T___11_po_key
)
SELECT p.tip_doc,
       p.id_value,
       TRY_CAST(s.prob_model         AS DOUBLE)                                        AS pd_raw,
       TRY_CAST(s.puntuacion         AS INTEGER)                                       AS puntuacion,
       TRY_CAST(s.prob_modelo_cal    AS DOUBLE)                                        AS pd_cal_vigente,
       TRY_CAST(s.puntuacion_cal     AS INTEGER)                                       AS puntuacion_cal_vigente,
       s.grupo_calibracion                                                             AS grupo_cal_vigente,
       s.tip_situacion_laboral                                                         AS sitlab_score,
       TRY_CAST(s.rat_expect_inflacion AS DOUBLE)                                      AS macro_inflacion,
       TRY_CAST(s.rat_tasa_desempleo   AS DOUBLE)                                      AS macro_desempleo,
       TRY_CAST(s.rat_tasa_desempleo_6 AS DOUBLE)                                      AS macro_desempleo_6,
       CAST(CASE WHEN s.key_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_score,
       p.codmes_mrm
FROM po p
LEFT JOIN e_perm_aws.scr_vcnbank_rsk s
       ON s.cod_tip_doc = p.tip_doc
      AND s.key_value   = p.id_value
      AND s.p_codmes    = p.codmes_mrm""" % CAB("40_pdraw"))

# ============================ 50 targets 1m..12m ============================
dm  = ",\n".join("       max(CASE WHEN e.codmes BETWEEN p.p01 AND %s THEN e.dm_tc END)%s AS max_dm_%02dm"
                 % (mes("p.codmes_mrm", n), " " * (34 - len(mes("p.codmes_mrm", n))), n) for n in range(1, 13))
du  = ",\n".join("       max(CASE WHEN c.codmes BETWEEN p.p01 AND %s AND c.duro = 1 THEN 1 ELSE 0 END)%s AS duro_%02dm"
                 % (mes("p.codmes_mrm", n), " " * (13 - len(mes("p.codmes_mrm", n)) + 21), n) for n in range(1, 13))
tg  = ",\n".join(
    "       CASE WHEN %s > '%s' THEN NULL\n"
    "            WHEN coalesce(max_dm_%02dm, 0) > %d OR coalesce(duro_%02dm, 0) = 1 THEN 1\n"
    "            ELSE 0 END%s AS target_%02dm"
    % (mes("codmes_mrm", n), MAXDATO, n, UMBRAL, n, " " * 26, n) for n in range(1, 13))

w(PROD, "01_staging", "50_targets.sql", "50. TARGETS 1M A 12M - ACUMULADOS Y CON MADUREZ POR HORIZONTE",
"""CREATE TABLE __T___50_targets
%s
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, %s AS p01
    FROM __T___11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           CASE WHEN coalesce(monto_cast,0) > 0 OR coalesce(sld_jud,0) > 0
                  OR coalesce(sld_ref,0)    > 0 OR coalesce(sld_ree,0) > 0
                THEN 1 ELSE 0 END                                                      AS duro
    FROM (
        SELECT codmes, tip_doc, key_value,
               sum(monto_cast) AS monto_cast, sum(sld_jud) AS sld_jud,
               sum(sld_ref)    AS sld_ref,    sum(sld_ree) AS sld_ree
        FROM __T___05_rcc_agg
        GROUP BY codmes, tip_doc, key_value) z
),
fut AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value, p.entidad,
           CAST(12 - count(DISTINCT e.codmes) AS INTEGER)                              AS missing_12,
%s,
%s
    FROM po p
    LEFT JOIN __T___05_rcc_agg e ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value
                                AND e.entidad = p.entidad
                                AND e.codmes BETWEEN p.p01 AND %s
    LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
                   AND c.codmes BETWEEN p.p01 AND %s
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, p.entidad
)
SELECT tip_doc,
       id_value,
       entidad,
       missing_12,
       max_dm_12m                                                                      AS max_dm_fut,
       CAST(coalesce(duro_12m, 0) AS INTEGER)                                          AS f_evento_fut,
       CAST(CASE WHEN %s > '%s' THEN 1 ELSE 0 END AS INTEGER)                          AS falla_madurez,
%s,
       codmes_mrm
FROM fut""" % (CAB("50_targets"), mes("codmes_mrm", 1), dm, du,
               mes("p.codmes_mrm", 12), mes("p.codmes_mrm", 12),
               mes("codmes_mrm", 12), MAXDATO, tg))

print("staging OK: %d tramos + 10, 11, 20, 21, 30, 40, 50" % len(tr))
