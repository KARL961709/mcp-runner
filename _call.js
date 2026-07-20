// Helper de prueba: maneja el MCP ibk-aws y llama una tool.
// Uso: TOOL=<tool> ARGS_JSON='{"...":"..."}' node _call.js
// Compat: si TOOL=athena_query y solo hay SQL, arma {query: SQL}.
const { spawn } = require("child_process");
const path = require("path");
const child = spawn(process.execPath, [path.join(__dirname, "ibk-aws-mcp.js")], {
  stdio: ["pipe", "pipe", "inherit"],
  env: { ...process.env },
});
let buf = "";
child.stdout.on("data", (d) => {
  buf += d.toString();
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (!line) continue;
    const m = JSON.parse(line);
    if (m.id === 3) {
      console.log(m.result.content[0].text);
      child.kill();
      process.exit(m.result.isError ? 1 : 0);
    }
  }
});
const tool = process.env.TOOL || "athena_query";
let argsObj;
if (process.env.ARGS_JSON) argsObj = JSON.parse(process.env.ARGS_JSON);
else if (tool === "athena_query") argsObj = { query: process.env.SQL, maxRows: Number(process.env.MAXROWS || 1000) };
else argsObj = {};
[
  { jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2024-11-05", capabilities: {} } },
  { jsonrpc: "2.0", method: "notifications/initialized" },
  { jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: tool, arguments: argsObj } },
].forEach((mm) => child.stdin.write(JSON.stringify(mm) + "\n"));
setTimeout(() => { console.error("TIMEOUT"); child.kill(); process.exit(2); }, 300000);
