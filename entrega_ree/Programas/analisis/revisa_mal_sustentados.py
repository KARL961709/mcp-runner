# -*- coding: utf-8 -*-
# =============================================================================
# REVISION DE LAS ETIQUETAS "MAL SUSTENTADO"
#   Contrasta la refutacion del ledger contra lo que el dato permite afirmar.
#   1. LRA_METHOD  : robustez NO es eficiencia. Se mide la robustez de verdad.
#   2. RHO_FLOOR   : que rho usa realmente el modelo, y si el piso interviene.
#   3. F_CAP_QUANTILE : magnitud del efecto del cap.
# =============================================================================
import json
import numpy as np
import pandas as pd
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
lra = json.load(open(RAIZ / 'outputs_v5/json/lra.json', encoding='utf-8'))
rd = pd.read_csv(RAIZ / 'outputs_v5/csv/rd_mensual.csv')
col = ['rd']
rd['codmes'] = rd[rd.columns[0]].astype(str)

exc = set()
for v in lra.get('exclusions', {}).values():
    if isinstance(v, (list, tuple)):
        exc.update(str(x) for x in v)
s = rd[~rd['codmes'].isin(exc)][col[0]].dropna().values
s = s[np.isfinite(s)]

print('=' * 78)
print('  1. LRA_METHOD --- ¿la mediana es robusta?')
print('=' * 78)
print('  serie de RD12 sobre la ventana del ancla: n=%d' % len(s))
print('  media %.6f%%   mediana %.6f%%' % (100 * s.mean(), 100 * np.median(s)))
print()
print('  PRUEBA DE ROBUSTEZ (lo que el código afirma): efecto de contaminar un dato')
peor = s.copy()
i = int(np.argmax(peor))
for factor in (2, 5, 10):
    c = s.copy(); c[i] = s[i] * factor
    print('    si el mes más alto se multiplica por %2d  -> media %+7.2f bps | mediana %+7.2f bps'
          % (factor, 1e4 * (c.mean() - s.mean()), 1e4 * (np.median(c) - np.median(s))))
print()
print('  PUNTO DE RUPTURA: proporción de datos que hay que corromper para arrastrar el estimador')
print('    media   : 1 dato de %d  (%.1f%%)' % (len(s), 100 / len(s)))
print('    mediana : %d datos de %d (50%%)' % (len(s) // 2, len(s)))
print()
print('  LECTURA: robustez y eficiencia son propiedades distintas. El ledger midió el')
print('  error estándar (eficiencia) para refutar una afirmación de robustez.')

print()
print('=' * 78)
print('  2. RHO_FLOOR --- ¿qué rho usa el modelo?')
print('=' * 78)
rho = json.load(open(RAIZ / 'outputs_v5/json/vasicek_rho.json', encoding='utf-8'))
print('  rho aplicado (momentos, sobre ESTA cartera) : %.6f' % rho['rho_final'])
print('  piso declarado                              : 0.033200')
print('  ¿el piso interviene?                        : %s'
      % ('NO --- el rho medido lo supera en %.1f%%'
         % (100 * (rho['rho_final'] / 0.0332 - 1)) if rho['rho_final'] > 0.0332 else 'SI'))


def rho_basel(pd_):
    k = (1 - np.exp(-35 * pd_)) / (1 - np.exp(-35))
    return 0.03 * k + 0.16 * (1 - k)


print()
print('  fórmula IRB «other retail» evaluada en distintos PD:')
for p in (0.0292, 0.0331, 0.0354, 0.0423, 0.1058):
    print('    PD = %6.2f%%  ->  rho_Basel = %.6f' % (100 * p, rho_basel(p)))
print('  la fórmula es decreciente en PD: a mayor PD, menor correlación')
print('  el rho de esta cartera se ESTIMA sobre su propia serie, no se toma de la fórmula')

print()
print('=' * 78)
print('  3. F_CAP_QUANTILE --- magnitud del efecto')
print('=' * 78)
print('  barrido registrado (PD_pit Z1 respecto de la base P5/P95):')
for q, e in [('0,80', '+10,4'), ('0,90', '+2,6'), ('0,95 (vigente)', '0,0'),
             ('0,975', '-0,7'), ('0,99', '-1,1'), ('1,00 sin cap', '-1,2')]:
    print('    q = %-16s %s bps' % (q, e))
print('  suprimir el cap por completo mueve la PD 1,2 bps: el parámetro es inmaterial')
