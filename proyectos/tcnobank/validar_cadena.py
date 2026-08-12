# -*- coding: utf-8 -*-
"""Validacion quirurgica de la cadena TCNOBANK. Falla si cualquier invariante se rompe."""
import io, os, re, glob, sys

P    = r"C:\Users\CARLOS\mcp-runner\proyectos\tcnobank"
PROD = os.path.join(P, "sql_prod")
QA   = os.path.join(P, "sql_qa")
T    = "disc_model_owner.ds_adm_tcnb"

fallos = []
def bad(f, m): fallos.append("%-34s %s" % (os.path.basename(f), m))

files = sorted(glob.glob(os.path.join(PROD, "**", "*.sql"), recursive=True) +
               glob.glob(os.path.join(QA, "*.sql")))

# ---------- 1. invariantes de byte y de forma ----------
for f in files:
    raw = io.open(f, "rb").read()
    if raw[:3] == b"\xef\xbb\xbf": bad(f, "BOM")
    try: t = raw.decode("ascii")
    except UnicodeDecodeError as e:
        bad(f, "no-ASCII en byte %d" % e.start); t = raw.decode("utf-8", "replace")
    if ";" in t: bad(f, "punto y coma")
    if t.count("(") != t.count(")"): bad(f, "parentesis %d/%d" % (t.count("("), t.count(")")))
    if t.count("'") % 2:  bad(f, "comillas simples impares")
    if t.count("[") != t.count("]"): bad(f, "corchetes")
    if not t.lstrip().startswith("--"): bad(f, "sin cabecera")
    u = t.upper()
    n = u.count("CREATE TABLE") + u.count("INSERT INTO") + u.count("DROP TABLE")
    if "sql_prod" in f and n != 1: bad(f, "%d statements DDL (debe ser 1)" % n)
    if "sql_qa" in f and n != 0:   bad(f, "la QA escribe")
    if "<S3_DATOS>" in t and "CREATE TABLE" not in u: bad(f, "location sin CREATE")

# ---------- 2. mapa fuente x mes (R9) ----------
for f in glob.glob(os.path.join(PROD, "01_staging", "05_rcc_agg_*.sql")):
    t = io.open(f, encoding="ascii").read()
    m = re.search(r"BETWEEN '(\d{6})' AND '(\d{6})'", t)
    if not m: bad(f, "sin ventana"); continue
    lo, hi = m.groups()
    esp = "d_perm_aws" if hi <= "201812" else "e_perm_aws"
    if "FROM %s.t_fact_report_rcc_rsk" % esp not in t:
        bad(f, "fuente != mapa R9 (%s-%s espera %s)" % (lo, hi, esp))
    if lo <= "201812" < hi: bad(f, "el tramo cruza la frontera 201812/201901")

# cobertura de los tramos: sin hueco ni solape sobre 201701-202606
vent = []
for f in sorted(glob.glob(os.path.join(PROD, "01_staging", "05_rcc_agg_*.sql"))):
    t = io.open(f, encoding="ascii").read()
    m = re.search(r"BETWEEN '(\d{6})' AND '(\d{6})'", t)
    if m: vent.append(m.groups())
def sig(c):
    y, mm = int(c[:4]), int(c[4:]) + 1
    return "%04d%02d" % (y + 1, 1) if mm == 13 else "%04d%02d" % (y, mm)
vent.sort()
if vent:
    if vent[0][0] != "201701": fallos.append("tramos: arrancan en %s, se espera 201701" % vent[0][0])
    if vent[-1][1] != "202606": fallos.append("tramos: terminan en %s, se espera 202606" % vent[-1][1])
    for a, b in zip(vent, vent[1:]):
        if sig(a[1]) != b[0]:
            fallos.append("tramos: hueco o solape entre %s y %s" % (a[1], b[0]))

# ---------- 3. un CREATE por tabla, y el orden del INSERT ----------
crea, ins = {}, {}
for f in files:
    if "sql_prod" not in f: continue
    t = io.open(f, encoding="ascii").read()
    for tb in re.findall(r"CREATE TABLE (\S+)", t): crea.setdefault(tb, []).append(f)
    for tb in re.findall(r"INSERT INTO (\S+)",  t): ins.setdefault(tb, []).append(f)
for tb, fs in crea.items():
    if len(fs) > 1: fallos.append("%s tiene %d CREATE" % (tb, len(fs)))
for tb in ins:
    if tb not in crea: fallos.append("%s recibe INSERT sin CREATE" % tb)

# ---------- 4. linaje: toda tabla leida existe y se crea ANTES ----------
ORDEN = ["05_rcc_agg", "10_po", "20_hist", "30_fut", "35_target", "40_drivers", "50_pd",
         "60_filtros", "cal", "px_master", "px_clean", "px_dirty", "px_macro"]
pos = {"%s_%s" % (T, k): i for i, k in enumerate(ORDEN)}
for f in files:
    if "00_reset" in f: continue
    t = io.open(f, encoding="ascii").read()
    yo = re.search(r"(?:CREATE TABLE|INSERT INTO) (\S+)", t)
    yo = pos.get(yo.group(1), 99) if yo else 99
    for leida in set(re.findall(r"(?:FROM|JOIN)\s+(disc_model_owner\.[a-z0-9_]+)", t)):
        if leida not in pos: bad(f, "lee tabla desconocida %s" % leida); continue
        if "sql_prod" in f and pos[leida] >= yo and yo != 99:
            bad(f, "lee %s que se crea despues" % leida.split("_")[-1])

# ---------- 5. la QA cubre lo que el build escribe ----------
qat = set()
for f in glob.glob(os.path.join(QA, "*.sql")):
    qat |= set(re.findall(r"disc_model_owner\.([a-z0-9_]+)", io.open(f, encoding="ascii").read()))
esc = set("ds_adm_tcnb_%s" % k for k in ORDEN)
if not qat: fallos.append("la QA no lee ninguna tabla del build")
for t_ in qat - esc: fallos.append("la QA lee %s que el build no escribe" % t_)

# ---------- 6. toda QA reporta magnitud ----------
for f in glob.glob(os.path.join(QA, "*.sql")):
    t = io.open(f, encoding="ascii").read().lower()
    if "veredicto" in t and "n_magnitud" not in t:
        bad(f, "veredicto sin magnitud")
    if "count(" not in t and "sum(" not in t:
        bad(f, "no reporta ningun conteo")

# ---------- 7. UNNEST multi-array alineado ----------
for f in files:
    t = io.open(f, encoding="ascii").read()
    for blk in re.findall(r"UNNEST\(\s*(ARRAY\[.*?\])\s*\)\s*\n?\s*AS", t, re.S):
        arrs = re.findall(r"ARRAY\[(.*?)\]", blk, re.S)
        largos = [len([x for x in a.split(",") if x.strip()]) for a in arrs]
        if len(set(largos)) > 1: bad(f, "UNNEST desalineado %s" % largos)

# ---------- 8. sin identidad en los exports ----------
for f in glob.glob(os.path.join(PROD, "02_gate", "9*_export_*.sql")):
    t = io.open(f, encoding="ascii").read()
    cols = t.split("FROM")[0]
    for prohibida in ("id_value,", "tip_doc,", "key_value,"):
        if prohibida in cols: bad(f, "el export saca identidad: %s" % prohibida.strip(","))

print("archivos revisados : %d  (%d build, %d QA)" %
      (len(files), len(glob.glob(os.path.join(PROD, "**", "*.sql"), recursive=True)),
       len(glob.glob(os.path.join(QA, "*.sql")))))
print("tramos de la capa  : %d, de %s a %s, contiguos" % (len(vent), vent[0][0], vent[-1][1]) if vent else "")
print("tablas del build   : %d" % len(crea))
print("")
if fallos:
    print("FALLOS (%d):" % len(fallos))
    for x in fallos: print("  " + x)
    sys.exit(1)
print("SIN FALLOS - los 8 invariantes pasan")
