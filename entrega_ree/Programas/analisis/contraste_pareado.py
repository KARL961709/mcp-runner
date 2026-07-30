# -*- coding: utf-8 -*-
# =============================================================================
# CONTRASTE PAREADO ENTRE CALIBRADORES — por segmento, fuera de muestra
#   Responde: la ventaja de Beta sobre Platt y sobre el shift, ¿es real o es ruido?
#   Diseño: leave-one-month-out. Para cada mes se ajusta en los otros 18 y se
#   predice ese mes; se compara el Brier del mes entre familias, PAREADO.
#   Test: Wilcoxon de rangos con signo sobre las 19 diferencias mensuales.
# =============================================================================
import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import wilcoxon

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / 'src'))
sys.path.insert(0, str(RAIZ / 'analisis'))
warnings.filterwarnings('ignore')

from metrics import brier                                          # noqa: E402
from benchmark_calibradores import ShiftCalibrator, _Platt, _Beta   # noqa: E402

d = pd.read_parquet(RAIZ / 'outputs_v5/parquets/full_calibrated.parquet')
d['cm'] = d['codmes'].astype(str)
z1 = d[(d['cm'] >= '202312') & (d['cm'] <= '202506') & d['target_12m'].notna()]

FAM = [('Shift', ShiftCalibrator), ('Platt', _Platt),
       ('Beta', lambda: _Beta(True))]

print('=' * 84)
print('  CONTRASTE PAREADO FUERA DE MUESTRA (leave-one-month-out, Brier por mes)')
print('=' * 84)

res = {}
for seg in ['DEP', 'NO DEP']:
    s = z1[z1['tipo_ingreso_dep'] == seg]
    X, y, cm = s['pd'].values, s['target_12m'].values.astype(float), s['cm'].values
    meses = sorted(np.unique(cm))
    br = {n: [] for n, _ in FAM}
    for m in meses:
        te = cm == m
        if te.sum() < 5 or len(np.unique(y[~te])) < 2:
            continue
        for n, mk in FAM:
            p = mk().fit(X[~te], y[~te]).predict(X[te])
            br[n].append(brier(y[te], p))
    for n in br:
        br[n] = np.array(br[n])
    res[seg] = br

    print('\n  --- %s  (n=%s, %d meses) ---' % (seg, '{:,}'.format(len(s)), len(br['Beta'])))
    print('  %-28s %12s %12s %10s %10s' % ('contraste', 'Brier medio', 'dif media', 'p Wilcoxon', 'veredicto'))
    for rival in ['Platt', 'Shift']:
        dif = br[rival] - br['Beta']          # >0 favorece a Beta
        stat, p = wilcoxon(dif) if np.any(dif != 0) else (np.nan, 1.0)
        gana = int((dif > 0).sum())
        ver = 'Beta mejor' if p < 0.05 and dif.mean() > 0 else (
              '%s mejor' % rival if p < 0.05 else 'indistinguibles')
        print('  Beta vs %-20s %12.6f %+12.2e %10.4f %10s'
              % (rival, br['Beta'].mean(), dif.mean(), p, ver))
        print('  %-28s Beta gana en %d de %d meses' % ('', gana, len(dif)))

print()
print('=' * 84)
print('  LECTURA')
print('=' * 84)
print('  Si el p es alto, la ventaja de Beta en el estimador puntual NO es')
print('  distinguible del ruido y el sustento de la eleccion debe declararse')
print('  como estructural, no como superioridad de ajuste.')

out = RAIZ / 'outputs_v5/json/contraste_pareado.json'
json.dump({seg: {n: v.tolist() for n, v in br.items()} for seg, br in res.items()},
          open(out, 'w', encoding='utf-8'), indent=1)
print('\n  escrito %s' % out.name)
