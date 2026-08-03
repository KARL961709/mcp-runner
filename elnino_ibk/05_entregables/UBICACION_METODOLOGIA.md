# Ubicación del cliente: metodología de inicio a fin

**Alcance:** cómo se localiza a cada cliente y a cada lead, con qué precisión, y cómo se traduce eso
en el estrés que recibe. Toda cifra de cobertura está medida sobre el corte 202607.

---

## 1. Punto de partida: qué sabemos de dónde está cada persona

| fuente | admisión | stock | qué entrega |
|---|---|---|---|
| `t_dim_cliente.ubigeo_cd` | 67,85% | **100%** | ubigeo INEI, por **código** |
| `t_mst_reniec_rsk` | **98,08%** | 98,36% | departamento / provincia / distrito, por **nombre** |
| `t_agg_censo_enrich_rsk` | 67,24% | **75,88%** | **latitud, longitud e `id_mzna`** |
| direcciones (apicliente, registro maestro) | 31,78% | 47,81% | texto; **coordenadas 100% nulas** |

Tres hechos que condicionan todo el diseño:

1. **Ninguna tabla de dirección del banco tiene coordenadas.** El censo es la única fuente de punto.
2. **El punto censal es una foto de 2017 y se degrada 0,4 pp por mes** (77,08% en 202604 → 75,85% en 202607).
3. **La cobertura de punto no es uniforme:** falta en **25% de las zonas de riesgo FEN alto** contra
   **16% en Lima**.

---

## 2. La asimetría entre admisión y stock

### Admisión — mapa distrital

El lead se localiza por **nombre** vía RENIEC, con 98,08% de cobertura. El domicilio es el del DNI.
No hay punto para un tercio de la población de campaña, y de todos modos la decisión de admisión
—otorgar, con qué línea, plazo y precio— no requiere más precisión que el distrito.

> **Para admisión el grano es y debe ser distrital.**

*Defecto a corregir:* las consultas actuales cruzan por **nombre normalizado** (`dep`+`prov`+`dist`).
Perú tiene ocho provincias con un distrito llamado Santa Rosa. En stock, teniendo `ubigeo_cd` al 100%,
**el cruce debe ser por código**.

### Stock — sí tenemos la ubicación

Para **75,88% del stock** existe el punto censal con latitud, longitud e `id_mzna`. Ese es el insumo
que permite refinar dentro del distrito.

*Nota técnica:* `id_mzna` es entero del INEI y el campo `manzana` de apicliente es texto libre
("Mz A"). **No cruzan por código.** El puente entre el cliente y cualquier capa geográfica es el
**punto**, no el código de manzana.

---

## 3. La escalera de precisión: qué se puede hoy y qué desbloquea cada paso

### Nivel 0 · Distrito — operativo hoy

1.891 unidades. Cobertura 100% en stock, 98,08% en admisión. **Es el grano de decisión.**

### Nivel 1 · Centro poblado — desbloqueable con una fuente pública

| | |
|---|---|
| unidades | **77.916 centros poblados** con nivel de exposición FEN oficial de CENEPRED |
| resolución | mediana de **30 por distrito**, p75 de 54, máximo 355 |
| espaciamiento típico | **~4,8 km** |
| ganancia | **42× más fino** que distrito |
| distribución | 1.469 en *Muy alto* (826 mil personas) · 5.533 en *Alto* (4,85 M) |

**Lo que falta:** el archivo de CENEPRED trae el **código de centro poblado en formato INEI**
(`0101010008` = ubigeo de 6 + correlativo de 4) **pero no trae coordenadas**. El directorio de
centros poblados del INEI sí las tiene y es público.

**Cómo se construyen las zonas.** Con las coordenadas de los centros poblados:

```
1 · Polígonos de Voronoi sobre los centros poblados del distrito
2 · Recorte de cada polígono al límite distrital
3 · Cada punto de cliente cae en exactamente un polígono
4 · El cliente hereda el nivel de exposición FEN de ese centro poblado
```

Voronoi porque es el método estándar para convertir una capa de puntos en zonas sin superposición ni
huecos, y porque el recorte al distrito preserva la restricción de suma de la sección 4. Con
espaciamiento típico de 4,8 km, el polígono medio queda en el orden de 20 km² — dentro del rango en
que la exposición a inundación es homogénea en llanura, no en ladera.

### Nivel 2 · El corredor del cauce — probado, y es el correcto

Lo que determina si un lote se inunda es la **distancia al cauce** y la **altura sobre él**, no la
pertenencia a una zona. El radio no es un círculo alrededor del cliente: es una **franja a lo largo
del cauce que se activa**.

```
micro = f ( distancia al cauce , altura sobre el cauce )
```

| | corredor | interpolado | fuera |
|---|---|---|---|
| distancia al cauce | ≤ 500 m | ≤ 2 km | > 2 km |
| altura sobre el cauce | ≤ 10 m | ≤ 25 m | > 25 m |

**Prueba de concepto sobre San Juan de Lurigancho** (malla de 336 × 307 m, 1.374 celdas dentro del
distrito). Cauces y borde distrital de OpenStreetMap; elevación SRTM 30 m en 1.671 puntos:

| filtro | celdas | % del distrito |
|---|---|---|
| todo el distrito | 1.374 | 100% |
| **cuenca asignada (Rímac)** | **1.374** | **100%** |
| altura sobre el cauce ≤ 10 m | 90 | 6,6% |
| distancia al cauce ≤ 500 m | 37 | 2,7% |
| **los dos · el corredor** | **24** | **1,7%** |

> **La cuenca marca el 100% del distrito y no discrimina nada. El corredor marca 1,7%: un factor de 57×.**

**Por qué hacen falta las dos condiciones.** De las 37 celdas a menos de 500 m del cauce, **13 están
más de 10 m por encima** y no se inundan: la distancia sola sobre-marca **35%**. SJL va de **188 a
2.184 m** de altitud dentro del mismo distrito.

**Los cauces de SJL son el Río Rímac** (su borde sur) **y la Quebrada Huaycoloro**, que OSM marca
`intermittent=yes` —seca casi todo el año— y es la que bajó en 2017 sobre Campoy y Zárate.

**Limitaciones reconocidas de la prueba:**
- La altura se mide contra el **punto de cauce más cercano**, no contra el cauce al que la celda
  realmente drena. Es una aproximación al HAND; explica parte de las 66 celdas «bajas pero lejos».
  No afecta al corredor, que exige las dos condiciones.
- OSM tiene la Huaycoloro pero **la cobertura de quebradas menores en Perú es despareja**. La fuente
  de producción debe ser la **red hidrográfica del ANA** (pedido 2 de la sección 6).
- SRTM 30 m es grueso para un umbral de 10 m en terreno llano.
- Los **1.122 puntos críticos** de CENEPRED/ANA —que dirían *qué* cauce se activa— traen nombre de
  río y paraje **sin coordenadas**.

### Nivel 3 · Manzana — no se recomienda

Precisión de manzana sobre una foto de 2017 que decae 0,4 pp por mes, con parámetros del modelo
todavía declarados. Es precisión en el extremo equivocado.

---

## 4. Por qué la cuenca NO es un camino de refinamiento

Es la confusión más natural del diseño y conviene dejarla cerrada:

| | medido |
|---|---|
| área mediana de cuenca | **1.848 km²** |
| área mediana de distrito | **~680 km²** |
| relación | la cuenca es **2,7× más grande** |
| distritos que tocan más de una cuenca | **78%** de la muestra evaluada |

> **La cuenca aporta el techo de severidad —cuánto daño puede producir un evento en ese sistema
> hidrográfico— no la ubicación fina.** Va en dirección contraria a la granularidad.

*Reserva técnica levantada en revisión:* la unidad de atribución hidrológicamente correcta para el
huaico no es la cuenca sino la **microcuenca de quebrada** (5–50 km², pendiente superior a 15%), y la
inundación ocurre en el **abanico aluvial de piedemonte**, que es una unidad geomorfológica. Una
unidad hidrográfica de 1.848 km² promedia ambas hasta borrarlas, y además funde tres regímenes de
altitud (0 a 4.800 m). Es una limitación reconocida de la versión actual.

---

## 5. Cómo el refinamiento entra al estrés

La regla, y la razón de que exista:

```
ΔPD_distrito   ←  lo fija el modelo                                    [ INVARIANTE ]
ΔPD_cliente    ←  el refinamiento redistribuye ese total dentro del distrito,
                  con  Σ ponderada dentro del distrito = ΔPD_distrito
```

| población | qué recibe |
|---|---|
| **admisión** (sólo distrito) | el valor distrital, sin sesgo |
| **stock con punto** (75,88%) | valor refinado que **suma al mismo total distrital** |
| **stock sin punto** (24,12%) | el promedio del distrito; no se le inventa precisión |

**Corrección incorporada tras revisión matemática.** La restricción de suma fija el **primer momento**
—elimina deriva de nivel— pero **no iguala la precisión** entre un distrito con 84% de cobertura y uno
con 75%. Y el 24% sin punto no falta al azar: dentro del distrito faltan los ribereños e informales,
es decir la cola. Por eso el refinamiento se **encoge según la cobertura del distrito**:

```
r̃_i  =  1 + B_d · ( r_i − 1 )        con  B_d  creciente en la cobertura de punto del distrito
```

Un distrito con poca cobertura refina menos, no refina igual de confiado.

---

## 6. Qué se pide y a quién

| # | pedido | a quién | desbloquea |
|---|---|---|---|
| 1 | Directorio de centros poblados con coordenadas | INEI (público) | **nivel 1 completo** |
| 2 | Red hidrográfica y puntos críticos georreferenciados | ANA | nivel 2 |
| 3 | Cambiar el cruce de nombre a `ubigeo_cd` en las consultas de stock | interno | corrige fragilidad actual |

Sólo el punto 1 es necesario para el siguiente paso; los otros dos son mejoras posteriores.
