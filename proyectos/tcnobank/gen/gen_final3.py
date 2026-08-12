# -*- coding: utf-8 -*-
"""Cadena TCNOBANK parte 3: QA y LEEME."""
import io, os
P   = r"C:\Users\CARLOS\mcp-runner\proyectos\tcnobank"
VAL = os.path.join(P, "sql_val_cal")
T   = "disc_model_owner.ds_adm_vcnbank_tc"
MAXDATO = "202606"

def w(name, titulo, sql):
    if not os.path.isdir(VAL): os.makedirs(VAL)
    ban = "-- " + "=" * 76 + "\n-- " + titulo + "\n-- " + "=" * 76 + "\n"
    io.open(os.path.join(VAL, name), "w", encoding="ascii", newline="\n").write(
        ban + sql.strip().replace("__T__", T) + "\n")

FILTROS = ["f_edad_rango","f_edad_nomatch","f_banc_u12m","f_cast_ori","f_jud_ori","f_ref_ori",
           "f_ree_ori","f_malo_ori","f_cast_u24m","f_jud_u24m","f_ref_u6m","f_mayor_cpp",
           "f_gar_conv","f_fraude","f_entidades","f_swap_u12m","f_swap_p12m","f_repro_p12m"]
PASOS = ["05_rcc_agg","10_po","11_po_key","20_rcc_base","21_rcc_flags","30_drivers",
         "40_pdraw","50_targets","60_filtros","65_dedup","cal"]

# --- 00 cobertura por paso: la validacion agregada que ESTILO pide tras cada CREATE ---
w("00_cobertura_pasos.sql", "00. COBERTURA Y GRANO DE CADA PASO MATERIALIZADO",
"\nUNION ALL\n".join(
"""SELECT '%s' AS paso, count(*) AS n_filas, count(DISTINCT codmes%s) AS meses
FROM __T___%s""" % (p, "" if p == "05_rcc_agg" else "_mrm", p) for p in PASOS)
+ "\nORDER BY paso")

# --- 91 controles del target por codmes ---
mon = "\n".join(
"       sum(CASE WHEN target_%02dm > target_%02dm THEN 1 ELSE 0 END) +" % (n, n + 1)
for n in range(1, 12))
rng = "\n".join(
"       sum(CASE WHEN target_%02dm NOT IN (0,1) THEN 1 ELSE 0 END) +" % n for n in range(1, 13))
mad = "\n".join(
"""       sum(CASE WHEN %s > '%s' AND target_%02dm IS NOT NULL THEN 1 ELSE 0 END) +
       sum(CASE WHEN %s <= '%s' AND target_%02dm IS NULL     THEN 1 ELSE 0 END) +"""
% ("date_format(date_add('month', %d, date_parse(codmes_mrm, '%%Y%%m')), '%%Y%%m')" % n, MAXDATO, n,
   "date_format(date_add('month', %d, date_parse(codmes_mrm, '%%Y%%m')), '%%Y%%m')" % n, MAXDATO, n)
for n in range(1, 13))

w("91_qa_targets.sql", "91. CONTROLES DEL TARGET POR CODMES - RANGO MADUREZ MONOTONIA Y CROSS-CHECK",
"""SELECT codmes_mrm,
       count(*)                                                                        AS n_magnitud,
%s
       0                                                                               AS falla_rango,
%s
       0                                                                               AS falla_madurez,
%s
       0                                                                               AS falla_monotonia,
       sum(CASE WHEN max_dm_fut > 60 AND target_12m = 0 THEN 1 ELSE 0 END)             AS falla_mora_no_marcada,
       sum(CASE WHEN f_evento_fut = 1 AND target_12m = 0 THEN 1 ELSE 0 END)            AS falla_evento_no_marcado
FROM __T___cal
GROUP BY codmes_mrm
ORDER BY codmes_mrm""" % (rng, mad, mon))

w("92_qa_targets_global.sql", "92. CONTROLES DEL TARGET AGRUPADO - SIN MADUROS Y DEGENERADO",
"""SELECT h.horizonte,
       count(h.t)                                                                      AS n_maduros,
       sum(h.t)                                                                        AS n_malos,
       round(100.0 * avg(CAST(h.t AS DOUBLE)), 4)                                      AS bad_rate,
       CAST(CASE WHEN count(h.t) = 0 THEN 1 ELSE 0 END AS INTEGER)                     AS falla_sin_maduros,
       CAST(CASE WHEN avg(CAST(h.t AS DOUBLE)) IN (0.0, 1.0) THEN 1 ELSE 0 END AS INTEGER) AS falla_degenerado
FROM __T___cal c
CROSS JOIN UNNEST(
    ARRAY['01m','02m','03m','04m','05m','06m','07m','08m','09m','10m','11m','12m'],
    ARRAY[c.target_01m, c.target_02m, c.target_03m, c.target_04m, c.target_05m, c.target_06m,
          c.target_07m, c.target_08m, c.target_09m, c.target_10m, c.target_11m, c.target_12m])
     AS h (horizonte, t)
WHERE c.flg_calib = 1 AND c.flg_clean = 1
GROUP BY h.horizonte
ORDER BY h.horizonte""")

w("90_qa_reconcilia.sql", "90. RECONCILIACION DE FLG_CLEAN Y DOMINIO DE FLG_CALIB",
"""SELECT 'G1' AS gate, chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM (
    SELECT 'meses donde 99 + 1 + 0 no suma el universo' AS chk,
           sum(CASE WHEN n_tot <> n99 + n1 + n0 THEN 1 ELSE 0 END) AS n_viol,
           sum(n_tot) AS n_magnitud
    FROM (SELECT codmes_mrm, count(*) AS n_tot,
                 sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END) AS n99,
                 sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END) AS n1,
                 sum(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END) AS n0
          FROM __T___cal GROUP BY codmes_mrm) x
    UNION ALL
    SELECT 'flg_clean fuera de 99, 1 y 0',
           sum(CASE WHEN flg_clean NOT IN (99,1,0) OR flg_clean IS NULL THEN 1 ELSE 0 END),
           count(*) FROM __T___cal
    UNION ALL
    SELECT 'flg_calib fuera de 0 y 1',
           sum(CASE WHEN flg_calib NOT IN (0,1) OR flg_calib IS NULL THEN 1 ELSE 0 END),
           count(*) FROM __T___cal
    UNION ALL
    SELECT 'llaves duplicadas en el maestro',
           (SELECT count(*) FROM (SELECT codmes_mrm, tip_doc, id_value, entidad
                                  FROM __T___cal GROUP BY 1,2,3,4 HAVING count(*) > 1) d),
           count(*) FROM __T___cal
    UNION ALL
    SELECT 'clientes con mas de una prelacion_cod = 1',
           (SELECT count(*) FROM (SELECT codmes_mrm, tip_doc, id_value FROM __T___cal
                                  WHERE prelacion_cod = 1 GROUP BY 1,2,3 HAVING count(*) > 1) p),
           count(*) FROM __T___cal WHERE prelacion_cod = 1
) y""")

w("93_qa_filtros_dominio.sql", "93. DOMINIO DE CADA FILTRO - NINGUNO PUEDE SER NULL",
"""SELECT f.filtro                                                                     AS chk,
       sum(CASE WHEN f.v IS NULL OR f.v NOT IN (0,1) THEN 1 ELSE 0 END)               AS n_viol,
       count(*)                                                                       AS n_magnitud,
       CASE WHEN sum(CASE WHEN f.v IS NULL OR f.v NOT IN (0,1) THEN 1 ELSE 0 END) = 0
            THEN 'PASS' ELSE 'FAIL' END                                               AS veredicto
FROM __T___cal c
CROSS JOIN UNNEST(
    ARRAY[%s],
    ARRAY[%s]) AS f (filtro, v)
GROUP BY f.filtro
ORDER BY n_viol DESC, f.filtro"""
% (", ".join("'%s'" % x for x in FILTROS), ", ".join("c.%s" % x for x in FILTROS)))

w("94_qa_funnel.sql", "94. FUNNEL AISLADO CON BAD-RATE POR FILTRO",
"""SELECT f.filtro,
       sum(f.dispara)                                                                  AS n_aislado,
       round(100.0 * sum(f.dispara) / count(*), 4)                                     AS pct_universo,
       sum(CASE WHEN f.dispara = 1 AND c.target_12m IS NOT NULL THEN 1 ELSE 0 END)     AS n_evaluable,
       sum(CASE WHEN f.dispara = 1 THEN coalesce(c.target_12m, 0) ELSE 0 END)          AS n_malo,
       round(100.0 * sum(CASE WHEN f.dispara = 1 THEN coalesce(c.target_12m, 0) ELSE 0 END)
             / nullif(sum(CASE WHEN f.dispara = 1 AND c.target_12m IS NOT NULL THEN 1 ELSE 0 END), 0), 4)
                                                                                       AS bad_rate
FROM __T___cal c
CROSS JOIN UNNEST(
    ARRAY[%s],
    ARRAY[%s]) AS f (filtro, dispara)
GROUP BY f.filtro
ORDER BY n_aislado DESC"""
% (", ".join("'%s'" % x for x in FILTROS), ", ".join("c.%s" % x for x in FILTROS)))

w("95_qa_serie_mensual.sql", "95. SERIE MENSUAL - POBLACION TASAS Y PD CRUDA",
"""SELECT codmes_mrm,
       count(*)                                                                        AS n_universo,
       sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                                 AS n_scope,
       sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                                 AS n_clean,
       sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)                AS n_calib,
       sum(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1 THEN 1 ELSE 0 END)          AS n_calib_macro,
       sum(CASE WHEN flg_calib = 1 AND flg_clean_sin_ent = 1 THEN 1 ELSE 0 END)        AS n_calib_sin_ent,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_01m AS DOUBLE) END), 4)                 AS rd_01m,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_03m AS DOUBLE) END), 4)                 AS rd_03m,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_06m AS DOUBLE) END), 4)                 AS rd_06m,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m AS DOUBLE) END), 4)                 AS rd_12m,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN pd_raw END), 4) AS pd_raw_media,
       sum(falla_madurez)                                                              AS n_inmaduro
FROM __T___cal
GROUP BY codmes_mrm
ORDER BY codmes_mrm""")

w("96_qa_lookahead.sql", "96. LINAJE - NINGUN FILTRO DISPARA ANTES DE QUE SU FUENTE EXISTA",
"""SELECT 'G6' AS gate, chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM (
    SELECT 'fraude que dispara antes de 202106' AS chk,
           sum(CASE WHEN ctrl_sin_fraude = 1 AND f_fraude = 1 THEN 1 ELSE 0 END) AS n_viol,
           sum(ctrl_sin_fraude) AS n_magnitud FROM __T___cal
    UNION ALL
    SELECT 'swap u12m que dispara antes de 202201',
           sum(CASE WHEN ctrl_sin_swap = 1 AND f_swap_u12m = 1 THEN 1 ELSE 0 END),
           sum(ctrl_sin_swap) FROM __T___cal
    UNION ALL
    SELECT 'inca con dato antes de 202305',
           sum(CASE WHEN codmes_mrm < '202305' AND ctrl_inca_sin_dato = 0 THEN 1 ELSE 0 END),
           sum(CASE WHEN codmes_mrm < '202305' THEN 1 ELSE 0 END) FROM __T___cal
    UNION ALL
    SELECT 'altas fuera de la ventana 201902 a 202605',
           sum(CASE WHEN codmes_mrm < '201902' OR codmes_mrm > '202605' THEN 1 ELSE 0 END),
           count(*) FROM __T___cal
) y""")

w("97_qa_drivers.sql", "97. COBERTURA DE DRIVERS Y LLAVES POR ANIO",
"""SELECT substr(codmes_mrm, 1, 4)                                                      AS anio,
       count(*)                                                                        AS n,
       round(100.0 * avg(CAST(falla_sin_tipo_ingreso AS DOUBLE)), 3)                   AS pct_sin_ingreso,
       round(100.0 * avg(CAST(ctrl_inca_sin_dato     AS DOUBLE)), 3)                   AS pct_sin_inca,
       round(100.0 * avg(CAST(ctrl_fuente_nueva      AS DOUBLE)), 3)                   AS pct_fuente_nueva,
       round(100.0 * avg(CAST(falla_sin_score        AS DOUBLE)), 3)                   AS pct_sin_score,
       round(100.0 * avg(CAST(falla_sin_sbs          AS DOUBLE)), 3)                   AS pct_sin_sbs,
       round(100.0 * avg(CAST(falla_sin_cuc          AS DOUBLE)), 3)                   AS pct_sin_cuc,
       round(100.0 * avg(CAST(f_edad_nomatch         AS DOUBLE)), 3)                   AS pct_sin_reniec,
       count(DISTINCT tipo_ingreso)                                                    AS n_tipo_ingreso,
       count(DISTINCT seg_arq_salud)                                                   AS n_seg_salud,
       round(100.0 * avg(CASE WHEN tipo_ingreso = 'DEPENDIENTE' THEN 1.0 ELSE 0.0 END), 3) AS pct_dep_val
FROM __T___cal
GROUP BY substr(codmes_mrm, 1, 4)
ORDER BY anio""")

w("98_qa_delta_reanclaje.sql", "98. DELTA DEL REANCLAJE M0 CONTRA M2 EN LOS CINCO FILTROS DE ORIGEN",
"""SELECT f.filtro,
       sum(f.m0)                                                                       AS n_m0,
       sum(f.m2)                                                                       AS n_m2,
       sum(f.m0) - sum(f.m2)                                                           AS delta,
       round(100.0 * (sum(f.m0) - sum(f.m2)) / nullif(sum(f.m0), 0), 3)                AS pct_pierde_reanclaje,
       count(*)                                                                        AS n_magnitud
FROM __T___cal c
CROSS JOIN UNNEST(
    ARRAY['cast_ori','jud_ori','ref_ori','ree_ori','malo_ori'],
    ARRAY[c.ctrl_cast_ori_m0, c.ctrl_jud_ori_m0, c.ctrl_ref_ori_m0, c.ctrl_ree_ori_m0, c.ctrl_malo_ori_m0],
    ARRAY[c.f_cast_ori, c.f_jud_ori, c.f_ref_ori, c.f_ree_ori, c.f_malo_ori])
     AS f (filtro, m0, m2)
GROUP BY f.filtro
ORDER BY f.filtro""")

w("99_qa_agg_cobertura.sql", "99. COBERTURA DE LA CAPA AGREGADA - SIN HUECO NI SOLAPE",
"""SELECT 'G9' AS gate, chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM (
    SELECT 'meses esperados sin filas en la capa agregada' AS chk,
           114 - count(DISTINCT codmes) AS n_viol,
           count(DISTINCT codmes) AS n_magnitud
    FROM __T___05_rcc_agg WHERE codmes BETWEEN '201701' AND '202606'
    UNION ALL
    SELECT 'llaves duplicadas dentro de un mes',
           (SELECT count(*) FROM (SELECT codmes, tip_doc, key_value, entidad
                                  FROM __T___05_rcc_agg GROUP BY 1,2,3,4 HAVING count(*) > 1) d),
           count(*) FROM __T___05_rcc_agg
) y""")

print("QA: 11 controles")
