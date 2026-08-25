# Diccionario — `dataset_fen_cliente.parquet`

**1 fila por registro geocodificado** (llave `clave`). 1 737 089 filas · 59 columnas · R asignado 99.96%.
Generado desde el geocoding IBK + score FEN v6 + CENEPRED (susceptibilidad Unificado, gate Pacífico).

> **Al cruzar contra la cartera del banco:** unir por `clave` (dirección origen de los tramos). Si se une por ubigeo, OJO: **nuestro ubigeo es INEI**; el `cod_ubi_domicilio` de RENIEC está corrido (asigna Piura a Puno sin error) → usar el puente `t_mst_ubigeos_rsk`.

## Identidad / geo
| Columna | Descripción |
|---|---|
| `clave` | Llave = `ubigeo|direccion` origen. Join a la cartera. |
| `ubigeo_limpio` | Ubigeo INEI 6 dígitos. |
| `departamento`, `provincia`, `distrito_limpio` | Ubicación administrativa. |
| `cuenca` | Cuenca ANA (nombre o Intercuenca código). |
| `lon_final`, `lat_final` | Coordenadas WGS84 (X,Y) finales. |
| `fuente_xy_final` | Quién puso el punto: `arcgis` / `google`. |

## Precisión del geocoding
| Columna | Descripción |
|---|---|
| `radio_final` | Radio de error del punto (km). |
| `prec_m` | Radio en metros. |
| `prec_tier` | Tramo: `<=50m / 51-100m / 101-300m / 301-500m / 501-1000m / >1km`. |
| `flg_prec_p50 … pgt1k` | Flags exclusivos del tramo de precisión (1/0). |

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
| `n_eventos` | Nº de El Niños en que activó (de 10). |
| `pct_expuesto` | % población del distrito en zona de peligro CENEPRED. |
| `sev`, `rec`, `fra`, `exp_n` | Componentes del score (0–1): severidad, recurrencia, fragilidad, exposición. |
| `score` | Score total (0–4) → Fisher-Jenks → R. |
| `gate_cronica` | 1 = cuenca gateada por crónica (huaico andino, no FEN). |

## Eventos El Niño (activación por año, 1/0)
`a1983 a1987 a1992 a1998 a2016 a2017 a2023 a2024 a2026` — `a2026` = evento en curso.

## Impacto histórico 2017 (SINPAD, por distrito)
| Columna | Descripción |
|---|---|
| `dmg17_dam` | Damnificados 2017 (lo que alimenta la severidad). |
| `dmg17_afe` | Afectados 2017. |
| `dmg17_viv` | Viviendas dañadas 2017. |
| `dmg17_fall` | Fallecidos 2017. |

## Evidencia de prensa (por distrito)
| Columna | Descripción |
|---|---|
| `flg_prensa` | 1 = distrito con fuente periodística validada. |
| `news_estado` | Estado de validación (`CONFIRMADO_*`). |
| `news_url` | Link a la nota / reporte. |

## Flags de decisión — **PROPUESTOS, no finales**
> Regla recomendada; **validar contra mora/pérdida real antes de usar en pricing.**
| Columna | Definición |
|---|---|
| `prop_target_castigo` | 1 = preciso ≤300m **Y** ≤300m de Muy Alto **Y** distrito R4/R5 (cerca de peligro real, bien ubicado, zona severa). |
| `prop_alivio` | 1 = distrito R4/R5 **pero** a >1km de toda huella (`flg_ma_1000=0`) → "en distrito riesgoso pero fuera del peligro fino" → no castigar tanto. |

## Avisos de uso
1. Los `flg_ma_*` son distancia a **susceptibilidad CENEPRED (1:1M)**, no a huella validada → **usar siempre CON `R_nivel`** (que sí está validado con daño + prensa), nunca solos.
2. Mínimo sensato de distancia = **contención (`flg_dentro_ma`) / 100m**; por debajo la fuente 1:1M no da precisión real.
3. Las bandas de distancia solo son confiables donde el punto es preciso (`prec_m ≤ 300`).
