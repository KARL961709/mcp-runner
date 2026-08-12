# -*- coding: utf-8 -*-
"""Cadena TCNOBANK parte 2: gate, historia macro, exports, reset y QA."""
import io, os
P    = r"C:\Users\CARLOS\mcp-runner\proyectos\tcnobank"
PROD = os.path.join(P, "sql_prod")
VAL  = os.path.join(P, "sql_val_cal")
T    = "disc_model_owner.ds_adm_vcnbank_tc"
MAXDATO = "202606"

def w(root, sub, name, titulo, sql):
    d = os.path.join(root, sub) if sub else root
    if not os.path.isdir(d): os.makedirs(d)
    ban = "-- " + "=" * 76 + "\n-- " + titulo + "\n-- " + "=" * 76 + "\n"
    io.open(os.path.join(d, name), "w", encoding="ascii", newline="\n").write(
        ban + sql.strip().replace("__T__", T) + "\n")

def CAB(suf, part="codmes_mrm"):
    p = "    partitioned_by      = ARRAY['%s'],\n" % part if part else ""
    return ("WITH (\n    format              = 'PARQUET',\n    parquet_compression = 'SNAPPY',\n"
            + p + "    external_location   = '<S3_DATOS>/adm_vcnbank_tc_%s/'\n) AS" % suf)

def mes(a, k):
    return "date_format(date_add('month', %d, date_parse(%s, '%%Y%%m')), '%%Y%%m')" % (k, a)

FILTROS = ["f_edad_rango","f_edad_nomatch","f_banc_u12m","f_cast_ori","f_jud_ori","f_ref_ori",
           "f_ree_ori","f_malo_ori","f_cast_u24m","f_jud_u24m","f_ref_u6m","f_mayor_cpp",
           "f_gar_conv","f_fraude","f_entidades","f_swap_u12m","f_swap_p12m","f_repro_p12m"]
CASO2 = [f for f in FILTROS if f not in ("f_banc_u12m","f_entidades","f_edad_nomatch",
                                          "f_swap_p12m","f_repro_p12m")]
CASO2_MACRO = [f for f in CASO2 if f not in ("f_fraude","f_swap_u12m")]

# ============================ 60 filtros ============================
w(PROD, "02_gate", "60_filtros.sql", "60. FILTROS - UNA COLUMNA POR FILTRO, NUNCA NULL",
"""CREATE TABLE __T___60_filtros
%s
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, sbs_value, cod_cuc, saldo_tc_ori,
           falla_sin_sbs, falla_sin_cuc, %s AS m02, %s AS p12
    FROM __T___11_po_key
),
gar AS (
    SELECT p_codmes, sbs_value,
           max(CASE WHEN cons_salgarhip > 0 THEN 1 ELSE 0 END)                         AS f_gar,
           max(CASE WHEN cons_salprestnorevconv > 0 OR cons_salprestrevconv > 0
                      OR cons_salpresconvob    > 0 THEN 1 ELSE 0 END)                  AS f_conv
    FROM e_perm_aws.t_consolidado_rsk
    GROUP BY p_codmes, sbs_value
),
fra AS (
    SELECT tip_doc, key_value, min(p_codmes) AS p_codmes_min
    FROM e_perm_aws.t_mst_fraude_rsk
    GROUP BY tip_doc, key_value
),
fac AS (
    SELECT codunicocli, CAST(periodo AS VARCHAR) AS codmes,
           max(CASE WHEN facilidad = 'SWAP' THEN 1 ELSE 0 END)                         AS f_swap,
           max(CASE WHEN facilidad = 'REPROGRAMACION'
                     AND tipo_facilidad IN ('LLUVIAS','UNILATERAL_LLUVIAS','SOCIAL')
                    THEN 1 ELSE 0 END)                                                 AS f_repro
    FROM e_perm_aws.t_cob_facilidades_ejecutadas
    WHERE estado_facilidad = 'EJECUTADO'
    GROUP BY codunicocli, CAST(periodo AS VARCHAR)
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       p.saldo_tc_ori,
       CAST(coalesce(CASE WHEN r.fec_nacimiento IS NOT NULL
                           AND NOT (date_diff('year', CAST(r.fec_nacimiento AS DATE),
                                              CAST(date_parse(p.codmes_mrm || '01', '%%Y%%m%%d') AS DATE))
                                    BETWEEN 21 AND 75)
                          THEN 1 ELSE 0 END, 0) AS INTEGER)                            AS f_edad_rango,
       CAST(CASE WHEN r.key_value IS NULL OR r.fec_nacimiento IS NULL THEN 1 ELSE 0 END AS INTEGER) AS f_edad_nomatch,
       CAST(coalesce(h.banc_u12m,   0) AS INTEGER)                                     AS f_banc_u12m,
       CAST(coalesce(b.cast_ori_m2, 0) AS INTEGER)                                     AS f_cast_ori,
       CAST(coalesce(b.jud_ori_m2,  0) AS INTEGER)                                     AS f_jud_ori,
       CAST(coalesce(b.ref_ori_m2,  0) AS INTEGER)                                     AS f_ref_ori,
       CAST(coalesce(b.ree_ori_m2,  0) AS INTEGER)                                     AS f_ree_ori,
       CAST(coalesce(b.malo_ori_m2, 0) AS INTEGER)                                     AS f_malo_ori,
       CAST(coalesce(h.cast_u24m,   0) AS INTEGER)                                     AS f_cast_u24m,
       CAST(coalesce(h.jud_u24m,    0) AS INTEGER)                                     AS f_jud_u24m,
       CAST(coalesce(h.ref_u6m,     0) AS INTEGER)                                     AS f_ref_u6m,
       CAST(coalesce(h.mayor_cpp,   0) AS INTEGER)                                     AS f_mayor_cpp,
       CAST(coalesce(greatest(g.f_gar, g.f_conv), 0) AS INTEGER)                       AS f_gar_conv,
       CAST(coalesce(CASE WHEN fr.p_codmes_min <= p.m02 THEN 1 ELSE 0 END, 0) AS INTEGER) AS f_fraude,
       CAST(CASE WHEN p.entidad IN ('00001','00002','00004','00006','00142')
                 THEN 0 ELSE 1 END AS INTEGER)                                         AS f_entidades,
       CAST(coalesce(su.f_swap,  0) AS INTEGER)                                        AS f_swap_u12m,
       CAST(coalesce(sp.f_swap,  0) AS INTEGER)                                        AS f_swap_p12m,
       CAST(coalesce(sp.f_repro, 0) AS INTEGER)                                        AS f_repro_p12m,
       CAST(coalesce(b.cast_ori_m0, 0) AS INTEGER)                                     AS ctrl_cast_ori_m0,
       CAST(coalesce(b.jud_ori_m0,  0) AS INTEGER)                                     AS ctrl_jud_ori_m0,
       CAST(coalesce(b.ref_ori_m0,  0) AS INTEGER)                                     AS ctrl_ref_ori_m0,
       CAST(coalesce(b.ree_ori_m0,  0) AS INTEGER)                                     AS ctrl_ree_ori_m0,
       CAST(coalesce(b.malo_ori_m0, 0) AS INTEGER)                                     AS ctrl_malo_ori_m0,
       CAST(CASE WHEN p.codmes_mrm < '202106' THEN 1 ELSE 0 END AS INTEGER)            AS ctrl_sin_fraude,
       CAST(CASE WHEN p.codmes_mrm < '202201' THEN 1 ELSE 0 END AS INTEGER)            AS ctrl_sin_swap,
       CAST(coalesce(h.ctrl_no_consumo, 0) AS INTEGER)                                 AS ctrl_no_consumo,
       CAST(p.falla_sin_sbs AS INTEGER)                                                AS falla_sin_sbs,
       CAST(p.falla_sin_cuc AS INTEGER)                                                AS falla_sin_cuc,
       CAST(coalesce(h.falla_sin_historia, 1) AS INTEGER)                              AS falla_sin_historia,
       p.codmes_mrm
FROM po p
LEFT JOIN __T___20_rcc_base  b ON b.tip_doc = p.tip_doc AND b.id_value = p.id_value
                              AND b.entidad = p.entidad AND b.codmes_mrm = p.codmes_mrm
LEFT JOIN __T___21_rcc_flags h ON h.tip_doc = p.tip_doc AND h.id_value = p.id_value
                              AND h.entidad = p.entidad AND h.codmes_mrm = p.codmes_mrm
LEFT JOIN e_perm_aws.t_mst_reniec_rsk r ON r.tip_doc = p.tip_doc AND r.key_value = p.id_value
LEFT JOIN gar g  ON g.sbs_value = p.sbs_value AND g.p_codmes = p.m02
LEFT JOIN fra fr ON fr.tip_doc  = p.tip_doc   AND fr.key_value = p.id_value
LEFT JOIN fac su ON su.codunicocli = p.cod_cuc
                AND su.codmes BETWEEN %s AND %s
LEFT JOIN fac sp ON sp.codunicocli = p.cod_cuc
                AND sp.codmes BETWEEN %s AND p.p12"""
 % (CAB("60_filtros"), mes("codmes_mrm", -2), mes("codmes_mrm", 12),
    mes("p.codmes_mrm", -12), mes("p.codmes_mrm", -1), mes("p.codmes_mrm", 1)))

# ============================ 65 dedup ============================
w(PROD, "02_gate", "65_dedup.sql", "65. DEDUP - PRELACION CON ORDEN TOTAL DETERMINISTA",
"""CREATE TABLE __T___65_dedup
%s
SELECT tip_doc,
       id_value,
       entidad,
       CAST(row_number() OVER (PARTITION BY codmes_mrm, tip_doc, id_value
                               ORDER BY entidad ASC) AS INTEGER)                       AS prelacion_cod,
       CAST(row_number() OVER (PARTITION BY codmes_mrm, tip_doc, id_value
                               ORDER BY saldo_tc_ori DESC, entidad ASC) AS INTEGER)    AS prelacion_sld,
       codmes_mrm
FROM __T___60_filtros""" % CAB("65_dedup"))

# ============================ 70 cal ============================
def suma(cols): return " + ".join("f.%s" % c for c in cols)
w(PROD, "02_gate", "70_cal.sql", "70. ENSAMBLADO FINAL - TABLA DE CALIBRACION",
"""CREATE TABLE __T___cal
%s
SELECT f.tip_doc,
       f.id_value,
       f.entidad,
       d.prelacion_cod,
       d.prelacion_sld,
       f.saldo_tc_ori,
       %s,
       f.ctrl_cast_ori_m0, f.ctrl_jud_ori_m0, f.ctrl_ref_ori_m0, f.ctrl_ree_ori_m0, f.ctrl_malo_ori_m0,
       f.ctrl_sin_fraude, f.ctrl_sin_swap, f.ctrl_no_consumo,
       f.falla_sin_sbs, f.falla_sin_cuc, f.falla_sin_historia,
       t.missing_12, t.max_dm_fut, t.f_evento_fut, t.falla_madurez,
       %s,
       v.tipo_ingreso, v.tipo_ingreso_dep, v.sit_lab_crudo, v.fuente_ingreso,
       v.seg_arq_salud, v.region_12m_prio, v.var_cuali_far_rubrofrec_9m_v3, v.flg_hosp_12m,
       v.falla_sin_tipo_ingreso, v.ctrl_inca_sin_dato, v.ctrl_fuente_nueva,
       q.pd_raw, q.puntuacion, q.pd_cal_vigente, q.puntuacion_cal_vigente,
       q.grupo_cal_vigente, q.sitlab_score,
       q.macro_inflacion, q.macro_desempleo, q.macro_desempleo_6, q.falla_sin_score,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 99
                 WHEN %s = 0 THEN 1 ELSE 0 END AS INTEGER)                             AS flg_clean,
       CAST(CASE WHEN f.f_banc_u12m = 1 THEN 99
                 WHEN %s + f.f_entidades = 0 THEN 1 ELSE 0 END AS INTEGER)             AS flg_clean_sin_ent,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 99
                 WHEN %s = 0 THEN 1 ELSE 0 END AS INTEGER)                             AS flg_clean_macro,
       CAST(CASE WHEN f.f_banc_u12m = 1 OR f.f_entidades = 1 THEN 0
                 WHEN q.pd_raw IS NULL           THEN 0
                 WHEN f.f_edad_nomatch = 1       THEN 0
                 WHEN t.falla_madurez = 1        THEN 0
                 ELSE 1 END AS INTEGER)                                                AS flg_calib,
       f.codmes_mrm
FROM __T___60_filtros f
LEFT JOIN __T___65_dedup   d ON d.tip_doc = f.tip_doc AND d.id_value = f.id_value
                            AND d.entidad = f.entidad AND d.codmes_mrm = f.codmes_mrm
LEFT JOIN __T___50_targets t ON t.tip_doc = f.tip_doc AND t.id_value = f.id_value
                            AND t.entidad = f.entidad AND t.codmes_mrm = f.codmes_mrm
LEFT JOIN __T___30_drivers v ON v.tip_doc = f.tip_doc AND v.id_value = f.id_value
                            AND v.codmes_mrm = f.codmes_mrm
LEFT JOIN __T___40_pdraw   q ON q.tip_doc = f.tip_doc AND q.id_value = f.id_value
                            AND q.codmes_mrm = f.codmes_mrm"""
 % (CAB("cal"),
    ", ".join("f.%s" % c for c in FILTROS),
    ", ".join("t.target_%02dm" % n for n in range(1, 13)),
    suma(CASO2), suma(CASO2), suma(CASO2_MACRO)))

# ============================ 81 serie macro ============================
w(PROD, "02_gate", "81_macro_serie.sql", "81. SERIE MENSUAL PARA SELECCION DE VARIABLE MACRO",
"""CREATE TABLE __T___81_macro
%s
WITH m AS (
    SELECT CAST(cod_mes AS VARCHAR)                    AS codmes,
           TRY_CAST(rat_ipc              AS DOUBLE)    AS rat_ipc,
           TRY_CAST(rat_pbi              AS DOUBLE)    AS rat_pbi,
           TRY_CAST(rat_tasa_desempleo   AS DOUBLE)    AS rat_tasa_desempleo,
           TRY_CAST(rat_tasa_referencia  AS DOUBLE)    AS rat_tasa_referencia,
           TRY_CAST(rat_expect_inflacion AS DOUBLE)    AS rat_expect_inflacion,
           TRY_CAST(rat_term_intercambio AS DOUBLE)    AS rat_term_intercambio
    FROM (
        SELECT cod_mes, rat_ipc, rat_pbi, rat_tasa_desempleo, rat_tasa_referencia,
               rat_expect_inflacion, rat_term_intercambio,
               row_number() OVER (PARTITION BY cod_mes
                                  ORDER BY fec_proceso DESC) AS rn
        FROM e_perm_aws.t_fact_bpe_vars_macro) x
    WHERE x.rn = 1
),
s AS (
    SELECT codmes_mrm                                                                  AS codmes,
           count(*)                                                                    AS n_universo,
           sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)            AS n_clean,
           sum(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1 THEN 1 ELSE 0 END)      AS n_clean_macro,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN CAST(target_12m AS DOUBLE) END) AS rd_12m_clean,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN CAST(target_06m AS DOUBLE) END) AS rd_06m_clean,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN CAST(target_03m AS DOUBLE) END) AS rd_03m_clean,
           avg(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1 THEN CAST(target_12m AS DOUBLE) END) AS rd_12m_macro,
           avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN pd_raw END)              AS pd_raw_clean
    FROM __T___cal
    GROUP BY codmes_mrm
)
SELECT s.codmes, s.n_universo, s.n_clean, s.n_clean_macro,
       s.rd_12m_clean, s.rd_06m_clean, s.rd_03m_clean, s.rd_12m_macro, s.pd_raw_clean,
       m.rat_ipc, m.rat_pbi, m.rat_tasa_desempleo, m.rat_tasa_referencia,
       m.rat_expect_inflacion, m.rat_term_intercambio
FROM s
LEFT JOIN m ON m.codmes = s.codmes""" % CAB("81_macro", None))

# ============================ exports ============================
COLS = ("""       to_hex(md5(to_utf8(tip_doc || '|' || id_value || '|' || entidad)))              AS id_hash,
       entidad, prelacion_cod, prelacion_sld, saldo_tc_ori,
       %s,
       ctrl_cast_ori_m0, ctrl_jud_ori_m0, ctrl_ref_ori_m0, ctrl_ree_ori_m0, ctrl_malo_ori_m0,
       ctrl_sin_fraude, ctrl_sin_swap, ctrl_no_consumo, ctrl_inca_sin_dato, ctrl_fuente_nueva,
       falla_sin_sbs, falla_sin_cuc, falla_sin_historia, falla_sin_tipo_ingreso,
       falla_sin_score, falla_madurez,
       missing_12, max_dm_fut, f_evento_fut,
       %s,
       tipo_ingreso, tipo_ingreso_dep, sit_lab_crudo, fuente_ingreso,
       seg_arq_salud, region_12m_prio, var_cuali_far_rubrofrec_9m_v3, flg_hosp_12m,
       pd_raw, puntuacion, pd_cal_vigente, puntuacion_cal_vigente, grupo_cal_vigente, sitlab_score,
       macro_inflacion, macro_desempleo, macro_desempleo_6,
       flg_clean, flg_clean_sin_ent, flg_clean_macro, flg_calib,
       codmes_mrm"""
 % (", ".join(FILTROS), ", ".join("target_%02dm" % n for n in range(1, 13))))

for nm, suf, ttl, whr in [
    ("90_export_master", "px_master", "90. EXPORT MASTER", "1 = 1"),
    ("91_export_clean",  "px_clean",  "91. EXPORT CLEAN",  "flg_calib = 1 AND flg_clean = 1"),
    ("92_export_dirty",  "px_dirty",  "92. EXPORT DIRTY",  "flg_calib = 1"),
    ("93_export_macro",  "px_macro",  "93. EXPORT MACRO",  "flg_calib = 1 AND flg_clean_macro = 1")]:
    w(PROD, "02_gate", nm + ".sql", ttl,
      "CREATE TABLE __T___%s\n%s\nSELECT\n%s\nFROM __T___cal\nWHERE %s" % (suf, CAB(suf), COLS, whr))

# ============================ 00 reset ============================
TABLAS = ["05_rcc_agg","10_po","11_po_key","20_rcc_base","21_rcc_flags","30_drivers","40_pdraw",
          "50_targets","60_filtros","65_dedup","cal","81_macro",
          "px_master","px_clean","px_dirty","px_macro"]
for i, t in enumerate(TABLAS, 1):
    w(PROD, "00_reset", "r%03d_drop_%s.sql" % (i, t), "R%03d. DROP %s" % (i, t.upper()),
      "DROP TABLE IF EXISTS __T___%s" % t)

print("gate + exports + reset OK (%d drops)" % len(TABLAS))
