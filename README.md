# mcp-runner

Runner por lotes para servidores MCP que hablan stdio. Levanta el servidor una
sola vez, corre N llamadas de un plan y guarda cada resultado como archivo.

Existe porque el entorno donde se ejecuta y el entorno donde se escribe el codigo
estan aislados: no hay red comun, y el transporte entre ambos es una persona
copiando y pegando. Por eso el objetivo del diseno es **minimizar viajes humanos**,
no automatizar el cruce.

## Uso

```
node _batch.js <plan.json> [outdir]
```

`plan.json` es un array de pasos:

```json
[
  { "id": "01_conteo", "tool": "athena_query", "args": { "query": "select 1" } },
  { "id": "02_listado", "tool": "s3_list",     "args": {} }
]
```

Variables de entorno:

- `STEP_TIMEOUT_MS` - timeout por paso (default 300000)
- `STOP_ON_ERROR=1` - cortar al primer fallo (por defecto NO corta: conviene
  traerse todo lo que si salio antes de diagnosticar)

## Que produce

En `outdir`:

- `<id>.txt` por cada paso, con la salida completa
- `_manifest.json` - estado estructurado de cada paso
- `_resumen.txt` - **el canal de vuelta**

`_resumen.txt` es deliberadamente diminuto: estado por paso y mensajes de error,
y *nada* del contenido de los pasos que salieron bien. Esta pensado para caber en
un copy-paste sin sacar datos del entorno donde se ejecuto. De vuelta viaja el
diagnostico, no el dato.

`_call.js` es la version de una sola tool, util para probar algo suelto:

```
TOOL=s3_list ARGS_JSON="{}" node _call.js
```

## Que NO va en este repo

El servidor MCP en si, los planes con SQL real, y cualquier salida. El
`.gitignore` esta en modo lista blanca para que eso no dependa de acordarse.

## Requisitos

Node, y el servidor MCP (`ibk-aws-mcp.js`) presente en la misma carpeta desde
donde se invoca `_batch.js` — o ajustar la ruta en la linea del `spawn`.
