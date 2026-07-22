'use strict';
// Genera 2 SVG autonomos (solo mapa, sin titulo/leyenda, fondo transparente) para PPTX:
//   mapa_fen_v3.svg      -> R0-R5 (6 colores)
//   mapa_fen_grupos.svg  -> grupos consolidados G0/G1/G2/G3 (4 colores)
const fs = require('fs');
const M = JSON.parse(fs.readFileSync(__dirname + '/_slidemap_v3.json', 'utf8'));
const W = M.W || 540, H = M.H || 820;
// R0-R5
const COL6 = ['#e2e8ee', '#ffe2a8', '#ffbf6b', '#fb8c3c', '#ed5a25', '#b81e16'];
// grupos: G0 noPac(R0) / G1 Bajo(R1) / G2 Medio(R2-R3) / G3 Alto(R4-R5)
const COL4 = ['#e2e8ee', '#ffe2a8', '#fb8c3c', '#b81e16'];
const grp = r => (r <= 0 ? 0 : r === 1 ? 1 : (r <= 3 ? 2 : 3));
function build(colorOf) {
  let p = '';
  M.feats.forEach(f => { if (f.d) p += `<path d="${f.d}" fill="${colorOf(f.r)}" stroke="#ffffff" stroke-width="0.25"/>`; });
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}">${p}</svg>`;
}
fs.writeFileSync(__dirname + '/mapa_fen_v3.svg', build(r => COL6[r]));
fs.writeFileSync(__dirname + '/mapa_fen_grupos.svg', build(r => COL4[grp(r)]));
const c6 = [0, 0, 0, 0, 0, 0], c4 = [0, 0, 0, 0]; M.feats.forEach(f => { c6[f.r]++; c4[grp(f.r)]++; });
console.log('mapa_fen_v3.svg (R0-R5):', JSON.stringify(c6));
console.log('mapa_fen_grupos.svg (G0/G1/G2/G3):', JSON.stringify(c4));
