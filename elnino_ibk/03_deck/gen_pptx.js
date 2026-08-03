// FEN -> PD estresada · version PPTX del mazo.
// Texto, tablas y recuadros van nativos (editables en PowerPoint); mapas y graficos entran como
// PNG rasterizados con svg2png.js. Tipografias: el mazo HTML usa Archivo, Nunito y JetBrains Mono,
// que no estan instaladas en Windows ni en las maquinas del banco; aca se sustituyen por Segoe UI
// y Consolas para que el archivo se vea igual en cualquier equipo.
const P = require('pptxgenjs');
const fs = require('fs');

const VERDE = '00A94F', TINTA = '000000', GRIS = '6E6E6E', SUAVE = 'D8D8D8',
      ROJO = 'A8140F', CLARO = 'A5A5A5', FONDO = 'F4F5F6';
const TIT = 'Segoe UI Black', TXT = 'Segoe UI', MONO = 'Consolas';

const pres = new P();
pres.defineLayout({ name: 'FEN169', width: 13.333, height: 7.5 });
pres.layout = 'FEN169';   // LAYOUT_16x9 de pptxgenjs son 10 x 5.625 in, no 13.333 x 7.5
const W = 13.333, H = 7.5, M = 0.62;  // margenes

// --- andamiaje comun a todos los slides -------------------------------------------------------
function base(s, kick, t1, t2){
  s.background = { color: 'FFFFFF' };
  s.addShape(pres.ShapeType.rect, { x: W-0.14, y: 0, w: 0.14, h: H, fill: { color: VERDE } });
  s.addShape(pres.ShapeType.rect, { x: M, y: 0.42, w: 0.11, h: 0.11, fill: { color: VERDE } });
  s.addText(kick.toUpperCase(), { x: M+0.2, y: 0.33, w: 9, h: 0.3, fontFace: TXT, fontSize: 9.5,
    bold: true, color: GRIS, charSpacing: 2.2 });
  s.addText([{ text: t1+' ', options: { color: TINTA } }, { text: t2, options: { color: VERDE } }],
    { x: M-0.05, y: 0.62, w: W-2*M, h: 0.72, fontFace: TIT, fontSize: 33, valign: 'top' });
  s.addShape(pres.ShapeType.rect, { x: M, y: 1.44, w: 1.05, h: 0.045, fill: { color: VERDE } });
  s.addShape(pres.ShapeType.rect, { x: M+1.05, y: 1.44, w: W-2*M-1.05, h: 0.045, fill: { color: TINTA } });
}
function cierre(s, fuerte, sub){
  s.addShape(pres.ShapeType.rect, { x: M, y: H-1.16, w: W-2*M, h: 0.012, fill: { color: SUAVE } });
  s.addText(fuerte, { x: M, y: H-1.05, w: W-2*M, h: 0.3, fontFace: TIT, fontSize: 14, color: TINTA });
  s.addText(sub, { x: M, y: H-0.72, w: W-2*M, h: 0.5, fontFace: TXT, fontSize: 9.5, color: GRIS, lineSpacing: 13 });
}
// formula en caja gris con filete negro a la izquierda
function formula(s, txt, x, y, w){
  s.addShape(pres.ShapeType.rect, { x, y, w, h: 0.36, fill: { color: FONDO } });
  s.addShape(pres.ShapeType.rect, { x, y, w: 0.032, h: 0.36, fill: { color: TINTA } });
  s.addText(txt, { x: x+0.14, y, w: w-0.2, h: 0.36, fontFace: MONO, fontSize: 10.5, color: TINTA, valign: 'middle' });
}
// recuadro negro de conclusion
function callout(s, rich, x, y, w, h){
  s.addShape(pres.ShapeType.rect, { x, y, w, h, fill: { color: TINTA } });
  s.addText(rich, { x: x+0.16, y: y+0.06, w: w-0.32, h: h-0.12, fontFace: TXT, fontSize: 10.5,
    color: 'FFFFFF', valign: 'middle', lineSpacing: 15 });
}
function rotulo(s, txt, x, y, w){
  s.addText(txt.toUpperCase(), { x, y, w, h: 0.24, fontFace: TXT, fontSize: 9, bold: true,
    color: GRIS, charSpacing: 2.2 });
  s.addShape(pres.ShapeType.rect, { x, y: y+0.26, w, h: 0.032, fill: { color: TINTA } });
}
const TB = { fontFace: TXT, fontSize: 10, color: GRIS, border: [{type:'none'},{type:'none'},
  {pt:0.6, color: SUAVE},{type:'none'}], valign: 'middle' };
const th = t => ({ text: t.toUpperCase(), options: { fontFace: TXT, fontSize: 8, bold: true,
  color: GRIS, charSpacing: 1.6, border: [{type:'none'},{type:'none'},{pt:1.4,color:TINTA},{type:'none'}] } });

// ============ 1 · LOS CINCO PASOS =============================================================
{
  const s = pres.addSlide();
  base(s, 'FEN · Riesgo de Crédito · Metodología', 'Los cinco pasos,', 'de los insumos a la PD');
  const pasos = [
    ['1', 'Daño físico', 'y = f ( severidad , recurrencia , fragilidad , exposición , atribución )',
     'DesInventar 1970-2015 · INDECI 2003-2020 · SINPAD · CENEPRED · ICEN del IGP · cuencas del ANA'],
    ['2', 'Afectación económica', 'y = f ( actividad económica del distrito , sector del cliente )',
     'Censo 2017, PEA por rama · IMARPE y PRODUCE · SINPAD agropecuario · ADEX'],
    ['3', 'Rezago de recuperación', 'y = f ( consumo observado , su propia tendencia )',
     'Índice de consumo IBK+ por departamento · SARIMA sobre el nivel'],
    ['4', 'Ubicación del cliente', 'y = f ( distrito ) en admisión · y = f ( latitud , longitud ) en stock',
     'RENIEC 98,08% · punto censal 75,88% del stock · OpenStreetMap · SRTM 30 m'],
    ['5', 'PD estresada', 'PD* = f ( PD calibrada , escenario nacional , los tres mapas , sector )',
     'Se aplica DESPUÉS de la calibración: no toca el modelo ni el ancla LRA']
  ];
  let y = 1.78;
  pasos.forEach(([n, tit, fx, fu]) => {
    s.addText(n, { x: M, y: y-0.04, w: 0.42, h: 0.4, fontFace: TIT, fontSize: 22, color: VERDE });
    s.addText(tit, { x: M+0.45, y: y-0.02, w: 2.75, h: 0.3, fontFace: TIT, fontSize: 14, color: TINTA });
    s.addText(fx, { x: M+3.3, y: y-0.01, w: 5.35, h: 0.3, fontFace: MONO, fontSize: 9.5, color: TINTA });
    s.addText(fu, { x: M+8.75, y: y-0.01, w: 3.2, h: 0.42, fontFace: TXT, fontSize: 8, color: CLARO, lineSpacing: 11 });
    s.addShape(pres.ShapeType.rect, { x: M, y: y+0.44, w: W-2*M, h: 0.008, fill: { color: SUAVE } });
    y += 0.64;
  });
  callout(s, [{ text: 'La PD estresada es POST-CALIBRACIÓN. ', options: { bold: true } },
    { text: 'El overlay se aplica encima de la PD ya calibrada: el modelo es el mismo todo el año y el overlay se enciende y se apaga con la temporada.' }],
    M, y+0.06, W-2*M, 0.52);
  cierre(s, 'Ventana operativa: enero a abril, vertiente del Pacífico.',
    'Año El Niño = máximo del Índice Costero El Niño entre enero y abril ≥ 1,3, el corte de «Cálida Moderada» del ENFEN.');
}

// ============ 2 y 3 · LOS DOS MAPAS ===========================================================
function slideMapa(cfg){
  const s = pres.addSlide();
  base(s, cfg.kick, cfg.t1, cfg.t2);
  s.addImage({ path: cfg.img, x: M-0.1, y: 1.72, w: 4.5*cfg.ar, h: 4.5 });
  const x = M+3.35, w = W-M-x;
  formula(s, cfg.fx, x, 1.76, w);
  const filas = [[th('componente'), th('qué mide'), th('fuente')]].concat(
    cfg.filas.map(f => [
      { text: f[0], options: { bold: true, color: TINTA } },
      { text: f[1] }, { text: f[2], options: { fontFace: MONO, fontSize: 8.5, color: VERDE } }]));
  s.addTable(filas, { x, y: 2.34, w, colW: [w*0.24, w*0.46, w*0.30], rowH: 0.31, ...TB });
  let cx = x;
  cfg.kpis.forEach(k => {
    s.addText(k[0], { x: cx, y: 4.62, w: 2.35, h: 0.44, fontFace: TIT, fontSize: 25, color: k[2] || TINTA });
    s.addText(k[1], { x: cx, y: 5.06, w: 2.3, h: 0.5, fontFace: TXT, fontSize: 9, color: GRIS, lineSpacing: 11 });
    cx += 2.55;
  });
  cierre(s, cfg.ci, cfg.sub);
}
slideMapa({
  kick: 'Paso 2 · Mapa de daño físico', t1: 'Dónde el agua', t2: 'destruye el activo',
  img: 'img/s2_0.png', ar: 2200/3202,
  fx: 'Daño físico = f ( severidad , recurrencia , fragilidad , exposición , atribución )',
  filas: [
    ['Severidad', 'damnificados y viviendas destruidas', 'DesInventar 83 y 98 · INDECI 2017'],
    ['Recurrencia', 'en cuántos de los 4 eventos se activó', 'DesInventar · INDECI · SINPAD'],
    ['Fragilidad', 'activación en eventos recientes', 'SINPAD 2017 y 2023-24'],
    ['Exposición', '% de población en zona inundable', 'CENEPRED, escenario FEN 2023'],
    ['Atribución', 'concentración del daño en años El Niño', 'cuencas del ANA · ICEN del IGP']],
  kpis: [['196', 'distritos en riesgo alto,\nde 1.891'],
         ['+0,50', 'correlación con el daño\npor habitante de 2017', VERDE],
         ['−0,04', 'correlación de la pobreza\ncon el mismo daño', ROJO]],
  ci: 'Ventana: enero a abril, vertiente del Pacífico.',
  sub: 'La atribución evita marcar cuencas que se inundan todos los años con o sin El Niño.'
});
slideMapa({
  kick: 'Paso 3 · Mapa de afectación económica', t1: 'A quién', t2: 'se le rompe el ingreso',
  img: 'img/s3_0.png', ar: 2200/3202,
  fx: 'Afectación económica = f ( actividad económica del distrito , sector del cliente )',
  filas: [
    ['Pesca', 'se cierra la temporada de anchoveta', 'IMARPE · PRODUCE'],
    ['Agricultura', 'se pierde la campaña', 'SINPAD · Censo 2017'],
    ['Ganadería', 'se pierde el pasto y el hato', 'SINPAD · Censo 2017'],
    ['Agroexportación', 'el calor impide la floración', 'ADEX · SENAMHI agroclimático'],
    ['Construcción', 'gana: la reconstrucción le da trabajo', 'MEF · BCRP']],
  kpis: [['1,45 M', 'hectáreas y 3,6 M de\ncabezas ya dañadas', VERDE],
         ['−57%', 'captura de anchoveta\nen El Niño costero', ROJO],
         ['1.891', 'distritos con PEA\npor rama, sin huecos']],
  ci: 'El multiplicador sectorial puede ser negativo.',
  sub: 'Un maestro de obra en Catacaos no es un cliente de mayor riesgo por el FEN: es uno de menor riesgo.  ·  La estructura productiva sale del Censo 2017, el último censo nacional: es la única fuente con los 1.891 distritos completos.'
});

// ============ 4 · REZAGO DE RECUPERACION ======================================================
{
  const s = pres.addSlide();
  base(s, 'Paso 4 · Rezago de recuperación', 'Cuánto tarda la zona', 'en volver');
  s.addImage({ path: 'img/s4_0.png', x: M, y: 2.15, w: 6.85, h: 6.85*733/2200 });
  s.addShape(pres.ShapeType.rect, { x: M+7.15, y: 1.72, w: 0.012, h: 3.9, fill: { color: SUAVE } });
  const x = M+7.45, w = W-M-x;
  formula(s, 'Rezago = f ( consumo observado , su propia tendencia )', x, 1.74, w);
  s.addText([{ text: 'Signo ' }, { text: 'positivo = peor', options: { bold: true, color: TINTA } },
    { text: ', igual que los otros dos mapas: mide cuánto le falta a la zona para volver a donde estaba.' }],
    { x, y: 2.22, w, h: 0.5, fontFace: TXT, fontSize: 10.5, color: GRIS, lineSpacing: 14 });
  rotulo(s, 'Tres lecturas del mismo dato', x, 2.82, w);
  s.addTable([
    [{ text: 'Variación absoluta' }, { text: 'no cae nunca', options: { bold: true, color: TINTA, align: 'right' } },
     { text: 'falso negativo', options: { color: ROJO, bold: true, align: 'right', fontSize: 8.5 } }],
    [{ text: 'Contra el nacional' }, { text: 'sube', options: { bold: true, color: TINTA, align: 'right' } },
     { text: 'señal invertida', options: { color: ROJO, bold: true, align: 'right', fontSize: 8.5 } }],
    [{ text: 'Contra su propia tendencia', options: { bold: true, color: TINTA } },
     { text: '−0,75 pp', options: { bold: true, color: TINTA, align: 'right' } },
     { text: 'la válida', options: { color: VERDE, bold: true, align: 'right', fontSize: 8.5 } }]
  ], { x, y: 3.26, w, colW: [w*0.46, w*0.28, w*0.26], rowH: 0.34, ...TB });
  callout(s, [{ text: 'Piura durante Yaku subió. ', options: { bold: true } },
    { text: 'Lo que crece —construcción, materiales, reposición— está bancarizado; lo que cae —pesca artesanal, agricultura de secano, comercio informal— no lo está. El índice mide la mitad que se beneficia.' }],
    x, 4.44, w, 1.0);
  s.addText([{ text: 'Y ese repunte es gasto financiado: parece recuperación y es apalancamiento. ', options: { bold: true, color: TINTA } },
    { text: 'Por eso entra como rezago, no como alivio.' }],
    { x, y: 5.52, w, h: 0.5, fontFace: TXT, fontSize: 9.5, color: CLARO, lineSpacing: 12 });
  cierre(s, 'Índice de consumo IBK+, var. % real mensual por departamento.',
    'Ene-2022 a jun-2026, 12 de 25 departamentos — sin Tumbes. La tendencia propia se estima con SARIMA sobre el nivel. Cobertura completa alternativa: Indicador de Actividad Productiva Departamental del INEI o la síntesis regional del BCRP.');
}

// ============ 5 · UBICACION ====================================================================
{
  const s = pres.addSlide();
  base(s, 'Ubicación del cliente', 'Admisión por distrito,', 'stock por punto');
  const w = (W-2*M-0.7)/2, x2 = M+w+0.7;
  s.addShape(pres.ShapeType.rect, { x: M+w+0.35, y: 1.74, w: 0.012, h: 4.0, fill: { color: SUAVE } });
  s.addText('Admisión — el lead', { x: M, y: 1.74, w, h: 0.32, fontFace: TIT, fontSize: 15, color: TINTA });
  formula(s, 'Ubicación = f ( nombre del distrito )', M, 2.16, w);
  s.addText([{ text: '98,08%', options: { bold: true, color: TINTA } },
    { text: ' por RENIEC. El domicilio es el del DNI y no hay punto para un tercio de la población de campaña.' }],
    { x: M, y: 2.66, w, h: 0.55, fontFace: TXT, fontSize: 11, color: GRIS, lineSpacing: 15 });
  s.addText([{ text: 'La decisión de admisión —otorgar, línea, plazo y precio— ' },
    { text: 'no requiere más precisión que el distrito', options: { bold: true, color: TINTA } }, { text: '.' }],
    { x: M, y: 3.28, w, h: 0.6, fontFace: TXT, fontSize: 10, color: CLARO, lineSpacing: 13 });
  s.addText('Stock — el cliente', { x: x2, y: 1.74, w, h: 0.32, fontFace: TIT, fontSize: 15, color: TINTA });
  formula(s, 'Ubicación = f ( latitud , longitud )', x2, 2.16, w);
  s.addText([{ text: '75,88%', options: { bold: true, color: TINTA } },
    { text: ' con punto censal. Foto 2017, cae 0,4 pp por mes.' }],
    { x: x2, y: 2.66, w, h: 0.3, fontFace: TXT, fontSize: 11, color: GRIS });
  [['a · El radio se mide desde el cauce', 'micro = f ( distancia al cauce , altura sobre el cauce )',
    'No es un círculo alrededor del cliente: es una franja a lo largo del cauce que se activa. Menos de 500 m y menos de 10 m de altura sobre él → corredor. Hasta 2 km y 25 m → interpolado. Fuera → promedio del distrito.'],
   ['b · Qué cauce, y cuándo cuenta', 'cauce = f ( punto ) · peso = f ( atribución El Niño de su cuenca )',
    'La quebrada es la unidad correcta, no la cuenca: la cuenca es 2,7× más grande que el distrito y no discrimina. La cuenca entra sólo como peso —cuánto de su daño ocurre en años El Niño— no como ubicación.']
  ].forEach(([t, f, d], i) => {
    const y = 3.12 + i*1.36;
    s.addShape(pres.ShapeType.rect, { x: x2, y, w: 0.032, h: 1.16, fill: { color: VERDE } });
    s.addText(t, { x: x2+0.16, y: y-0.04, w: w-0.2, h: 0.28, fontFace: TIT, fontSize: 11.5, color: TINTA });
    s.addText(f, { x: x2+0.16, y: y+0.24, w: w-0.2, h: 0.24, fontFace: MONO, fontSize: 9, color: VERDE });
    s.addText(d, { x: x2+0.16, y: y+0.5, w: w-0.2, h: 0.66, fontFace: TXT, fontSize: 9.5, color: GRIS, lineSpacing: 12 });
  });
  cierre(s, 'El total del distrito no cambia: el punto sólo redistribuye adentro.',
    'Falta el punto en 25% de las zonas de riesgo alto contra 16% en Lima; sin esa regla el overlay sería más preciso en Lima que en Piura.');
}

// ============ 6 · EL RADIO =====================================================================
{
  const s = pres.addSlide();
  base(s, 'Ubicación del stock · cómo se define el radio', 'El radio se mide', 'desde el cauce');
  const mw = 2.55, mh = mw*1808/1320;
  [['San Juan de Lurigancho', 'valle andino · 188 a 2.184 m', 'img/s6_0.png', M],
   ['Olmos', 'llanura costera · −4 a 1.157 m', 'img/s6_1.png', M+2.95]].forEach(([t, u, im, x]) => {
    s.addText(t, { x, y: 1.72, w: 2.8, h: 0.26, fontFace: TIT, fontSize: 12.5, color: TINTA });
    s.addText(u.toUpperCase(), { x, y: 1.98, w: 2.8, h: 0.2, fontFace: TXT, fontSize: 7.5, bold: true, color: GRIS, charSpacing: 1.4 });
    s.addImage({ path: im, x, y: 2.24, w: mw, h: mh });
  });
  s.addShape(pres.ShapeType.rect, { x: M+5.75, y: 1.72, w: 0.012, h: 4.1, fill: { color: SUAVE } });
  const x = M+6.05, w = W-M-x;
  rotulo(s, 'La función', x, 1.72, w);
  formula(s, 'micro = f ( distancia al cauce , altura sobre el cauce )', x, 2.12, w);
  s.addText([{ text: 'No es un círculo alrededor del cliente. Es una ' },
    { text: 'franja a lo largo del cauce que se activa', options: { bold: true, color: TINTA } },
    { text: ', y dentro de ella sólo lo que está ' }, { text: 'a la altura del agua', options: { bold: true, color: TINTA } },
    { text: '. El radio se ancla en el cauce, que es el origen del peligro, no en la población.' }],
    { x, y: 2.6, w, h: 0.72, fontFace: TXT, fontSize: 10, color: GRIS, lineSpacing: 13 });
  rotulo(s, 'Cuánto del distrito queda marcado', x, 3.4, w);
  const cw = [w*0.5, w*0.25, w*0.25];
  s.addTable([
    [th(''), th('Lurigancho'), th('Olmos')],
    [{ text: 'Lo que marca la cuenca' }, { text: '100%', options:{bold:true,color:TINTA,align:'right'} }, { text: '100%', options:{bold:true,color:TINTA,align:'right'} }],
    [{ text: '≤ 10 m sobre el cauce' }, { text: '6,6%', options:{bold:true,color:TINTA,align:'right'} }, { text: '68,0%', options:{bold:true,color:TINTA,align:'right'} }],
    [{ text: '≤ 500 m del cauce' }, { text: '2,7%', options:{bold:true,color:TINTA,align:'right'} }, { text: '5,3%', options:{bold:true,color:TINTA,align:'right'} }],
    [{ text: 'El corredor', options:{bold:true,color:TINTA} }, { text: '1,7%', options:{bold:true,color:VERDE,align:'right'} }, { text: '4,9%', options:{bold:true,color:VERDE,align:'right'} }],
    [{ text: 'en km²', options:{fontSize:8.5,color:CLARO} }, { text: '2,5 de 142', options:{fontSize:8.5,color:CLARO,align:'right'} }, { text: '263 de 5.370', options:{fontSize:8.5,color:CLARO,align:'right'} }]
  ], { x, y: 3.84, w, colW: cw, rowH: 0.28, ...TB });
  // leyenda comun a los dos mapas
  const LEY = [['A8140F','el corredor · cumple las dos'],['FFB347','cerca del cauce pero por encima del agua'],
    ['FFE9B8','a la altura del agua pero lejos del cauce'],['0B4D8F','cauce'],['CFE0F2','distrito · lo que marca la cuenca'],
    ['FFFFFF','radio referencial sobre el cauce']];
  LEY.forEach((L, i) => {
    const lx = M + (i%3)*1.9, ly = 5.86 + Math.floor(i/3)*0.26;
    s.addShape(pres.ShapeType.rect, { x: lx, y: ly+0.045, w: 0.11, h: 0.11, fill: { color: L[0] },
      line: L[0]==='FFFFFF' ? { color: '111111', width: 0.75, dashType: 'dash' } : { color: L[0], width: 0.25 } });
    s.addText(L[1], { x: lx+0.18, y: ly, w: 1.72, h: 0.2, fontFace: TXT, fontSize: 7.5, color: GRIS });
  });
  callout(s, [{ text: 'Por eso van las dos condiciones. ', options: { bold: true } },
    { text: 'En el valle manda la altura: el radio solo sobre-marca 35%. En la llanura manda el radio: la altura casi no filtra —el 68% del distrito está a nivel del cauce— y sobre-marca 7%.' }],
    x, 5.5, w, 0.78);
  cierre(s, 'Cauces y bordes distritales de OpenStreetMap; altitud de SRTM 30 m.',
    'Malla de 336 × 307 m en Lurigancho y 1.847 × 1.757 m en Olmos. El borde de Olmos calza con el INEI (5.358 contra 5.361 km²); el de Lurigancho encierra 142 km² contra los 131 km² publicados.');
}

// ============ 7 · EJEMPLO NUMERICO =============================================================
{
  const s = pres.addSlide();
  base(s, 'Ejemplo · de punta a punta', 'El mismo distrito,', 'distinto cliente');
  const w = W-2*M;
  const hd = ['perfil', 'PD\ncalibrada', 'daño\nfísico', 'afectación\neconómica', 'rezago de\nrecuperación', 'ajuste\ntotal', 'PD hoy\nagosto · 18%', 'PD en\nene-abr · 100%'];
  const fil = [
    ['Chimbote · pescador', '7,5%', '+2,36', '+1,50', '+0,20', '+0,49', '8,70%', '16,04%'],
    ['Chimbote · empleado público', '7,5%', '+2,36', '0,00', '+0,20', '+0,34', '8,58%', '14,96%'],
    ['Catacaos · comerciante con local', '6,0%', '+2,10', '+1,00', '+0,40', '+0,41', '6,96%', '12,89%'],
    ['San Isidro · empleado', '3,0%', '−1,66', '0,00', '−0,10', '−0,24', '3,29%', '4,93%']];
  const cw = [w*0.26].concat([0.098,0.088,0.104,0.108,0.088,0.113,0.121].map(f => w*f));
  s.addTable([hd.map((t, i) => ({ text: t, options: { fontFace: TXT, fontSize: 8, bold: true, color: i>=6?TINTA:GRIS,
      align: i ? 'right' : 'left', charSpacing: 1.2, valign: 'bottom',
      border: [{type:'none'},{type:'none'},{pt:1.4,color:TINTA},{type:'none'}] } }))]
    .concat(fil.map(f => f.map((c, i) => ({ text: c, options: {
      align: i ? 'right' : 'left', bold: i===0 || i>=6, fontSize: i>=6 ? 12 : 10.5,
      color: i>=7 ? VERDE : TINTA } })))),
    { x: M, y: 1.82, w, colW: cw, rowH: 0.56, ...TB, fontSize: 10.5, color: TINTA });
  [['Mismo distrito, distinto sector.', 'En Chimbote el pescador termina en 16,04% y el empleado público en 14,96%: el sector explica 1,1 puntos.'],
   ['El peso del mes manda.', 'Hoy el movimiento es chico porque en agosto sólo conocemos el 18% del escenario. En temporada se aplica completo.'],
   ['Todos suben, a distinta velocidad.', 'San Isidro también sube porque el escenario mueve la PD del banco; lo que reparte el score es cuánto más, no la dirección.']
  ].forEach(([b, t], i) => {
    const x = M + i*(w/3);
    s.addShape(pres.ShapeType.rect, { x, y: 4.86, w: w/3-0.35, h: 0.028, fill: { color: TINTA } });
    s.addText([{ text: b+' ', options: { bold: true, color: TINTA } }, { text: t }],
      { x, y: 5.02, w: w/3-0.35, h: 1.1, fontFace: TXT, fontSize: 11, color: GRIS, lineSpacing: 15, valign: 'top' });
  });
  cierre(s, 'Los pesos del ejemplo son ilustrativos, no calibrados.',
    'Se estiman del spread observado entre zonas en 2017 y 2023, dentro de la caja que garantiza que el ajuste nunca se desborde.');
}

// ============ 8 · ROADMAP ======================================================================
{
  const s = pres.addSlide();
  base(s, 'Cronograma · agosto 2026', 'Roadmap', 'calibración × FEN');
  s.addImage({ path: 'img/s8_0.png', x: M, y: 1.7, w: W-2*M, h: (W-2*M)*492/2200 });
  const w1 = 7.05, x2 = M+w1+0.5;
  s.addShape(pres.ShapeType.rect, { x: M+w1+0.25, y: 4.5, w: 0.012, h: 1.6, fill: { color: SUAVE } });
  s.addTable([
    [th('frente'), th('arranque'), th('cierre'), th('háb.'), th('responsable')],
    [{ text: 'Framework calibración × FEN', options:{bold:true,color:VERDE} }, { text: 'lun 3 ago' },
     { text: 'vie 7 ago', options:{bold:true,color:VERDE} }, { text: '4', options:{bold:true,color:VERDE,align:'center'} }, { text: 'Carlos Acosta' }],
    [{ text: 'Calibración TC No Bank', options:{bold:true,color:VERDE} }, { text: 'lun 3 ago' },
     { text: 'lun 10 ago est.', options:{bold:true,color:VERDE} }, { text: '5', options:{bold:true,color:VERDE,align:'center'} }, { text: 'Carlos Acosta' }],
    [{ text: 'Adm VC Cash PP', options:{bold:true,color:TINTA} }, { text: 'lun 10 ago' },
     { text: 'vie 21 ago', options:{bold:true,color:TINTA} }, { text: '10', options:{bold:true,color:TINTA,align:'center'} }, { text: 'Carlos Acosta' }],
    [{ text: 'Adm TC Bank', options:{bold:true,color:TINTA} }, { text: 'lun 10 ago' },
     { text: 'vie 21 ago', options:{bold:true,color:TINTA} }, { text: '10', options:{bold:true,color:TINTA,align:'center'} },
     { text: 'Adrián Kashimirho · préstamos, estrategias' }],
    [{ text: 'Stock VC · PP y TC', options:{bold:true,color:TINTA} }, { text: 'mié 12 ago' },
     { text: 'mar 25 ago', options:{bold:true,color:TINTA} }, { text: '10', options:{bold:true,color:TINTA,align:'center'} }, { text: 'Carlos Acosta' }]
  ], { x: M, y: 4.40, w: w1, colW: [w1*0.29, w1*0.15, w1*0.17, w1*0.08, w1*0.31], rowH: 0.26, ...TB, fontSize: 9.5 });
  const w2 = W-M-x2;
  rotulo(s, 'Backlog de calibraciones · sin fecha', x2, 4.40, w2);
  s.addTable([
    [{ text: [{ text: 'IL New Bank\n', options:{bold:true,color:TINTA,fontSize:10.5} },
              { text: 'nunca se ha calibrado', options:{color:CLARO,fontSize:8.5} }] },
     { text: 'TBD', options:{bold:true,color:CLARO,align:'right',charSpacing:1.6} }],
    [{ text: [{ text: 'Comportamental BN\n', options:{bold:true,color:TINTA,fontSize:10.5} },
              { text: 'en evaluación', options:{color:CLARO,fontSize:8.5} }] },
     { text: 'TBD', options:{bold:true,color:CLARO,align:'right',charSpacing:1.6} }]
  ], { x: x2, y: 4.82, w: w2, colW: [w2*0.76, w2*0.24], rowH: 0.38, ...TB });
  callout(s, [{ text: 'El framework es la compuerta: si no cierra el viernes 7, no arranca nada el lunes 10. ', options: { bold: true } },
    { text: 'Con el feriado del jueves 6 quedan cuatro días hábiles para cerrarlo, no cinco.' }],
    x2, 5.68, w2, 0.62);
  cierre(s, 'Días hábiles de lunes a viernes; sábados y domingos sombreados en el eje.',
    'Diez hábiles por frente = dos semanas calendario; el framework son cuatro. Feriados del período: jueves 6 de agosto, que sí descuenta un hábil, y Santa Rosa el 30, que cae domingo.');
}

pres.writeFile({ fileName: 'FEN_metodologia_e2e.pptx' })
  .then(f => console.log('escrito:', f, '·', Math.round(fs.statSync(f).size/1024), 'KB ·', pres.slides.length, 'slides'));
