// Batch runner: corre N tools del MCP ibk-aws en UNA sola sesion y guarda cada
// resultado como archivo. Pensado para la PC del banco: un comando por lote,
// en vez de un copy-paste por paso.
//
// Uso:  node _batch.js <plan.json> [outdir]
//
// plan.json = array de pasos:
//   [ { "id": "01_conteo",  "tool": "athena_query", "args": { "query": "select ..." } },
//     { "id": "02_listado", "tool": "s3_list",      "args": { "prefix": "..." } } ]
//
// Salida: outdir/<id>.txt por paso + outdir/_manifest.json con el estado de cada uno.
// Env: STEP_TIMEOUT_MS (default 300000), STOP_ON_ERROR=1 para cortar al primer fallo.

const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const planPath = process.argv[2];
const outDir = process.argv[3] || process.env.OUT_DIR || path.join(process.cwd(), "salida");
const STEP_TIMEOUT_MS = Number(process.env.STEP_TIMEOUT_MS || 300000);

if (!planPath) {
  console.error("Uso: node _batch.js <plan.json> [outdir]");
  process.exit(2);
}

const plan = JSON.parse(fs.readFileSync(planPath, "utf8"));
if (!Array.isArray(plan) || plan.length === 0) {
  console.error("El plan debe ser un array con al menos un paso.");
  process.exit(2);
}
fs.mkdirSync(outDir, { recursive: true });

// El servidor MCP no siempre vive junto a este script (p.ej. el runner viene de
// un repo y el servidor esta en .claude\mcp). Se resuelve por env, y si no
// aparece se falla temprano con un mensaje accionable: un error criptico aqui
// cuesta un viaje humano completo.
const serverPath = process.env.MCP_SERVER || path.join(__dirname, "ibk-aws-mcp.js");
if (!fs.existsSync(serverPath)) {
  console.error(`No encuentro el servidor MCP en: ${serverPath}`);
  console.error(`Indica la ruta con:  set MCP_SERVER=C:\\ruta\\a\\ibk-aws-mcp.js`);
  process.exit(2);
}

const child = spawn(process.execPath, [serverPath], {
  stdio: ["pipe", "pipe", "inherit"],
  env: { ...process.env },
});

// Capa JSON-RPC por stdio, delimitada por saltos de linea (igual que _call.js,
// pero multiplexando varias respuestas sobre el mismo proceso).
const pending = new Map();
let buf = "";
child.stdout.on("data", (d) => {
  buf += d.toString();
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (!line) continue;
    let m;
    try { m = JSON.parse(line); } catch { continue; }
    const waiter = pending.get(m.id);
    if (waiter) { pending.delete(m.id); waiter(m); }
  }
});

const send = (msg) => child.stdin.write(JSON.stringify(msg) + "\n");

function call(id, method, params) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => { pending.delete(id); reject(new Error("TIMEOUT")); }, STEP_TIMEOUT_MS);
    pending.set(id, (m) => { clearTimeout(t); resolve(m); });
    send({ jsonrpc: "2.0", id, method, params });
  });
}

(async () => {
  await call(1, "initialize", { protocolVersion: "2024-11-05", capabilities: {} });
  send({ jsonrpc: "2.0", method: "notifications/initialized" });

  const manifest = [];
  let fallidos = 0;

  for (let n = 0; n < plan.length; n++) {
    const paso = plan[n];
    const id = paso.id || String(n + 1).padStart(2, "0");
    process.stderr.write(`[${n + 1}/${plan.length}] ${id} (${paso.tool}) ... `);

    let texto, estado;
    try {
      const m = await call(100 + n, "tools/call", { name: paso.tool, arguments: paso.args || {} });
      if (m.error) {
        estado = "error";
        texto = "JSON-RPC error: " + JSON.stringify(m.error);
      } else {
        texto = (m.result.content || []).map((c) => c.text).join("\n");
        estado = m.result.isError ? "error" : "ok";
      }
    } catch (e) {
      estado = "error";
      texto = String(e.message);
    }

    fs.writeFileSync(path.join(outDir, `${id}.txt`), texto, "utf8");
    manifest.push({
      id, tool: paso.tool, estado, archivo: `${id}.txt`, bytes: Buffer.byteLength(texto),
      // Solo el texto de ERROR viaja al resumen: sirve para diagnosticar y no
      // es dato de cartera. La salida de los pasos ok se queda en outDir.
      error: estado === "ok" ? null : texto.slice(0, 400),
    });
    if (estado !== "ok") fallidos++;
    process.stderr.write(estado + "\n");

    // Un paso fallido no corta el lote, salvo que se pida explicitamente:
    // conviene traerse todo lo que si salio antes de diagnosticar.
    if (estado !== "ok" && process.env.STOP_ON_ERROR === "1") break;
  }

  fs.writeFileSync(path.join(outDir, "_manifest.json"), JSON.stringify(manifest, null, 2), "utf8");

  // _resumen.txt = el canal de vuelta. Deliberadamente diminuto: estado por paso
  // y mensajes de error, nada del contenido de los pasos ok. Pensado para que
  // quepa en un copy-paste hacia el chat sin sacar datos del perimetro.
  const ancho = Math.max(...manifest.map((m) => m.id.length));
  const lineas = [
    `LOTE: ${path.basename(planPath)}   ${new Date().toISOString().slice(0, 16).replace("T", " ")}`,
    `${manifest.length - fallidos}/${manifest.length} ok`,
    "",
  ];
  for (const m of manifest) {
    lineas.push(`${m.id.padEnd(ancho)}  ${m.estado === "ok" ? "ok   " : "ERROR"}  ${String(m.bytes).padStart(7)} B`);
    if (m.error) for (const l of m.error.split("\n")) lineas.push(`    > ${l}`);
  }
  // Todo el resumen en ASCII puro: sobrevive cualquier copy-paste entre consolas.
  lineas.push("", `(salida completa en ${outDir} - no se incluye aqui a proposito)`);
  const resumen = lineas.join("\n") + "\n";
  fs.writeFileSync(path.join(outDir, "_resumen.txt"), resumen, "utf8");
  process.stderr.write("\n" + resumen);

  child.kill();
  process.stderr.write(`\nListo. ${manifest.length - fallidos}/${manifest.length} ok -> ${outDir}\n`);
  process.exit(fallidos ? 1 : 0);
})().catch((e) => {
  console.error("FALLO: " + e.message);
  child.kill();
  process.exit(2);
});
