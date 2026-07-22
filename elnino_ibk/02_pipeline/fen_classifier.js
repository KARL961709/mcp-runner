'use strict';
/*
 * fen_classifier.js — FUENTE CANÓNICA ÚNICA del clasificador "El Niño costero (FEN)".
 * ------------------------------------------------------------------------------------
 * Coherente con 01_fuentes/sinpad/BUCKET_PELIGROS.md.
 *
 * Concepto FEN-lluvia (lo que cuenta como activación El Niño costero):
 *   lluvia intensa + sus consecuencias hidro-geomorfológicas:
 *   inundación (desborde río/canal/lago, aniego, saturación pluvial, defensa ribereña,
 *   ruptura de dique, embalse), flujos (huaico/aluvión/avenida torrencial), y
 *   movimientos de masa GATILLADOS por saturación/lluvia (deslizamiento, derrumbe de cerros).
 *
 * Se EXCLUYE por NO ser FEN-lluvia:
 *   - Frío: granizada, helada, nevada, friaje, descenso de temperatura, ola de frío.
 *   - Viento: vendaval, vientos fuertes, tormenta/tempestad eléctrica.
 *   - Mar: marejada, oleaje anómalo, maretazo, cambio de línea de costa
 *          (El Niño los causa, pero el GRADO se construye sobre lluvia/inundación, no oleaje).
 *   - Geológico "seco" / sísmico: derrumbe de rocas, reptación, erosión genérica,
 *          sedimentación, licuación.
 *   - Volcánico: lahar, ceniza, actividad volcánica.
 *   - Estructural: derrumbe de vivienda, colapso por antigüedad/actividad humana/biológico.
 *   - Sequía / déficit hídrico: va como MODO aparte (grado_sequia), nunca fusionado.
 *   - Otros: incendios, sismo, epidemia, accidente, plaga, contaminación.
 *
 * Dos vocabularios distintos => dos funciones, MISMA semántica:
 *   - isFEN_sinpad(peligroPrincipal)  -> SINPAD v3 (mayúsculas, "LLUVIAS INTENSAS"...)
 *   - isFEN_desinventar(evento)       -> DesInventar (capitalizado, "Inundación"...)
 */

// --- SINPAD: INUNDAC cubre desborde/canal/lago/saturación/defensa ribereña/diques ---
const FEN_SINPAD_RE = /LLUVIA|INUNDAC|HUAIC|HUAYC|ALUVI|ANIEGO|TEMPORAL|EROSION FLUVIAL|AGENTE CLIM|EMBALSE|DESLIZ|DERRUMBE CERRO/;
// Exclusiones explícitas (por si algún token genérico las rozara): rocas, reptación, lahar, estructural.
const FEN_SINPAD_EXCL = /DERRUMBE DE ROCA|REPTAC|LAHAR|DERRUMBE VIVIENDA|COLAPSO POR|COLAPSO DE ESTRUCTURA POR (ACTIVIDAD|AGENTE BIOL)/;

function isFEN_sinpad(p) {
  const s = String(p || '').toUpperCase();
  if (FEN_SINPAD_EXCL.test(s)) return false;
  return FEN_SINPAD_RE.test(s);
}

// --- DesInventar: Aluvi=Aluvión(Huayco), Avenida=Avenida torrencial ---
const FEN_DESINV_RE = /Inundaci|Lluvia|Aluvi|Huayco|Deslizamiento|Avenida/i;
// NO incluir: Alud (avalancha de nieve), Marejada, Vendaval, Tormenta, Granizada, Erosi, Sedimentaci, Licuaci.

function isFEN_desinventar(e) {
  return FEN_DESINV_RE.test(String(e || ''));
}

module.exports = { isFEN_sinpad, isFEN_desinventar, FEN_SINPAD_RE, FEN_DESINV_RE };
