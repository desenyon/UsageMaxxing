#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import vm from "node:vm";

const home = os.homedir();
const pluginRoot = path.join(home, "Library/Application Support/com.sunstory.openusage/plugins");
const pluginDataRoot = path.join(home, "Library/Application Support/com.sunstory.openusage/plugins_data");
const providers = ["claude", "codex", "cursor", "gemini", "antigravity", "perplexity"];
const appPaths = {
  claude: ["/Applications/Claude.app", path.join(home, "Applications/Claude.app")],
  codex: ["/Applications/Codex.app", path.join(home, "Applications/Codex.app")],
  cursor: ["/Applications/Cursor.app", path.join(home, "Applications/Cursor.app")],
  gemini: ["/Applications/Gemini.app", path.join(home, "Applications/Gemini.app")],
  antigravity: [
    "/Applications/Antigravity.app",
    "/Applications/Antigravity IDE.app",
    path.join(home, "Applications/Antigravity.app"),
    path.join(home, "Applications/Antigravity IDE.app"),
  ],
  perplexity: ["/Applications/Perplexity.app", path.join(home, "Applications/Perplexity.app")],
};

function expand(p) {
  return p.replace(/^~(?=$|\/)/, home);
}

function isInstalled(provider) {
  return (appPaths[provider] || []).some((p) => fs.existsSync(p));
}

function parseJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function decodeJwtPayload(token) {
  if (!token || typeof token !== "string") return null;
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const payload = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = payload + "=".repeat((4 - (payload.length % 4)) % 4);
    return JSON.parse(Buffer.from(padded, "base64").toString("utf8"));
  } catch {
    return null;
  }
}

function runSecurity(args) {
  try {
    return execFileSync("/usr/bin/security", args, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return "";
  }
}

function sqliteQuery(dbPath, sql) {
  const output = execFileSync("/usr/bin/sqlite3", ["-json", expand(dbPath), sql], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 16 * 1024 * 1024,
  });
  return output.trim() || "[]";
}

function sqliteExec(dbPath, sql) {
  execFileSync("/usr/bin/sqlite3", [expand(dbPath), sql], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function curlRequest(req) {
  const args = ["-sS", "-i", "-X", req.method || "GET", "--max-time", String(Math.ceil((req.timeoutMs || 15000) / 1000))];
  if (req.dangerouslyIgnoreTls) args.push("-k");
  const headers = req.headers || {};
  for (const [key, value] of Object.entries(headers)) {
    args.push("-H", `${key}: ${value}`);
  }
  if (typeof req.bodyText === "string") {
    args.push("--data", req.bodyText);
  }
  args.push(req.url);

  let output = "";
  try {
    output = execFileSync("/usr/bin/curl", args, {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
      maxBuffer: 32 * 1024 * 1024,
    });
  } catch (error) {
    output = error.stdout?.toString?.() || "";
    if (!output) throw new Error("network request failed");
  }

  const parts = output.split(/\r?\n\r?\n/);
  let headerText = "";
  let bodyText = "";
  for (let i = 0; i < parts.length; i += 1) {
    if (/^HTTP\//.test(parts[i])) {
      headerText = parts[i];
      bodyText = parts.slice(i + 1).join("\n\n");
    }
  }
  const lines = headerText.split(/\r?\n/);
  const status = Number((lines[0] || "").match(/HTTP\/\S+\s+(\d+)/)?.[1] || 0);
  const responseHeaders = {};
  for (const line of lines.slice(1)) {
    const idx = line.indexOf(":");
    if (idx > 0) responseHeaders[line.slice(0, idx).trim().toLowerCase()] = line.slice(idx + 1).trim();
  }
  return { status, headers: responseHeaders, bodyText };
}

function makeContext(provider) {
  const pluginDataDir = path.join(pluginDataRoot, provider);
  fs.mkdirSync(pluginDataDir, { recursive: true });

  const ctx = {
    app: { pluginDataDir },
    host: {
      fs: {
        exists: (p) => fs.existsSync(expand(p)),
        readText: (p) => fs.readFileSync(expand(p), "utf8"),
        writeText: (p, text) => fs.writeFileSync(expand(p), text, "utf8"),
      },
      sqlite: { query: sqliteQuery, exec: sqliteExec },
      keychain: {
        readGenericPassword: (service) => runSecurity(["find-generic-password", "-s", service, "-w"]),
        writeGenericPassword: (service, value) => {
          runSecurity(["delete-generic-password", "-s", service]);
          execFileSync("/usr/bin/security", ["add-generic-password", "-s", service, "-a", service, "-w", value], {
            encoding: "utf8",
            stdio: ["ignore", "ignore", "ignore"],
          });
        },
      },
      log: {
        info: (msg) => console.error(`[${provider}] ${String(msg)}`),
        warn: (msg) => console.error(`[${provider}] WARN ${String(msg)}`),
        error: (msg) => console.error(`[${provider}] ERROR ${String(msg)}`),
      },
      http: { request: curlRequest },
      ls: { discover: discoverLanguageServer },
      ccusage: null,
    },
    util: {
      tryParseJson: parseJson,
      request: curlRequest,
      isAuthStatus: (status) => status === 401 || status === 403,
      parseDateMs: (value) => {
        const ms = Date.parse(value);
        return Number.isFinite(ms) ? ms : null;
      },
      toIso: (value) => {
        if (value === null || value === undefined) return undefined;
        const n = Number(value);
        const ms = Number.isFinite(n) ? (n > 1e12 ? n : n * 1000) : Date.parse(String(value));
        return Number.isFinite(ms) ? new Date(ms).toISOString() : undefined;
      },
      needsRefreshByExpiry: ({ nowMs, expiresAtMs, bufferMs }) => {
        if (!expiresAtMs) return false;
        return Number(expiresAtMs) - Number(nowMs) <= Number(bufferMs || 0);
      },
      retryOnceOnAuth: ({ request, refresh }) => {
        let resp = request();
        if (resp && (resp.status === 401 || resp.status === 403)) {
          const token = refresh();
          if (token) resp = request(token);
        }
        return resp;
      },
    },
    jwt: { decodePayload: decodeJwtPayload },
    base64: {
      decode: (value) => Buffer.from(String(value), "base64").toString("binary"),
    },
    fmt: {
      dollars: (value) => Number(value) / 100,
      planLabel: (value) => String(value || "").replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()),
    },
    line: {
      progress: (line) => ({ type: "progress", ...line }),
      text: (line) => ({ type: "text", ...line }),
      badge: (line) => ({ type: "badge", ...line }),
    },
  };
  return ctx;
}

function discoverLanguageServer(options) {
  const processName = options?.processName || "";
  const markers = options?.markers || [];
  const csrfFlag = options?.csrfFlag || "--csrf_token";
  const portFlag = options?.portFlag || "--extension_server_port";
  let output = "";
  try {
    output = execFileSync("/bin/ps", ["axo", "pid=,command="], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      maxBuffer: 8 * 1024 * 1024,
    });
  } catch {
    return { ports: [] };
  }

  const ports = [];
  let extensionPort = null;
  let csrf = "";
  for (const line of output.split("\n")) {
    if (processName && !line.includes(processName)) continue;
    if (markers.some((marker) => !line.toLowerCase().includes(String(marker).toLowerCase()))) continue;
    const tokens = line.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) || [];
    for (let i = 0; i < tokens.length; i += 1) {
      const token = tokens[i].replace(/^['"]|['"]$/g, "");
      const next = (tokens[i + 1] || "").replace(/^['"]|['"]$/g, "");
      if (token === csrfFlag && next) csrf = next;
      if (token.startsWith(`${csrfFlag}=`)) csrf = token.slice(csrfFlag.length + 1);
      if (token === portFlag && Number(next)) {
        extensionPort = Number(next);
        ports.push(extensionPort);
      }
      if (token.startsWith(`${portFlag}=`)) {
        const port = Number(token.slice(portFlag.length + 1));
        if (Number.isFinite(port)) {
          extensionPort = port;
          ports.push(port);
        }
      }
    }
  }
  return { ports: Array.from(new Set(ports)), extensionPort, csrf };
}

async function probeProvider(provider) {
  const pluginPath = path.join(pluginRoot, provider, "plugin.js");
  if (!isInstalled(provider)) {
    return { provider, installed: false, status: "not_installed", lines: [] };
  }
  if (!fs.existsSync(pluginPath)) {
    return { provider, installed: true, status: "unsupported", lines: [], error: "No exact local plugin installed." };
  }

  const context = {
    console,
    globalThis: {},
    TextDecoder,
    Uint8Array,
    Date,
    Math,
    Number,
    String,
    Boolean,
    Array,
    Object,
    JSON,
    RegExp,
    Error,
    encodeURIComponent,
    decodeURIComponent,
    setTimeout,
    clearTimeout,
  };
  context.globalThis = context;
  vm.createContext(context);
  vm.runInContext(fs.readFileSync(pluginPath, "utf8"), context, { filename: pluginPath, timeout: 1000 });
  const plugin = context.globalThis.__openusage_plugin;
  if (!plugin || typeof plugin.probe !== "function") {
    return { provider, installed: true, status: "unsupported", lines: [], error: "Exact plugin does not expose a probe." };
  }

  try {
    const result = plugin.probe(makeContext(provider));
    const lines = Array.isArray(result?.lines) ? result.lines : [];
    if (lines.length === 0) {
      return { provider, installed: true, status: "unavailable", plan: result?.plan || null, lines: [], error: "No exact usage lines returned." };
    }
    return { provider, installed: true, status: "ok", plan: result?.plan || null, lines };
  } catch (error) {
    return { provider, installed: true, status: "error", lines: [], error: String(error) };
  }
}

const selected = process.argv.slice(2).filter((p) => providers.includes(p));
const runProviders = selected.length ? selected : providers;
const results = [];
for (const provider of runProviders) {
  results.push(await probeProvider(provider));
}
process.stdout.write(JSON.stringify({ generatedAt: new Date().toISOString(), results }, null, 2));
