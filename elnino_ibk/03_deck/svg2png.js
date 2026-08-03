// Extrae los SVG del deck HTML y los rasteriza a PNG.
// Las clases .gk/.gm/.gn viven en el CSS del deck, no en el SVG: hay que volcarlas a atributos
// inline o el rasterizador las ignora. Y las tres tipografias del deck (Archivo, Nunito,
// JetBrains Mono) no estan instaladas en Windows: se sustituyen por Segoe UI y Consolas, que si.
const fs = require('fs');
const { Resvg } = require('@resvg/resvg-js');

const CLASES = {
  gn: "font-family:'Segoe UI';font-weight:900;font-size:22px;letter-spacing:-0.6px",
  gm: "font-family:'Segoe UI';font-weight:600;font-size:14px;letter-spacing:1.4px",
  gk: "font-family:'Segoe UI';font-weight:700;font-size:14px;letter-spacing:1.4px",
  gh: "paint-order:stroke;stroke:#fff;stroke-width:3.4px;stroke-linejoin:round",
  mp: "", gr: ""
};

function inline(svg){
  let s = svg.replace(/class="([^"]+)"/g, (m, cs) => {
    const st = cs.trim().split(/\s+/).map(c => CLASES[c] || '').filter(Boolean).join(';');
    return st ? 'style="'+st+'"' : '';
  });
  // el deck escribe los SVG dentro del HTML, donde el namespace es implicito; el rasterizador lo exige
  if (!/xmlns=/.test(s)) s = s.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ');
  return s;
}

const html = fs.readFileSync('deck_FEN_metodologia_e2e.html', 'utf8');
// Los mapas del Peru dibujan cada distrito con <use href="#mN"> contra un <defs> unico que el deck
// pone una sola vez al inicio del body. Extraido suelto, el SVG del mapa sale vacio: hay que
// reinyectarle ese bloque.
const DEFS = (html.match(/<defs>[\s\S]*?<\/defs>/) || [''])[0];

const secs = html.split('<section class="slide').slice(1);
const salida = [];
secs.forEach((sec, i) => {
  (sec.match(/<svg[\s\S]*?<\/svg>/g) || []).forEach((svg, j) => {
    let limpio = inline(svg);
    if (/<use /.test(limpio)) limpio = limpio.replace(/(<svg[^>]*>)/, '$1' + DEFS);
    const vb = limpio.match(/viewBox="0 0 ([\d.]+) ([\d.]+)"/);
    const w = vb ? +vb[1] : 900;
    const escala = Math.min(4, Math.max(2, 2200 / w));   // ~2200 px de ancho, tope 4x
    const r = new Resvg(limpio, {
      fitTo: { mode: 'width', value: Math.round(w * escala) },
      font: { defaultFontFamily: 'Segoe UI', loadSystemFonts: true },
      background: 'rgba(255,255,255,0)'
    });
    const png = r.render().asPng();
    const nombre = 'img/s'+(i+1)+'_'+j+'.png';
    fs.writeFileSync(nombre, png);
    const dim = r.render();
    salida.push({ slide: i+1, k: j, file: nombre, w: dim.width, h: dim.height, kb: Math.round(png.length/1024) });
  });
});
fs.mkdirSync('img', { recursive: true });
console.log(salida.map(o => `slide ${o.slide}.${o.k}  ${o.file}  ${o.w}x${o.h}  ${o.kb} KB`).join('\n'));
fs.writeFileSync('_img.json', JSON.stringify(salida));
