# -*- coding: utf-8 -*-
# =============================================================================
# REVISION DE LAS TRES ETIQUETAS RESTANTES
#   Para cada una: que afirma el codigo, que refuta el ledger, y que dice el dato
#   sobre la MAGNITUD del problema. Una etiqueta severa sobre un efecto de 1 bps
#   no es proporcionada; una sobre un efecto de 50 bps si.
# =============================================================================
import io
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
led = io.open(RAIZ / 'config/LEDGER_PARAMETROS.md', encoding='utf-8').read()

for k in ['INFLATION_EXCL_MONTHS', 'DRIVER_RMSE_THRESHOLD', 'EC_MULT_DEFAULT']:
    print('=' * 92)
    print('  ', k)
    print('=' * 92)
    for l in led.splitlines():
        if k in l and l.strip().startswith('|'):
            c = [x.strip() for x in l.split('|')][1:-1]
            et = ['parámetro', 'valor', 'gobierna', 'derivación/cita', 'medición', 'sensibilidad', 'estado']
            for i, x in enumerate(c):
                if x and x != '---':
                    print('   %-18s %s' % (et[i] if i < len(et) else '', x[:340]))
            break
    print()
