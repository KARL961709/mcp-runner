"""
shap_muestra.py -- TreeSHAP sobre ds_adm_bpe_shap_muestra (salida de 95_shap_muestra.sql)

Uso:  python shap_muestra.py <ruta_parquet_o_carpeta> [ruta_modelo.sav]

Corre en TRES pasos y el paso 1 decide si los otros dos valen algo:

  1  TEST DE ESCALA. Aplica el artefacto a las columnas woe_* y compara contra
     la columna `probabilidad` que ya viene calculada en la tabla de score.
     Si NO reproduce, las woe_* no son los inputs del modelo y cualquier
     atribucion posterior seria falsa. El script lo dice y para.

  2  DESCOMPOSICION IBK vs RESTO_TOP4 vs SSFF, reponderada por n_estrato
     (la muestra es 1000 por poblacion x codmes, los estratos son desiguales).

  3  DESCOMPOSICION TEMPORAL: que variables mueven la PD de 202603 en adelante.
"""
import sys, os, pickle, glob
import numpy as np
import pandas as pd

RUTA = sys.argv[1] if len(sys.argv) > 1 else "."
MODELO = sys.argv[2] if len(sys.argv) > 2 else "model_ligthbm_admbank.sav"

VARS = ["woe_prm_decresldo12m","woe_max_nrocredsldo06m","woe_nro_decresldo12m",
"rat_promsldnegdecre03y06m","woe_cant_vehi","woe_cant_entireportsisnoreg","woe_dpt_grupo_v2",
"woe_edad","woe_avg_porcsald_otrasent12m","woe_prm_deudatelco12m","woe_anti_negmeses",
"woe_prm_decresldopp12m","woe_min_sldopasi06m","woe_beta_nroenti","woe_beta_sldoppcomer",
"woe_prm_decresldotc12m","woe_prm_porcsldoimpa12m","woe_prm_usotcfueraibk12m","woe_beta_sldotc12m",
"woe_prm_nrotrxcashout06m","woe_nro_dismsaldonormal12mcny","woe_peor_clasicony09m",
"woe_max_dismsldoretail03m","woe_ciiu_grupo_v2","woe_max_dismsldo12rl",
"woe_nro_mesesdismsldoretail12m","woe_max_nroentinegocny06m","woe_prm_ratdispefect03m",
"woe_nro_mesescastin06m","rat_promsldnegdecreprin3y6m","woe_max_dismsldonoprinc12m",
"woe_nro_mesesatrasmay8dias09m","woe_beta_sldopp12m","woe_rat_sldo09msobre12mrl",
"woe_max_diasatras09mrl","woe_prm_valorexpimp12m","woe_nro_mesesdicmsldoprinc12m",
"woe_porc_messldogiro06m","woe_rat_sldonormal3msobre12mrl"]

PROD2MOD = {
 "woe_cant_entireportsisnoreg":"ctd_entreport12m","woe_beta_sldoppcomer":"beta_saldo_pc_u1a",
 "woe_nro_decresldo12m":"cuenta_decre_12m_total","woe_avg_porcsald_otrasent12m":"avg_porcsald_otrasent12m",
 "woe_prm_decresldo12m":"prom_dec_12m_total","woe_cant_vehi":"cantidad_veh",
 "woe_beta_nroenti":"beta_entidades_dist_rd_u1a","woe_prm_decresldopp12m":"prom_dec_12m_pp_sf_total",
 "woe_prm_deudatelco12m":"prm_ddatelc12m","woe_min_sldopasi06m":"min_sldpdvtotal_6um",
 "woe_max_nrocredsldo06m":"max_num_tip_cred_u6m","woe_edad":"edad",
 "rat_promsldnegdecre03y06m":"ratio_prm_sald_neg_dct_3m_6m","woe_anti_negmeses":"ant_negocio",
 "woe_prm_usotcfueraibk12m":"prm_usotcrrstsf12m","woe_prm_porcsldoimpa12m":"avg_pct_saldo_impago_u1a",
 "woe_peor_clasicony09m":"peor_cls_sbs_9um_cny","woe_max_dismsldo12rl":"max_d_sld_12um_rl",
 "woe_ciiu_grupo_v2":"ciiu_grupo_v2","woe_max_dismsldoretail03m":"max_d_sldrctret_3um",
 "woe_nro_mesesdismsldoretail12m":"num_meses_disldrctret_12m","woe_max_dismsldonoprinc12m":"max_d_sldretnoprin_12um",
 "woe_max_diasatras09mrl":"max_dm9um_rl","woe_max_nroentinegocny06m":"max_num_ent_neg6um_cny",
 "woe_rat_sldo09msobre12mrl":"rt9sld12_rl","woe_prm_nrotrxcashout06m":"x6_numout_trans",
 "woe_prm_ratdispefect03m":"prom_ratio_disp_ef_pnj_u3m","woe_nro_dismsaldonormal12mcny":"num_dsldnor_12um_cny",
 "rat_promsldnegdecreprin3y6m":"ratio_prm_sald_neg_dct_prin_3m_6m","woe_nro_mesesatrasmay8dias09m":"num_meses_8dm_u9m",
 "woe_prm_valorexpimp12m":"x12_valor__impexp","woe_nro_mesescastin06m":"ct_in_6um",
 "woe_porc_messldogiro06m":"pct_meses_sgiro_u6m","woe_beta_sldotc12m":"beta_saldo_tc_tot_u1a",
 "woe_beta_sldopp12m":"beta_saldo_pp_u6m","woe_dpt_grupo_v2":"dpt_grupo_v2",
 "woe_nro_mesesdicmsldoprinc12m":"num_meses_disldrctprin_6m","woe_prm_decresldotc12m":"prom_dec_12m_tc_total",
 "woe_rat_sldonormal3msobre12mrl":"rt3sldnor12_rl"}
assert len(PROD2MOD) == 39

FUENTE = {"min_sldpdvtotal_6um":"PASIVOS-IBK","x6_numout_trans":"TRX-IBK","beta_saldo_tc_tot_u1a":"TRX-IBK",
 "ciiu_grupo_v2":"TRX-IBK","num_meses_8dm_u9m":"TRX-IBK","x12_valor__impexp":"ADEX",
 "num_meses_disldrctprin_6m":"ADEX","cantidad_veh":"SUNARP","ant_negocio":"SUNAT",
 "max_d_sld_12um_rl":"SUNAT","ctd_entreport12m":"SENTINEL","prm_ddatelc12m":"SENTINEL",
 "dpt_grupo_v2":"RENIEC","edad":"RENIEC"}


def cargar(ruta):
    if os.path.isdir(ruta):
        fs = sorted(glob.glob(os.path.join(ruta, "**", "*.parquet"), recursive=True))
        if not fs:
            fs = sorted(glob.glob(os.path.join(ruta, "**", "*"), recursive=True))
            fs = [f for f in fs if os.path.isfile(f) and os.path.getsize(f) > 1000]
        if not fs:
            sys.exit("no encontre parquets en %s" % ruta)
        print("leyendo %d archivo(s)" % len(fs))
        return pd.concat([pd.read_parquet(f) for f in fs], ignore_index=True)
    return pd.read_parquet(ruta)


def sigmoid(z):
    return 1.0 / (1.0 + np.exp(-z))


df = cargar(RUTA)
print(f"filas {len(df):,}  columnas {df.shape[1]}")
print("  por poblacion:", df.pob.value_counts().to_dict() if "pob" in df else "sin columna pob")
falta = [v for v in VARS if v not in df.columns]
if falta:
    sys.exit("faltan columnas en el parquet: %s" % falta)

bst = pickle.load(open(MODELO, "rb"))
bst = bst.booster_ if hasattr(bst, "booster_") else bst
FN = list(bst.feature_name())

X = pd.DataFrame({PROD2MOD[v]: pd.to_numeric(df[v], errors="coerce") for v in VARS})[FN]

# ---------------------------------------------------------------- 1  ESCALA
print("\n" + "=" * 78)
print("PASO 1  TEST DE ESCALA  --  el modelo reproduce la columna `probabilidad`?")
print("=" * 78)
p_mod = bst.predict(X)
p_tab = pd.to_numeric(df["probabilidad"], errors="coerce").values
ok = np.isfinite(p_mod) & np.isfinite(p_tab)
dif = np.abs(p_mod[ok] - p_tab[ok])
corr = np.corrcoef(p_mod[ok], p_tab[ok])[0, 1]
print(f"  n comparables      {ok.sum():,}")
print(f"  max |dif|          {dif.max():.3e}")
print(f"  media |dif|        {dif.mean():.3e}")
print(f"  p99  |dif|         {np.percentile(dif, 99):.3e}")
print(f"  correlacion        {corr:.6f}")
print(f"  PD media modelo    {p_mod[ok].mean()*100:.4f}%")
print(f"  PD media tabla     {p_tab[ok].mean()*100:.4f}%")

REPRODUCE = dif.max() < 1e-6
if REPRODUCE:
    print("\n  >>> REPRODUCE EXACTO. Las columnas woe_* SON los inputs del modelo.")
    print("      La atribucion SHAP de los pasos 2 y 3 es valida.")
elif corr > 0.99:
    print("\n  >>> NO reproduce al bit pero correlaciona >0.99: probable diferencia de")
    print("      version del artefacto. SHAP sirve para el ORDEN, no para el nivel.")
else:
    print("\n  >>> NO REPRODUCE. Las woe_* no son los inputs de este artefacto.")
    print("      Los pasos 2 y 3 se corren igual pero NO deben reportarse como")
    print("      atribucion del modelo en produccion. Hace falta el artefacto que")
    print("      genero esta columna, o las variables crudas.")

# ------------------------------------------------------ pesos de la muestra
n_estr = pd.to_numeric(df["n_estrato"], errors="coerce")
tam = df.groupby(["pob", "codmes"])["pob"].transform("size")
df["w"] = (n_estr / tam).fillna(1.0)
print("\npesos de reponderacion  min %.2f  mediana %.2f  max %.2f" %
      (df.w.min(), df.w.median(), df.w.max()))

contrib = bst.predict(X, pred_contrib=True)
SH = pd.DataFrame(contrib[:, :-1], columns=FN)
BASE = contrib[0, -1]


def prom(mask, col):
    w = df.loc[mask, "w"].values
    return np.average(SH.loc[mask.values, col].values, weights=w)


# ------------------------------------------------------------- 2  POBLACION
print("\n" + "=" * 78)
print("PASO 2  DESCOMPOSICION POR POBLACION  (log-odds, reponderado)")
print("=" * 78)
for pob in ["IBK", "RESTO_TOP4", "SSFF"]:
    m = df.pob == pob
    w = df.loc[m, "w"].values
    print(f"  {pob:<12} n={m.sum():>7,}  peso={w.sum():>12,.0f}  "
          f"PD={np.average(p_mod[m.values], weights=w)*100:>7.3f}%  "
          f"logodds={np.average(SH.loc[m.values].sum(axis=1).values, weights=w)+BASE:>8.4f}")

mi, ms = df.pob == "IBK", df.pob == "SSFF"
fil = []
for f in FN:
    d = prom(ms, f) - prom(mi, f)
    fil.append((f, prom(mi, f), prom(ms, f), d, FUENTE.get(f, "RCC")))
tot = sum(r[3] for r in fil)
if abs(tot) < 1e-9:
    sys.exit("brecha SSFF-IBK nula: revisar que la columna pob tenga las tres poblaciones")
fil.sort(key=lambda r: -abs(r[3]))
print(f"\n  brecha total SSFF - IBK = {tot:+.4f} log-odds")
print(f"\n  {'variable':<36}{'fuente':<13}{'SHAP ibk':>10}{'SHAP ssff':>11}{'delta':>10}{'% brecha':>10}")
print("  " + "-" * 90)
for f, a, b, d, fu in fil[:20]:
    print(f"  {f:<36}{fu:<13}{a:>10.4f}{b:>11.4f}{d:>+10.4f}{100*d/tot:>9.1f}%")
ext = sum(d for f, a, b, d, fu in fil if fu != "RCC")
print(f"\n  fuentes NO-RCC (lo que el SSFF no puede tener): {100*ext/tot:.1f}% de la brecha")

# -------------------------------------------------------------- 3  TIEMPO
print("\n" + "=" * 78)
print("PASO 3  QUE MUEVE LA PD DESDE 202603  (IBK, clean + dirty)")
print("=" * 78)
d2 = df[df.pob == "IBK"].copy()
d2["cm"] = pd.to_numeric(d2["codmes"], errors="coerce")
ini, fin = (d2.cm >= 202507) & (d2.cm <= 202602), d2.cm >= 202603
if fin.sum() < 50 or ini.sum() < 50:
    print("  muestra insuficiente en alguna ventana (ini=%d fin=%d)" % (ini.sum(), fin.sum()))
else:
    fil2 = []
    for f in FN:
        a = np.average(SH.loc[d2.index[ini], f].values, weights=d2.loc[ini, "w"].values)
        b = np.average(SH.loc[d2.index[fin], f].values, weights=d2.loc[fin, "w"].values)
        fil2.append((f, a, b, b - a))
    t2 = sum(r[3] for r in fil2)
    fil2.sort(key=lambda r: -abs(r[3]))
    print(f"  202507-202602 n={ini.sum():,}   202603+ n={fin.sum():,}")
    print(f"  cambio total en log-odds = {t2:+.4f}")
    print(f"\n  {'variable':<36}{'antes':>10}{'desde 202603':>14}{'delta':>10}{'% cambio':>10}")
    print("  " + "-" * 82)
    for f, a, b, d in fil2[:15]:
        print(f"  {f:<36}{a:>10.4f}{b:>14.4f}{d:>+10.4f}{100*d/t2:>9.1f}%")

# ------------------------------------------------------------------ salida
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "outputs")
os.makedirs(out, exist_ok=True)
res = pd.DataFrame(fil, columns=["variable", "shap_ibk", "shap_ssff", "delta", "fuente"])
res["pct_brecha"] = 100 * res.delta / tot
res.to_csv(os.path.join(out, "shap_ibk_vs_ssff.csv"), index=False)
print("\nescrito outputs/shap_ibk_vs_ssff.csv")
