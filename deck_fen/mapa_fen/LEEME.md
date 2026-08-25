# Mapa FEN 2026 — cómo abrirlo

El mapa necesita un **servidor local** (carga los puntos lote por distrito con `fetch()`, que el navegador bloquea si abres el HTML con doble clic directo).

## Opción 1 (recomendada)
Clic derecho en **`abrir_mapa.ps1`** → *Ejecutar con PowerShell*. Se abre el navegador solo. Deja la ventana negra abierta mientras lo usas.

## Opción 2 (manual)
En esta carpeta, en una terminal:
```
python -m http.server 8799
```
Luego abre: http://localhost:8799/mapa_fen2026_cuencas.html

## Qué contiene el mapa
- **Peligro FEN** (Unificado / Inundación / Mov. masa, CENEPRED, gate Pacífico) + cuencas, subcuencas, curvas de nivel, distritos con nombre.
- **Selector** Departamento → Provincia → Distrito + **filtro Score FEN (R0–R5)**.
- **Densidad de direcciones IBK** por precisión (≤300m / ≤500m / ≤1km / >1km) y **puntos lote individuales** por distrito.
- **Ficha por distrito**: componentes del score, composición de direcciones (≤300m y proximidad a Muy Alto/Alto), impacto El Niño 2017, evidencia de prensa.
- Zoom al centro/cursor, tarjeta minimizable, tema oscuro Interbank.

## Archivos
- `mapa_fen2026_cuencas.html` — el mapa.
- `fen_*.png` — capas de peligro (base). `ibk_*.png` — densidad de direcciones.
- `ibk_pts/` — puntos lote por distrito (1 archivo `.bin` por ubigeo).

**Datos internos IBK — uso interno.**
