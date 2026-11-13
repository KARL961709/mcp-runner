"""Prueba autonoma del paquete de referencia. Requiere: python 3.10+, numpy, pandas, scipy, pyarrow.
Uso (desde la raiz del paquete):  python pruebas/probar_todo.py
Cada chequeo imprime OK / MAL. Sale con codigo 1 si alguno falla.

P1 estructuras (DDL = ds = scr = tabla de parametros)
P2 pkl: se arma desde JSON, pasa sus controles y no lleva codigo propio
P3 job real (inference.py) sobre el ds de referencia = scr esperado, bit a bit (REE y VC)
P4 la referencia del inference.sql reproduce la x del mes y la x congelada del ds
P5 tabla de parametros: vigencia por modelo, freeze nuevo, correccion, trazabilidad, controles
P6 Denton: pesos = solucion exacta; mezcla de fuentes en la x del VC (k = 0, 1, 2)
P7 el job se detiene sin escribir ante errores
P8 recalibrar = pkl nuevo: cambia solo lo recalibrado
"""
import copy
import os
import pickle
import pickletools
import shutil
import subprocess
import sys
import tempfile

import numpy as np
import pandas as pd

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(RAIZ, "mlops", "scripts")
for p in (SCRIPTS, os.path.join(RAIZ, "referencia"), os.path.join(RAIZ, "pkl"), os.path.join(RAIZ, "denton")):
    sys.path.insert(0, p)
import armar_pkl as AP  # noqa: E402
import generar_pesos as GP  # noqa: E402
import sql_referencia as R  # noqa: E402
from utils import calculo as C  # noqa: E402

res = []


def chk(nombre, ok, det=""):
    res.append(bool(ok))
    print(f"  {'OK ' if ok else 'MAL'} {nombre:<72} {det}")


def igual_df(a, b):
    if list(a.columns) != list(b.columns) or len(a) != len(b):
        return False, "columnas o filas distintas"
    malos = []
    for c in a.columns:
        x, y = a[c].reset_index(drop=True), b[c].reset_index(drop=True)
        if pd.api.types.is_float_dtype(x) or pd.api.types.is_float_dtype(y):
            xa, ya = x.astype("float64").to_numpy(), y.astype("float64").to_numpy()
            if not ((xa == ya) | (np.isnan(xa) & np.isnan(ya))).all():
                malos.append(c)
        elif not (x.astype(str).to_numpy() == y.astype(str).to_numpy()).all():
            malos.append(c)
    return not malos, str(malos[:4])


def ddl_columnas(nombre):
    lineas = open(os.path.join(RAIZ, "ddl", nombre), encoding="utf-8").read().splitlines()
    i0 = next(i for i, l in enumerate(lineas) if l.startswith("CREATE"))
    i1 = next(i for i, l in enumerate(lineas) if l.strip() == ")")
    cols = [l.split()[0] for l in lineas[i0 + 1:i1]]
    part = next((l for l in lineas if l.startswith("PARTITIONED BY")), None)
    if part:
        cols += [p.split()[0] for p in part[part.index("(") + 1: part.rindex(")")].split(",")]
    return cols


def correr_job(modelo, ds, obj, carpeta):
    for c in ("data", "models", "results"):
        os.makedirs(os.path.join(carpeta, c), exist_ok=True)
    ds.to_parquet(os.path.join(carpeta, "data", "ds.parquet"), index=False)
    destino = os.path.join(carpeta, "models", "objeto_calibracion.pkl")
    if os.path.exists(destino):
        os.remove(destino)
    if obj is not None:
        with open(destino, "wb") as f:
            pickle.dump(obj, f)
    for f in os.listdir(os.path.join(carpeta, "results")):
        os.remove(os.path.join(carpeta, "results", f))
    env = dict(os.environ, DIR_DATA=os.path.join(carpeta, "data"), DIR_MODELS=os.path.join(carpeta, "models"),
               DIR_RESULTS=os.path.join(carpeta, "results"), PYTHONIOENCODING="utf-8")
    t = ds.cod_mes.iloc[0]
    r = subprocess.run([sys.executable, "inference.py", "--model", modelo, "--table-score", f"scr_cal_{modelo}_rsk", "--partition", t],
                       cwd=SCRIPTS, env=env, capture_output=True, text=True)
    out = os.path.join(carpeta, "results", f"scr_cal_{modelo}_rsk_{t}.parquet")
    return r, (pd.read_parquet(out) if os.path.exists(out) else None)


TMP = tempfile.mkdtemp(prefix="cal_ref_")
REF = os.path.join(RAIZ, "referencia")
PAR = pd.read_csv(os.path.join(REF, "t_cal_parametros_rsk.csv"), sep=";", dtype=str)
PAR["nro_carga"] = PAR.nro_carga.astype(int)
IPC = {r.cod_mes: float(r.porc_ipc) for r in pd.read_csv(os.path.join(REF, "porc_ipc_bcrp.csv"), sep=";", dtype=str).itertuples()}
SPEC = {"cppibkren": "spec_cppibkren_201801_v1.json", "vcadmbnk": "spec_vcadmbnk_202508_v4.json"}
OBJ = {m: AP.armar(os.path.join(RAIZ, "pkl", s)) for m, s in SPEC.items()}
DS = {m: pd.read_parquet(os.path.join(REF, f"ds_{m}_202612.parquet")) for m in SPEC}
DS09 = {m: pd.read_parquet(os.path.join(REF, f"ds_{m}_202609.parquet")) for m in SPEC}
ESP = {m: pd.read_parquet(os.path.join(REF, f"scr_cal_{m}_202612_esperado.parquet")) for m in SPEC}

print("P1. Estructuras")
chk("DDL t_cal_parametros_rsk = 6 campos de la referencia", ddl_columnas("01_t_cal_parametros_rsk.sql") == R.COL_PAR, str(ddl_columnas("01_t_cal_parametros_rsk.sql")))
chk("DDL t_cal_<modelo>_rsk = columnas del ds (37)", ddl_columnas("02_t_cal_modelo_rsk.sql") == R.COL_DS and all(list(d.columns) == R.COL_DS for d in DS.values()))
chk("DDL scr_cal (REE, 1 producto) = columnas del scr esperado (25)", ddl_columnas("03_scr_cal_cppibkren_rsk.sql") == list(ESP["cppibkren"].columns) == C.columnas_scr(OBJ["cppibkren"]))
chk("scr VC (4 productos) = 6 + 8 x 4 + id_calibracion + 8 extras + 2 = 49", len(C.columnas_scr(OBJ["vcadmbnk"])) == 49 == ESP["vcadmbnk"].shape[1])
chk("DDL t_mst_denton_pesos_rsk = columnas del CSV de pesos",
    ddl_columnas("04_t_mst_denton_pesos_rsk.sql") == list(pd.read_csv(os.path.join(RAIZ, "denton", "t_mst_denton_pesos_rsk.csv"), sep=";", nrows=0).columns))

print("\nP2. pkl de parametros")
specs = sorted(f for f in os.listdir(os.path.join(RAIZ, "pkl")) if f.startswith("spec_"))
objs = [AP.armar(os.path.join(RAIZ, "pkl", s)) for s in specs]
chk(f"{len(objs)} pkl armados desde JSON pasan sus controles", all(not C.validar(o) for o in objs), str([o.id_calibracion for o in objs]))
globs = {str(a) for op, a, _ in pickletools.genops(pickle.dumps(OBJ["vcadmbnk"])) if op.name in ("GLOBAL", "STACK_GLOBAL", "SHORT_BINUNICODE")}
chk("pkl solo datos: no referencia codigo propio (utils.*)", not any(g.startswith("utils") for g in globs))

print("\nP3. Job real = scr esperado (bit a bit)")
for m in SPEC:
    r, scr = correr_job(m, DS[m], OBJ[m], os.path.join(TMP, m))
    ok, det = igual_df(scr, ESP[m]) if scr is not None else (False, (r.stdout + r.stderr)[-200:])
    chk(f"{m}: {len(DS[m])} clientes, {ESP[m].shape[1]} columnas", ok, det)

print("\nP4. Referencia del inference.sql = ds")
for m in SPEC:
    ds = R.armar_ds(m, "202612", DS[m], IPC, {}, PAR, {"202609": DS09[m]}, "2026-12-15 08:00:00")
    chk(f"{m}: x del mes y x congelada identicas al ds de referencia",
        (ds.var_macro_01 == DS[m].var_macro_01).all() and (ds.var_macro_02 == DS[m].var_macro_02).all(),
        f"x {ds.var_macro_01.iloc[0]!r} | x_freeze {ds.var_macro_02.iloc[0]!r}")

print("\nP5. Tabla de parametros (todos los modelos juntos)")
rr = np.random.default_rng(7)
MESES = [R.cm(i) for i in range(R.mi("202501"), R.mi("202701"))]
filas = []
for j in range(40):
    for p in sorted(rr.choice(MESES, size=rr.integers(1, 6), replace=False)):
        for nro in range(1, rr.integers(1, 4) + 1):
            filas.append({"modelo": f"modelo_{j:02d}", "parametro": "cod_mes_freeze", "valor": str(rr.choice(MESES)), "nro_carga": nro,
                          "ts_carga": f"{p[:4]}-{p[4:]}-0{nro} 10:00:00", "p_codmes": p})
G = pd.DataFrame(filas)[R.COL_PAR]


def oraculo(par, mod, t):
    r = [f for f in par.itertuples() if f.modelo == mod and f.p_codmes <= t]
    if not r:
        return None
    pm = max(f.p_codmes for f in r)
    return max((f for f in r if f.p_codmes == pm), key=lambda f: f.nro_carga).valor


def vig(par, mod, t, ts=None):
    try:
        return R.vigente(par, mod, t, ts)["cod_mes_freeze"]
    except ValueError:
        return None


casos = [(m, t) for m in G.modelo.unique() for t in MESES]
chk(f"Vigencia de {G.modelo.nunique()} modelos x {len(MESES)} meses = oraculo independiente", all(vig(G, m, t) == oraculo(G, m, t) for m, t in casos))
antes = {k: vig(G, *k) for k in casos}
G2 = pd.concat([G, pd.DataFrame([{"modelo": "modelo_07", "parametro": "cod_mes_freeze", "valor": "202611", "nro_carga": 9,
                                  "ts_carga": "2026-12-10 09:00:00", "p_codmes": "202601"}])], ignore_index=True)
chk("Carga nueva de un modelo no mueve a ningun otro", all(m == "modelo_07" for m, t in casos if vig(G2, m, t) != antes[(m, t)]))
P2 = pd.concat([PAR, pd.DataFrame([{"modelo": "cppibkren", "parametro": "cod_mes_freeze", "valor": "202609", "nro_carga": 1,
                                    "ts_carga": "2026-12-10 09:00:00", "p_codmes": "202612"},
                                   {"modelo": "cppibkren", "parametro": "cod_mes_freeze", "valor": "202612", "nro_carga": 2,
                                    "ts_carga": "2026-12-20 09:00:00", "p_codmes": "202612"}])], ignore_index=True)
chk("Correccion nro_carga 2 manda; con ts_carga de una corrida previa se recupera la carga 1",
    vig(P2, "cppibkren", "202612") == "202612" and vig(P2, "cppibkren", "202612", "2026-12-15 08:00:00") == "202609")
chk("VC no cambia por cargas del REE", vig(P2, "vcadmbnk", "202612") == "202609")
malo = G.copy()
malo.loc[malo.index[0], "valor"] = "202613"
chk("Controles rechazan llave repetida y mes invalido",
    any("LLAVE" in e for e in R.validar_parametros(pd.concat([G, G.iloc[[0]]]))) and any("VALOR" in e for e in R.validar_parametros(malo))
    and not R.validar_parametros(G))
try:
    R.armar_ds("cppibkren", "202612", DS["cppibkren"].head(5), IPC, {}, P2.assign(valor=P2.valor.replace("202612", "202512")), {}, "2026-12-30 00:00:00")
    chk("Freeze en un mes sin ds -> se detiene", False)
except ValueError as e:
    chk("Freeze en un mes sin ds -> se detiene", "no existe el ds" in str(e), str(e))

print("\nP6. Denton y mezcla de fuentes")
peor, smin, smax = GP.autoprueba(R.pesos_denton())
chk("Pesos del CSV = Denton resuelto directo (2 variantes x 3 fases x k=1,2)", peor < 1e-10 and abs(smin - 1) < 1e-10 and abs(smax - 1) < 1e-10, f"dif max {peor:.1e}")
apoyo_sint = {R.cm(i): 3.0 + 0.4 * np.sin(i / 2.0) for i in range(R.mi("202503"), R.mi("202812"), 3)}
v12 = R.var12m(IPC)
peor = 0.0
for ult in ("202603", "202604", "202605", "202606", "202607", "202608", "202609"):
    ipc_cortado = {c: v for c, v in IPC.items() if c <= ult}
    pos = R.mi(ult) % 3 + 1
    fase = pos % 3
    e0 = 3 - fase if fase else 3
    obs = [v12[R.cm(R.mi(ult) - j)] for j in range(GP.N_ANCLA)][::-1]
    trims = {q: apoyo_sint[R.cm(R.mi(ult) + e0 + 3 * q)] for q in range(GP.N_TRIM)}
    serie = GP.denton_directo(obs, trims, fase, R.VARIANTE_DENTON)
    for k in (1, 2):
        t = R.cm(R.mi(ult) + k)
        x, kk = R.x_vc(ipc_cortado, apoyo_sint, t)
        i = GP.N_ANCLA - 1 + k
        peor = max(peor, abs(x - serie[i - 2: i + 1].mean()))
chk("x VC con k = 1 y 2 (7 meses de corte, las 3 fases) = Denton directo", peor < 1e-12, f"dif max {peor:.1e}")
x0, k0 = R.x_vc(IPC, apoyo_sint, "202609")
chk("x VC con la ventana observada (k = 0) = MA3 del observado, sin APOYO",
    k0 == 0 and x0 == float(np.mean([v12["202607"], v12["202608"], v12["202609"]])), f"{x0!r}")
try:
    R.x_vc({c: v for c, v in IPC.items() if c <= "202606"}, apoyo_sint, "202609")
    chk("k = 3 se rechaza (fuera de diseno)", False)
except ValueError as e:
    chk("k = 3 se rechaza (fuera de diseno)", "k = 1 o 2" in str(e))

print("\nP7. El job se detiene sin escribir")
r, s = correr_job("cppibkren", DS["cppibkren"], OBJ["vcadmbnk"], os.path.join(TMP, "p7"))
chk("pkl de otro modelo -> Detenido", r.returncode == 1 and s is None, r.stdout.strip()[-60:])
mal = DS["cppibkren"].copy()
mal.loc[mal.index[:3], "var_macro_02"] = np.nan
r, s = correr_job("cppibkren", mal, OBJ["cppibkren"], os.path.join(TMP, "p7"))
chk("x congelada vacia -> Detenido", r.returncode == 1 and s is None, r.stdout.strip()[-60:])
r, s = correr_job("cppibkren", DS["cppibkren"], None, os.path.join(TMP, "p7"))
chk("Sin pkl -> Detenido", r.returncode == 1 and s is None, r.stdout.strip()[-60:])

print("\nP8. Recalibrar = pkl nuevo")
nuevo = copy.deepcopy(OBJ["vcadmbnk"])
f = nuevo.productos["TC"]["filas"]
f.loc[(f.parametro == "lambda") & (f.llave_clean == "1"), "valor"] = 1.8
nuevo.id_calibracion = "vcadmbnk_202701_v1"
_, b = correr_job("vcadmbnk", DS["vcadmbnk"], nuevo, os.path.join(TMP, "p8"))
a = ESP["vcadmbnk"]
limpio = DS["vcadmbnk"].flg_clean_01.to_numpy() == "1"
fa, fb = a.prob_modelo_cal_tc.astype(float).to_numpy(), b.prob_modelo_cal_tc.astype(float).to_numpy()
chk("Cambian solo los TC limpios", (fa[limpio] != fb[limpio]).all() and (fa[~limpio] == fb[~limpio]).all()
    and all(igual_df(a[[c]], b[[c]])[0] for c in a.columns if not c.endswith("_tc") and c != "id_calibracion"))
chk("id_calibracion del scr = version nueva", (b.id_calibracion == "vcadmbnk_202701_v1").all())

shutil.rmtree(TMP, ignore_errors=True)
print(f"\nRESULTADO: {sum(res)}/{len(res)} chequeos OK")
sys.exit(0 if all(res) else 1)
