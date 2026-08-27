# Diccionario — `dataset_fen_cliente.parquet` (MAESTRO)

**1 fila por registro geocodificado** (llave `clave`). **1 737 089 filas · 75 columnas** · R asignado 99.96%.
Generado desde el geocoding IBK + score FEN v6 + CENEPRED (susceptibilidad Unificado, gate Pacífico) + direcciones limpias + flags de segmentación.

> **Al cruzar contra la cartera del banco:** unir por `clave` (dirección origen de los tramos). Si se une por ubigeo, OJO: **nuestro ubigeo es INEI**; el `cod_ubi_domicilio` de RENIEC está corrido (asigna Piura a Puno sin error) → usar el puente `t_mst_ubigeos_rsk`.
>
> **Tipos:** los campos de score (`sev, rec, fra, exp_n, score, pct_expuesto, n_eventos, pacifico, gate_cronica`) son **numéricos** en esta versión (antes eran texto).

## Identidad / geo
| Columna | Descripción |
|---|---|
| `clave` | Llave = `ubigeo\|direccion` origen. Join a la cartera. |
| `ubigeo_limpio` | Ubigeo INEI 6 dígitos. |
| `departamento`, `provincia`, `distrito_limpio` | Ubicación administrativa. |
| `cuenca` | Cuenca ANA (nombre o Intercuenca código). |
| `lon_final`, `lat_final` | Coordenadas WGS84 (X,Y) finales. |
| `fuente_xy_final` | Quién puso el punto: `arcgis` / `google`. |

## Dirección limpia (del geocoding cascada)
| Columna | Descripción |
|---|---|
| `direccion_limpia` | Dirección normalizada usada para geocodificar. |
| `departamento_limpio`, `provincia_limpio` | Admin limpios (origen cascada). |
| `manzana_limpio` | Manzana normalizada (si venía en la dirección). |
| `tramo` | Nº de lote/chunk del proceso de geocoding. |
| `direccion_util` | bool: la dirección tenía info útil para geocodificar. |

## Precisión del geocoding
| Columna | Descripción |
|---|---|
| `radio_final` | Radio de error del punto (km). |
| `prec_m` | Radio en metros. |
| `prec_tier` | Tramo: `<=50m / 51-100m / 101-300m / 301-500m / 501-1000m / >1km`. |
| `flg_prec_p50 … pgt1k` | Flags exclusivos del tramo de precisión (1/0). |
| `preciso` | 1 = `prec_m ≤ 300` (usable para decisión de distancia). |

## Proximidad a peligro (Unificado = MAX inundación, mov. masa; gate Pacífico)
> Distancia euclidiana en metros (UTM 18S). Contención = distancia 0 = dentro de la celda.
| Columna | Descripción |
|---|---|
| `dist_ma_m` | Metros a la celda **Muy Alto** más cercana. |
| `dist_am_m` | Metros a la celda **Alto+Muy Alto** más cercana. |
| `flg_ma_100/300/500/1000` | 1 si el punto está a ≤X m de **Muy Alto** (acumulativo). |
| `flg_am_100/300/500/1000` | Igual, para **Alto+Muy Alto**. |
| `flg_dentro_ma` | 1 = punto **dentro** de zona Muy Alto (señal fina más defendible). |
| `flg_dentro_alto` | 1 = punto dentro de Alto+Muy Alto. |

## Grado FEN + score (por distrito)
| Columna | Descripción |
|---|---|
| `R_nivel` | Grado FEN-costero `R0`–`R5` (R0 = no-Pacífico). |
| `pacifico` | 1 = vertiente Pacífico (gate del score). |
| `patron_evento` | `persistente` / `reciente_solo` / `cronica` / `sin_eventos` / `no_pac`. |
| `n_eventos` | Nº de El Niños en que activó. |
| `pct_expuesto` | % población del distrito en zona de peligro CENEPRED. |
| `sev`, `rec`, `fra`, `exp_n` | Componentes del score (0–1). **`fra` = actividad reciente, no fragilidad socioeconómica.** |
| `score` | Score total (0–4) → Fisher-Jenks → R. |
| `gate_cronica` | 1 = cuenca gateada por crónica (huaico andino, no FEN). |

## Eventos El Niño (activación por año, 1/0)
`a1983 a1987 a1992 a1998 a2016 a2017 a2023 a2024 a2026` — `a2026` = evento en curso.
> Daño distrital solo existe para 2017 (BD INDECI 2003-2020); 2023/24 solo aportan activación.

## Impacto histórico 2017 (INDECI/SINPAD, por distrito)
| Columna | Descripción |
|---|---|
| `dmg17_dam` | Damnificados 2017 (alimenta la severidad). |
| `dmg17_afe` | Afectados 2017. |
| `dmg17_viv` | Viviendas dañadas 2017. |
| `dmg17_fall` | Fallecidos 2017. |
| `viv2017_distrito` | Parque de viviendas 2017 del distrito (shp CENEPRED). |
| `dano_pct_distrito` | `dmg17_viv / viv2017_distrito` × 100 (proxy de daño histórico). |

## Evidencia de prensa (por distrito)
| Columna | Descripción |
|---|---|
| `flg_prensa` | 1 = distrito con fuente periodística validada. |
| `news_estado` | Estado de validación (`CONFIRMADO_*`). |
| `news_url` | Link a la nota / reporte. |

## Segmentación de propuesta (R4/R5) — **PROPUESTA, no final**
> Regla recomendada; **validar contra mora/pérdida real antes de usar en pricing.** Solo aplica al universo R4/R5 (sacado de campaña); `no_aplica` para el resto.
| Columna | Definición |
|---|---|
| `segmento_fen` | `liberar` / `precio_dif` / `retener_nucleo` / `retener_llano` / `sin_dato` / `no_aplica` |
| `prop_liberar` | 1 = preciso ∧ dist_ma>500 ∧ **fuera de Alto** → reingreso pleno (12 127). |
| `prop_precio` | 1 = preciso ∧ dist_ma>500 ∧ en Alto ∧ **daño distrito <4%** → precio diferenciado (21 809). |
| `prop_retener` | 1 = preciso en núcleo (≤500m Muy Alto) o llano peligroso (daño ≥4%) (153 780). |
| `prop_sindato` | 1 = localidad (`prec_m>300`), no decidible (110 813). |
| `liberable_grado` | Variante por grado: R5 fuera de Muy Alto+Alto / R4 fuera de Muy Alto (59 171). |
| `liberable_fuera_ambos` | 1 = preciso ∧ fuera de Muy Alto **y** Alto (contención simple). |
| `prop_target_castigo`, `prop_alivio` | Flags preliminares anteriores (**superados** por `segmento_fen`). |

## Avisos de uso
1. Los `flg_ma_*` son distancia a **susceptibilidad CENEPRED (1:1M)**, no a huella validada → **usar siempre CON `R_nivel`**, nunca solos.
2. Mínimo sensato de distancia = **contención (`flg_dentro_ma`)**; por debajo de ~300 m la fuente 1:1M no da precisión real.
3. Las bandas de distancia solo son confiables donde el punto es preciso (`prec_m ≤ 300`).
4. `dano_pct_distrito` de distritos capital (p.ej. Trujillo) puede venir inflado → auditar outliers antes de usar como gate absoluto.
