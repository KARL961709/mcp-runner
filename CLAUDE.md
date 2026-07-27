# mcp-runner — contexto para Claude

Este repo es un **canal de una sola dirección** entre dos máquinas aisladas.

## La restricción que lo explica todo

La máquina donde se escribe el código (fábrica) **no tiene acceso a AWS**: la red
corporativa bloquea el acceso desde equipos externos. La máquina que sí lo tiene
(ejecución) no es accesible remotamente. No existe red común entre ambas.

No busques workarounds a esto — el bloqueo es política deliberada y se respeta.

## Cómo fluye el trabajo

```
FÁBRICA (aquí escribo)            EJECUCIÓN (allá corre)
──────────────────────            ──────────────────────
edito sql/ y scripts
git push  ─────────────► GitHub ──────────►  .\Go.ps1
                                             (git pull + corre + resumen)
leo _resumen.txt  ◄──── pegado a mano ◄──────
```

El usuario es el único transporte de vuelta. **Diseña para minimizar viajes
humanos:** valida temprano, falla con mensajes accionables, y no dependas de
iterar contra el error — cada vuelta le cuesta a una persona.

## La regla que no se cruza

**El código entra, los datos no salen.**

El `.gitignore` está en **lista blanca**: `*` seguido de excepciones `!` explícitas.
Esto es un control técnico, no una convención — `output/`, `*.csv` y `config.ps1`
no se pueden commitear ni por accidente.

Consecuencia práctica: **al agregar un archivo nuevo hay que sumarle su `!`**, o
no se sube. Verifica siempre después de un push:

```
git ls-tree -r --name-only origin/master
```

## Canal de vuelta

`_resumen.txt` lleva estado por query, filas, segundos y el mensaje de error si
falló. **Nunca contenido de resultados.** De vuelta viaja el diagnóstico, no el
dato. Si necesitas más para diagnosticar, pide un error más explícito — no una
muestra de filas.

## Gotchas ya pagados

- **BOM**: Athena responde `MALFORMED_QUERY: mismatched input 'ï'` si el .sql
  tiene BOM. Lo meten Notepad y `Set-Content -Encoding utf8` de PowerShell 5.1.
  `Run-Athena.ps1` normaliza antes de enviar, pero al crear .sql usa
  `[System.IO.File]::WriteAllText(..., New-Object System.Text.UTF8Encoding($false))`.
- **Splatting**: reenvía parámetros entre scripts por **hashtable**, no por array.
  El array los pasa como posicionales y un switch termina bindeado al primer
  parámetro.
- **PositionalBinding**: los scripts usan `PositionalBinding=$false` a propósito.
  Un argumento suelto debe ser un error, no un `-SqlDir` accidental.
- **Comillas dobles** en mensajes de commit con here-string de PS 5.1 rompen el
  paso de argumentos a git: el commit falla y el `push exit: 0` engaña.

## Cómo se construyen las tablas aquí

Las reglas completas viven en `C:\Users\CARLOS\Documents\2026\GDM\_motor_insumos_cal\`
(`PATRON_DISENO_SCRIPTS.md` = las 5 lentes · `ESTILO_SQL.md` · `ORDEN_SCRIPTS.md` ·
`SKILL_EXTENDIDO.md` = los 22 gates). Las de acá ya costaron días, y están inline
porque un puntero a un archivo que la sesión quizá no abra es más débil que la regla.

**Cadena materializada, nunca un mega-query.** Trino **NO materializa los CTE: los
inlinea**. Un CTE referenciado 3 veces se recomputa 3 veces. Cada paso es
`DROP TABLE IF EXISTS` + `CREATE TABLE AS` leyendo del anterior. Un statement por
archivo (Athena no corre varios) y **sin punto y coma**, ni siquiera en comentarios.

**El costo se mide en particiones LEÍDAS, no en meses escritos.**
`P = ventana_escritura + lookback + lookforward`. Pasar de 6 a 24 meses escritos no
multiplica por 4: el lookback es cola fija (20 → 38 particiones = 1.9x).

**El límite de tiempo es del runner, no de Athena.** `Run-Athena.ps1` trae
`-TimeoutSec 900` por defecto y **no hay `stop-query-execution`**: un `TIMEOUT` puede
haber terminado bien y dejado la tabla creada. Y el `catch` no corta el `foreach`, así
que un fallo genera errores en cascada: **la causa raíz es siempre el primer error**.
Por eso los CTAS se corren de a uno.

**Identidad por CÓDIGO, nunca por nombre.** `LIKE '%CREDITO DEL PERU%'` no matchea
`'BANCO DE CRÉDITO DEL PERÚ'`, y en su lugar entran los vehículos de cartera vendida.
Antes de cualquier join entre fuentes, medir el formato de las DOS llaves
(`length(v)` vs `length(to_utf8(v))`, ceros a la izquierda).

**`RANK()` no dedupea** — los empates reciben todos el 1. Usar `ROW_NUMBER()` con orden
total, y declarar la política de desempate: no es un detalle técnico, decide población.

**Subconjunto portable de Athena:** `UNNEST` multi-array (`UNNEST(ARRAY[...], ARRAY[...])`),
nunca `UNNEST(ARRAY[ROW(...)])` — Athena lo colapsa a una sola columna.

**Un flag = un eje.** No fusionar dos preguntas en una escala ordinal. Si un consumo
necesita `IN (1,98)` o restar buckets, el esquema está mal y se parte antes de construir.

**Validar lo generado antes de pushear:** paréntesis, corchetes, comillas, ASCII puro,
un solo statement. Toda edición masiva por script corre **en seco primero**.

## Configuración

`config.ps1` (no versionado) define perfil, workgroup y base. Plantilla en
`config.ejemplo.ps1`. Nunca pongas esos valores en archivos versionados.
