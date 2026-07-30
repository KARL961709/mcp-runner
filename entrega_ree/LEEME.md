# Calibración PD — Comportamental Préstamo Personal Reenganche

Entrega completa: datos de entrada, cadena de cálculo, resultados, reportes y
documento metodológico.

---

## Cómo se ejecuta

```
cd Programas
python Ejecutar.py
```

Opciones:

| opción | efecto |
|---|---|
| `--sin-reportes` | corre la cadena sin generar los Excel |
| `--sin-macro` | omite la selección de variable macro (~30 s) |
| `--hasta 06` | corta después del paso indicado |

El orquestador fija por sí mismo las rutas de datos, resultados y reportes, de
modo que la carpeta es movible: no hay rutas absolutas que ajustar.

---

## Qué hay en cada carpeta

| carpeta | contenido |
|---|---|
| `Data/` | los dos insumos: el maestro de calibración y el parquet macro |
| `Programas/` | `Ejecutar.py` (orquestador) y el código |
| `Programas/pipeline/` | los pasos que producen la PD, en orden 00 a 11 |
| `Programas/src/` | módulos compartidos: configuración, calibración, Vasicek, métricas, monitoreo |
| `Programas/reportes/` | generadores de los Excel, **separados de la cadena a propósito** |
| `Programas/analisis/` | selección de variable macro y los contrastes entre calibradores |
| `Programas/sql/` | las consultas que construyen el maestro en Athena (no se ejecutan aquí) |
| `Resultados/` | salidas de la corrida: json, csv, parquets, gráficos y el log de cada paso |
| `Reportes/` | los Excel entregables |
| `doc/` | documento metodológico (`.tex` y `.pdf`), sus figuras y el detalle de la cadena SQL |
| `config/` | bitácora de acuerdos, ledger de parámetros, margen de conservadurismo y fichas de filtros |

La separación entre `pipeline/` y `reportes/` es deliberada: la cadena calcula la
PD y los reportes sólo la presentan. Un cambio en un Excel no puede alterar un
coeficiente, y el flujo corre completo con `--sin-reportes`.

---

## Orden de la cadena

```
00 carga y partición        →  01 RD histórica y LRA      →  02 correlación ρ
   ↓
selección de variable macro →  03 modelo macro y factor    →  04 BetaCal y anclaje TTC
   ↓
05 λ por máxima verosimilitud → 06 transformación Vasicek  →  07 monitoreo y semáforo
   ↓
08 tabla final de PD        →  10 proyección de cohortes    →  11 gráficos
   ↓
09 / 09b  Excel trimestral y mensual
```

Cada paso deja su log en `Resultados/_log_<paso>.txt`. El orquestador se detiene
en el primer fallo y sólo declara flujo completo si corrieron todos los pasos.

---

## Reproducibilidad

La corrida vigente está en `Resultados/`. Volver a ejecutar sobre los mismos
datos reproduce esas salidas. Los parámetros que gobiernan el resultado están
catalogados uno a uno en `config/LEDGER_PARAMETROS.md`, con su valor, lo que
gobierna, su derivación y su sensibilidad medida.
