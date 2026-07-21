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

## Configuración

`config.ps1` (no versionado) define perfil, workgroup y base. Plantilla en
`config.ejemplo.ps1`. Nunca pongas esos valores en archivos versionados.
