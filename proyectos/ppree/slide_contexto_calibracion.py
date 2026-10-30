# -*- coding: utf-8 -*-
"""Update Calibracion PP Reenganche -- CONTEXTO. Lamina 1 de una secuencia de 3.

ALCANCE, que es lo que las versiones anteriores tenian mal: esta lamina SOLO da
contexto. El impacto va en la lamina siguiente y las alternativas V1/V2 en la
tercera. Por eso aqui NO van las tarjetas de "que cambia / que no cambia": eso
es el final, y contarlo antes le quita sentido a las dos laminas que siguen.

La cadena de contexto, en tres eslabones y nada mas:
    que es el modelo   ->   sobre que se calibro   ->   que necesita campana

A la derecha, la foto RD vs PD, que es el puente hacia la lamina del impacto.
La serie de PD previa al alta la completa el usuario: el grafico es nativo, asi
que se agrega desde Editar datos sin tocar el diseno.
"""
import os
import sys
from pathlib import Path

# El motor de laminas (deck.py / theme.py / textfit.py) viene de la skill
# enr-ppt-editable y NO vive en este repo. En otra maquina la ruta cambia, asi
# que se toma de ENR_PPT_SCRIPTS y, si no esta, se cae con un mensaje
# accionable en vez de un ImportError sin contexto.
SK = os.environ.get('ENR_PPT_SCRIPTS') or (
    r'C:\Users\CARLOS\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc'
    r'\local-agent-mode-sessions\skills-plugin\47605a77-e2ab-4661-9efe-85d048cc6bab'
    r'\ba2b094c-6faa-46ff-b8b7-d2b5dca44b1a\skills\enr-ppt-editable\scripts')
if not (Path(SK) / 'deck.py').exists():
    sys.exit('No encuentro el motor de laminas en:\n  %s\n'
             'Define ENR_PPT_SCRIPTS apuntando a la carpeta scripts/ de la '
             'skill enr-ppt-editable.' % SK)
sys.path.insert(0, str(SK))
from deck import Deck                      # noqa
import theme as T                          # noqa
from pptx.enum.shapes import MSO_SHAPE     # noqa

OUT = Path(os.environ.get('ENR_PPT_OUT') or Path(__file__).resolve().parent)

CAT = ['202410', '202411', '202412', '202501', '202502', '202503',
       '202504', '202505', '202506', '202507', '202508', '202509']
RD = [3.5688, 2.9215, 4.4961, 4.1737, 2.6475, 2.5352, 2.3211, 2.8787, 3.0071, 2.4272, 2.8020, 2.6474]
PD1 = [3.0635, 2.2655, 3.5270, 3.0602, 3.0798, 2.6826, 2.8206, 2.5199, 2.8970, 2.8049, 2.7937, 2.7258]


def persona(s, cx, top, h=0.34, color='muted'):
    rh = h * 0.38
    s.rect(cx - rh / 2, top, rh, rh, fill=color, line=None, shape=MSO_SHAPE.OVAL)
    bw, bh = h * 0.72, h * 0.50
    s.rect(cx - bw / 2, top + rh * 1.18, bw, bh, fill=color, line=None,
           shape=MSO_SHAPE.ROUND_2_SAME_RECTANGLE, radius=0.5)


def cartera(s, cx, top, n=4, h=0.30, sep=0.24):
    x0 = cx - sep * (n - 1) / 2
    for i in range(n):
        a = h if i in (1, 2) else h * 0.82
        persona(s, x0 + i * sep, top + (h - a), h=a,
                color='accent_dark' if i in (1, 2) else 'accent_line')


d = Deck(footer_title='Comportamental PP Reenganche  ·  Calibracion de PD',
         footer_sub='Gerencia', show_page_numbers=False)
s = d.slide()

y = s.header(eyebrow='Contexto',
             title='Update Calibracion PP Reenganche',
             lead=[('Es un modelo de ', {}),
                   ('STOCK', {'bold': True, 'color': 'accent_dark'}),
                   (': puntua a toda la cartera cada mes, y en ese mismo reporte viene la ', {}),
                   ('marca de reenganche', {'bold': True, 'color': 'accent_dark'}),
                   ('.', {})])
print('  header y = %.3f' % y)

LW = 6.55
RX = T.MARGIN_L + LW + 0.36
RW = T.CONTENT_R - RX
BOT = s.content_bottom() - 0.44          # deja aire para la linea de enlace

# ======================================================= IZQUIERDA: la cadena
yL = y + 0.08
PASOS = [
    ('Es un modelo de STOCK', 'No puntua desembolsos: puntua a toda la cartera cada mes. La marca de quien se reengancho viene en ese mismo reporte.', 'cartera'),
    ('El reporte llega con un mes de desfase', 'El de octubre trae la informacion al cierre de setiembre. Por eso usamos el reporte del mes siguiente al desembolso.', 'persona'),
    ('Y ahi el reenganche YA esta marcado', '15,226 de 15,226 casos. Es la senal de que ese reporte es posterior al desembolso, y campana decide ANTES.', 'persona_acc'),
]
hp = 1.02
for i, (tit, txt, ico) in enumerate(PASOS):
    ok = (i == 2)
    yy = yL + i * (hp + 0.10)
    s.rect(T.MARGIN_L, yy, LW, hp, fill='accent_bg' if ok else 'surface',
           line='accent_line' if ok else 'border', radius=0.05)
    cxi = T.MARGIN_L + 0.72
    if ico == 'cartera':
        cartera(s, cxi, yy + 0.30, n=4, h=0.28)
    else:
        persona(s, cxi, yy + 0.30, h=0.30,
                color='accent_dark' if ok else 'muted')
    s.text(T.MARGIN_L + 1.38, yy + 0.18, LW - 1.62, 0.26, tit, style='item_title',
           size=13, color='accent_dark' if ok else 'ink')
    s.text(T.MARGIN_L + 1.38, yy + 0.48, LW - 1.62, 0.52, txt, style='item_body',
           size=10.8, color='ink' if ok else 'muted')

# franja: las dos fotos alrededor del alta
yM = yL + 3 * (hp + 0.10) + 0.06
HM = BOT - yM
s.rect(T.MARGIN_L, yM, LW, HM, fill='white', line='border', radius=0.05)
s.text(T.MARGIN_L + 0.26, yM + 0.12, LW - 0.52, 0.20,
       'DOS MOMENTOS DEL MISMO CLIENTE', style='eyebrow', size=8.4, color='muted')
cxm = T.MARGIN_L + LW / 2
bw_f, by_f = 2.42, yM + 0.34
s.rect(T.MARGIN_L + 0.26, by_f, bw_f, 0.58, fill='accent_bg', line='accent_line', radius=0.05)
s.text(T.MARGIN_L + 0.26, by_f + 0.07, bw_f, 0.22, 'ANTES de desembolsar',
       style='item_title', align='center', size=11, color='accent_dark')
s.text(T.MARGIN_L + 0.26, by_f + 0.31, bw_f, 0.20, 'la PD que necesita campana',
       style='note', align='center', size=8.8, color='accent')
xr = T.MARGIN_L + LW - 0.26 - bw_f
s.rect(xr, by_f, bw_f, 0.58, fill='surface', line='border', radius=0.05)
s.text(xr, by_f + 0.07, bw_f, 0.22, 'DESPUES de desembolsar',
       style='item_title', align='center', size=11, color='ink')
s.text(xr, by_f + 0.31, bw_f, 0.20, 'la PD que usamos hoy',
       style='note', align='center', size=8.8, color='muted')
persona(s, cxm, by_f + 0.03, h=0.30, color='accent_dark')
s.text(cxm - 0.70, by_f + 0.40, 1.40, 0.20, 'desembolso', style='note',
       align='center', size=9, color='accent_dark')

# ======================================================= DERECHA: la foto
s.rect(RX, yL, RW, BOT - yL, fill='white', line='border', radius=0.05)
s.text(RX + 0.26, yL + 0.16, RW - 0.52, 0.22, 'MORA REAL CONTRA LA PD DEL MODELO',
       style='eyebrow', size=8.4, color='muted')
s.text(RX + 0.26, yL + 0.38, RW - 0.52, 0.22, 'ultimos 12 meses con mora ya observada',
       style='note', size=9, color='muted')
s.chart('line', RX + 0.14, yL + 0.64, RW - 0.28, 3.30,
        categories=CAT,
        series={'Mora real': RD, 'PD que usamos hoy': PD1},
        number_format='0.0"%"', min_scale=2.0, max_scale=4.8, gridlines=True)

# ======================================================= enlace a lo que sigue
s.line(T.MARGIN_L, BOT + 0.14, T.CONTENT_W, color='border')
s.text(T.MARGIN_L, BOT + 0.22, T.CONTENT_W, 0.24,
       [[('A continuacion:  ', {'color': 'muted'}),
         ('el impacto medido', {'bold': True, 'color': 'accent_dark'}),
         ('   y   ', {'color': 'muted'}),
         ('las alternativas V1 y V2', {'bold': True, 'color': 'accent_dark'})]],
       style='item_body', size=11)

p = OUT / 'update_calibracion_ppree.pptx'
d.save(str(p))
print('ok -> %s' % p)
