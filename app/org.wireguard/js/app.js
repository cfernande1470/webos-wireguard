const BASE = "/var/lib/webosbrew/wireguard";
const APPDIR = "/media/developer/apps/usr/palm/applications/org.webosbrew.wireguard";
const HB_SERVICE = "luna://org.webosbrew.hbchannel.service";

const I18N = {
  en: {
    subtitle: "WireGuard client for webOS Homebrew",
    installUpdate: "Install / update",
    startVpn: "Start VPN",
    stopVpn: "Stop VPN",
    status: "Status",
    cleanAll: "Uninstall",
    routes: "Routes",
    config: "Config",
    log: "Log",
    uploadConfig: "Upload config",
    donate: "Donate!",
    donateTitle: "Donate!",
    donatePaypal: "Donate with PayPal",
    startOnBoot: "Start on boot",
    scrollUp: "▲ Up",
    scrollDown: "▼ Down",
    scrollEnd: "End",
    hint: 'To upload a configuration: press <b>Upload config</b>, open the URL on your computer and send your <code>wg0.conf</code>.',
    uploadTitle: "Upload configuration",
    uploadHelp: 'Open the URL from your computer, enter the PIN and upload your <b>wg0.conf</b>. Closing this window will stop the temporary upload server.',
    close: "Close",

    ready: "Ready.",
    executing: "Running...",
    completed: "Completed",
    error: "Error",
    timeout: "Timeout",
    checkingComponents: "Checking components",
    componentsReady: "Components ready",
    installPending: "Install required",
    installingComponents: "Installing/updating components...",
    componentsInstalled: "Components installed/updated",
    uploadStarting: "Starting upload server...",
    uploadStarted: "Upload server started",
    uploadStopping: "Stopping upload server...",
    uploadStopped: "Upload server stopped",
    uploadStopError: "Error stopping upload server",

    serviceUnavailable:
      "ERROR: webOS.service.request is not available.\n\n" +
      "Check that this file exists:\n" +
      "lib/webOSTVjs-1.2.4/webOSTV.js",

    serviceUnavailableStatus: "Error: webOS service unavailable",
    hbTimeout: "TIMEOUT: no response from Homebrew service.",
    jsException: "JS EXCEPTION",
    lunaError: "luna-call ERROR",

    checkInstalled:
      "WireGuard Homebrew ready.\n\n" +
      "Components already installed.\n\n" +
      "Options:\n" +
      "1. Install / update if you have just updated the app\n" +
      "2. Upload config\n" +
      "3. Start VPN\n" +
      "4. Status",

    checkMissing:
      "WireGuard Homebrew ready.\n\n" +
      "WireGuard components are not installed yet.\n\n" +
      "Press Install / update before using the VPN.",

    checkingInitial:
      "WireGuard Homebrew ready.\n\n" +
      "Checking whether components are already installed...",

    installLabel: "Install / update",
    startLabel: "Start VPN",
    stopLabel: "Stop VPN",
    statusLabel: "VPN status",
    routesLabel: "Routes",
    configLabel: "Config",
    logsLabel: "Logs",
    uploadLabel: "Upload config",
    autostartEnable: "Enable start on boot",
    autostartDisable: "Disable start on boot",
    cleanupLabel: "Uninstall WireGuard",

    uploadInstructions:
      "Open that URL from your computer, enter the PIN and upload your wg0.conf."
  },

  es: {
    subtitle: "Cliente WireGuard para webOS Homebrew",
    installUpdate: "Instalar / actualizar",
    startVpn: "Arrancar VPN",
    stopVpn: "Parar VPN",
    status: "Estado",
    cleanAll: "Desinstalar",
    routes: "Rutas",
    config: "Config",
    log: "Log",
    uploadConfig: "Subir config",
    donate: "Donar!",
    donateTitle: "Donar!",
    donatePaypal: "Donate with PayPal",
    startOnBoot: "Iniciar al arrancar",
    scrollUp: "▲ Subir",
    scrollDown: "▼ Bajar",
    scrollEnd: "Fin",
    hint: 'Para subir configuración: pulsa <b>Subir config</b>, abre la URL en el ordenador y manda tu <code>wg0.conf</code>.',
    uploadTitle: "Subir configuración",
    uploadHelp: 'Abre la URL desde el ordenador, introduce el PIN y sube tu <b>wg0.conf</b>. Al cerrar esta ventana se parará el servidor temporal de subida.',
    close: "Cerrar",

    ready: "Listo.",
    executing: "Ejecutando...",
    completed: "Completado",
    error: "Error",
    timeout: "Timeout",
    checkingComponents: "Comprobando componentes",
    componentsReady: "Componentes listos",
    installPending: "Pendiente de instalar",
    installingComponents: "Instalando/actualizando componentes...",
    componentsInstalled: "Componentes instalados/actualizados",
    uploadStarting: "Arrancando servidor de subida...",
    uploadStarted: "Servidor de subida arrancado",
    uploadStopping: "Parando servidor de subida...",
    uploadStopped: "Servidor de subida parado",
    uploadStopError: "Error al parar subida",

    serviceUnavailable:
      "ERROR: webOS.service.request no está disponible.\n\n" +
      "Comprueba que existe:\n" +
      "lib/webOSTVjs-1.2.4/webOSTV.js",

    serviceUnavailableStatus: "Error: servicio webOS no disponible",
    hbTimeout: "TIMEOUT: sin respuesta del servicio Homebrew.",
    jsException: "EXCEPCIÓN JS",
    lunaError: "ERROR luna-call",

    checkInstalled:
      "WireGuard Homebrew listo.\n\n" +
      "Componentes ya instalados.\n\n" +
      "Opciones:\n" +
      "1. Instalar / actualizar si acabas de actualizar la app\n" +
      "2. Subir config\n" +
      "3. Arrancar VPN\n" +
      "4. Estado",

    checkMissing:
      "WireGuard Homebrew listo.\n\n" +
      "Los componentes WireGuard todavía no están instalados.\n\n" +
      "Pulsa Instalar / actualizar antes de usar la VPN.",

    checkingInitial:
      "WireGuard Homebrew listo.\n\n" +
      "Comprobando si los componentes ya están instalados...",

    installLabel: "Instalar / actualizar",
    startLabel: "Arrancar VPN",
    stopLabel: "Parar VPN",
    statusLabel: "Estado VPN",
    routesLabel: "Rutas",
    configLabel: "Config",
    logsLabel: "Logs",
    uploadLabel: "Subir config",
    autostartEnable: "Activar inicio al arrancar",
    autostartDisable: "Desactivar inicio al arrancar",
    cleanupLabel: "Desinstalar WireGuard",

    uploadInstructions:
      "Abre esa URL desde el portátil, introduce el PIN y sube el wg0.conf."
  }
};

let currentLang = "en";

try {
  currentLang = localStorage.getItem("wgLanguage") || "en";
} catch (e) {
  currentLang = "en";
}

if (!I18N[currentLang]) {
  currentLang = "en";
}

function t(key) {
  return (I18N[currentLang] && I18N[currentLang][key]) || I18N.en[key] || key;
}

function applyLanguage() {
  document.documentElement.lang = currentLang;

  const textNodes = document.querySelectorAll("[data-i18n]");
  for (let i = 0; i < textNodes.length; i++) {
    const key = textNodes[i].getAttribute("data-i18n");
    textNodes[i].textContent = t(key);
  }

  const htmlNodes = document.querySelectorAll("[data-i18n-html]");
  for (let i = 0; i < htmlNodes.length; i++) {
    const key = htmlNodes[i].getAttribute("data-i18n-html");
    htmlNodes[i].innerHTML = t(key);
  }

  const enBtn = document.getElementById("langEn");
  const esBtn = document.getElementById("langEs");

  if (enBtn) {
    enBtn.classList.toggle("active", currentLang === "en");
    enBtn.setAttribute("aria-pressed", currentLang === "en" ? "true" : "false");
  }

  if (esBtn) {
    esBtn.classList.toggle("active", currentLang === "es");
    esBtn.setAttribute("aria-pressed", currentLang === "es" ? "true" : "false");
  }
}

function setLanguage(lang) {
  if (!I18N[lang]) {
    lang = "en";
  }

  currentLang = lang;

  try {
    localStorage.setItem("wgLanguage", currentLang);
  } catch (e) {}

  applyLanguage();
  setStatus(t("ready"));
}



function setStatus(text) {
  const el = document.getElementById("statusLine");
  if (el) el.textContent = text || "";
}

function print(text) {
  const el = document.getElementById("out");
  if (el) {
    el.textContent = text || "";
    el.scrollTop = 0;
  }
}

function append(text) {
  const el = document.getElementById("out");
  if (el) el.textContent += "\n" + (text || "");
}

function scrollOutput(direction) {
  const el = document.getElementById("out");
  if (!el) return;
  el.scrollTop += direction * 300;
}

function scrollOutputToEnd() {
  const el = document.getElementById("out");
  if (!el) return;
  el.scrollTop = el.scrollHeight;
}

function decodeBase64Maybe(value) {
  if (!value) return "";
  try {
    return atob(value);
  } catch (e) {
    return "";
  }
}

function formatResponse(res) {
  let out = "";

  if (res.stdoutString) {
    out += res.stdoutString;
  } else if (res.stdoutBytes) {
    out += decodeBase64Maybe(res.stdoutBytes);
  }

  if (res.stderrString) {
    out += "\nSTDERR:\n" + res.stderrString;
  } else if (res.stderrBytes) {
    const stderr = decodeBase64Maybe(res.stderrBytes);
    if (stderr) out += "\nSTDERR:\n" + stderr;
  }

  if (!out) {
    out = JSON.stringify(res, null, 2);
  }

  return out;
}

function serviceAvailable() {
  return (
    typeof webOS !== "undefined" &&
    webOS.service &&
    typeof webOS.service.request === "function"
  );
}

function execCommand(command, callback, timeoutMs) {
  timeoutMs = timeoutMs || 20000;

  if (!serviceAvailable()) {
    const msg =
      t("serviceUnavailable");
    print(msg);
    setStatus(t("serviceUnavailableStatus"));
    if (callback) callback(false, msg);
    return;
  }

  let finished = false;

  const timer = setTimeout(function() {
    if (!finished) {
      finished = true;
      const msg = t("hbTimeout");
      append("\n\n" + msg);
      setStatus("Timeout");
      if (callback) callback(false, msg);
    }
  }, timeoutMs);

  try {
    webOS.service.request(HB_SERVICE, {
      method: "exec",
      parameters: {
        command: command
      },
      onSuccess: function(res) {
        if (finished) return;
        finished = true;
        clearTimeout(timer);
        const out = formatResponse(res);
        if (callback) callback(true, out, res);
      },
      onFailure: function(err) {
        if (finished) return;
        finished = true;
        clearTimeout(timer);
        const out = t("lunaError") + ":\n" + JSON.stringify(err, null, 2);
        if (callback) callback(false, out, err);
      }
    });
  } catch (e) {
    finished = true;
    clearTimeout(timer);
    const out = t("jsException") + ":\n" + e.message + "\n\n" + (e.stack || "");
    if (callback) callback(false, out, e);
  }
}

function run(command, label, timeoutMs) {
  setStatus(t("executing"));
  print("Running:\n" + (label || command) + "\n\nWaiting for response...");

  const wrappedCommand =
    "( " + command + " ); " +
    "RC=$?; " +
    "echo; echo COMMAND_RC=$RC; " +
    "exit 0";

  execCommand(wrappedCommand, function(ok, out) {
    print(out);

    const commandOk = ok && out.indexOf("COMMAND_RC=0") !== -1;
    setStatus(commandOk ? t("completed") : t("error"));
  }, timeoutMs || 20000);
}

function componentsCheckCommand() {
  return (
    "if [ -x " + BASE + "/scripts/status.sh ] && " +
    "   [ -x " + BASE + "/scripts/start.sh ] && " +
    "   [ -x " + BASE + "/scripts/stop.sh ] && " +
    "   [ -x " + BASE + "/bin/wg ] && " +
    "   [ -x " + BASE + "/bin/wireguard-go ] && " +
    "   [ -x " + BASE + "/bin/wg-upload ]; then " +
    "  echo 'COMPONENTS_STATUS=installed'; " +
    "  echo 'WireGuard components installed'; " +
    "else " +
    "  echo 'COMPONENTS_STATUS=missing'; " +
    "  echo 'WireGuard components not installed'; " +
    "  echo 'Press Install / update before starting the VPN.'; " +
    "fi"
  );
}

function checkComponents(callback) {
  execCommand(componentsCheckCommand(), function(ok, out) {
    const installed = out.indexOf("COMPONENTS_STATUS=installed") !== -1;
    if (callback) callback(installed, out);
  }, 10000);
}

function installComponents() {
  const cmd =
    "APPID='org.webosbrew.wireguard'; " +
    "echo 'Installing/updating WireGuard components...'; " +
    "echo; echo '== whoami / id =='; " +
    "id 2>&1 || true; " +
    "echo; echo '== app locations =='; " +
    "INSTALL=''; " +
    "for d in " +
      "/media/developer/apps/usr/palm/applications/$APPID " +
      "/media/cryptofs/apps/usr/palm/applications/$APPID " +
      "/media/internal/apps/usr/palm/applications/$APPID; do " +
      "echo \"checking: $d\"; " +
      "if [ -f \"$d/payload/wireguard/install.sh\" ]; then " +
        "INSTALL=\"$d/payload/wireguard/install.sh\"; " +
        "break; " +
      "fi; " +
    "done; " +
    "if [ -z \"$INSTALL\" ]; then " +
      "echo; echo '== fallback search =='; " +
      "INSTALL=$(find /media -type f -path '*/org.webosbrew.wireguard/payload/wireguard/install.sh' 2>/dev/null | head -1); " +
    "fi; " +
    "if [ -z \"$INSTALL\" ]; then " +
      "echo 'ERROR: cannot find payload/wireguard/install.sh'; " +
      "echo; echo '== matching files =='; " +
      "find /media -path '*org.webosbrew.wireguard*' 2>/dev/null | head -120; " +
      "echo; echo 'INSTALL_RC=1'; " +
      "exit 0; " +
    "fi; " +
    "echo; echo \"found installer: $INSTALL\"; " +
    "echo; echo '== running installer =='; " +
    "sh \"$INSTALL\"; " +
    "RC=$?; " +
    "echo; echo \"INSTALL_RC=$RC\"; " +
    "exit 0";

  setStatus(t("installingComponents"));
  print("Running:\n" + t("installLabel") + "\n\nWaiting for response...");

  execCommand(cmd, function(ok, out) {
    print(out);

    const installOk = ok && out.indexOf("INSTALL_RC=0") !== -1;

    if (installOk) {
      setStatus(t("componentsInstalled"));
      refreshAutostart();
    } else {
      setStatus(t("error"));
    }
  }, 60000);
}

function startVpn() {
  run(BASE + "/scripts/start.sh", t("startLabel"), 30000);
}

function stopVpn() {
  run(BASE + "/scripts/stop.sh", t("stopLabel"), 30000);
}

function statusVpn() {
  run(BASE + "/scripts/status.sh", t("statusLabel"), 30000);
}

function showRoutes() {
  run(
    "echo '== routes =='; " +
    "ip route; " +
    "echo; echo '== route get 1.1.1.1 =='; " +
    "ip route get 1.1.1.1 2>&1 || true; " +
    "echo; echo '== public IPv4 =='; " +
    "curl -4 --max-time 10 http://ifconfig.me/ip 2>/dev/null || true; " +
    "echo",
    t("routesLabel"),
    30000
  );
}

function showConfig() {
  run(
    "echo '== wg0.conf =='; " +
    "sed -E 's#^(PrivateKey[[:space:]]*=[[:space:]]*).*#\\1REDACTED#;s#^(PresharedKey[[:space:]]*=[[:space:]]*).*#\\1REDACTED#' " +
    BASE + "/conf/wg0.conf 2>/dev/null || true; " +
    "echo; echo '== address =='; " +
    "cat " + BASE + "/conf/address 2>/dev/null || true; " +
    "echo; echo '== autostart =='; " +
    BASE + "/scripts/autostart.sh status 2>&1 || true",
    t("configLabel"),
    30000
  );
}

function showLog() {
  run(
    "echo '== wireguard-go.log =='; " +
    "tail -120 " + BASE + "/run/wireguard-go.log 2>/dev/null || true; " +
    "echo; echo '== autostart.log =='; " +
    "tail -80 " + BASE + "/run/autostart.log 2>/dev/null || true; " +
    "echo; echo '== upload.log =='; " +
    "tail -80 " + BASE + "/run/wg-upload.log 2>/dev/null || true",
    t("logsLabel"),
    30000
  );
}

function uploadStart() {
  setStatus(t("uploadStarting"));
  print("Running:\n" + t("uploadLabel") + "\n\nWaiting for response...");

  execCommand(BASE + "/scripts/upload-start.sh", function(ok, out) {
    print(out);
    setStatus(ok ? t("uploadStarted") : t("error"));

    if (ok) {
      showUploadPopup(out);
    }
  }, 30000);
}

function refreshAutostart() {
  const cmd =
    "if [ -x " + BASE + "/scripts/autostart.sh ]; then " +
    BASE + "/scripts/autostart.sh status; " +
    "else echo 'Autostart: unavailable'; fi";

  execCommand(cmd, function(ok, out) {
    const toggle = document.getElementById("autostartToggle");
    if (!toggle) return;

    const unavailable = out.indexOf("unavailable") !== -1;
    toggle.checked = out.indexOf("enabled") !== -1;
    toggle.disabled = unavailable;
  }, 10000);
}

function toggleAutostart() {
  const toggle = document.getElementById("autostartToggle");
  const enable = toggle && toggle.checked;
  const cmd = BASE + "/scripts/autostart.sh " + (enable ? "enable" : "disable");

  run(cmd, enable ? t("autostartEnable") : t("autostartDisable"), 15000);

  setTimeout(refreshAutostart, 1200);
}

window.onerror = function(message, source, lineno, colno, error) {
  print(
    "JS ERROR:\n" +
    message + "\n" +
    "line: " + lineno + ":" + colno + "\n" +
    (error && error.stack ? error.stack : "")
  );
  setStatus("JS error");
};

window.onload = function() {
  applyLanguage();
  print(
    t("checkingInitial")
  );

  setStatus(t("checkingComponents"));

  checkComponents(function(installed, out) {
    if (installed) {
      refreshAutostart();

      setStatus(t("ready"));
      print(t("checkInstalled"));
    } else {
      setStatus(t("installPending"));
      print(t("checkMissing"));

      const toggle = document.getElementById("autostartToggle");
      if (toggle) {
        toggle.checked = false;
        toggle.disabled = true;
      }
    }
  });

  setTimeout(function() {
    const btn = document.querySelector("button");
    if (btn) btn.focus();
  }, 300);
};

function showUploadPopup(output) {
  const modal = document.getElementById("uploadModal");
  const urlEl = document.getElementById("uploadUrl");
  const pinEl = document.getElementById("uploadPin");

  if (!modal || !urlEl || !pinEl) return;

  const urlMatch = output.match(/URL:\s*(http:\/\/[^\s]+)/i);
  const pinMatch = output.match(/PIN:\s*([0-9]{4})/i) || output.match(/TOKEN:\s*([0-9]{4})/i);

  const url = urlMatch ? urlMatch[1] : "No encontrada";
  const pin = pinMatch ? pinMatch[1] : "----";

  urlEl.textContent = url;
  pinEl.textContent = pin;

  modal.classList.remove("hidden");

  setTimeout(function() {
    const btn = modal.querySelector("button");
    if (btn) btn.focus();
  }, 200);
}

function closeUploadPopup() {
  const modal = document.getElementById("uploadModal");
  if (modal) modal.classList.add("hidden");

  setStatus(t("uploadStopping"));

  execCommand(BASE + "/scripts/upload-stop.sh", function(ok, out) {
    print(out);
    setStatus(ok ? t("uploadStopped") : t("uploadStopError"));

    setTimeout(function() {
      const btn = document.querySelector("button.upload");
      if (btn) btn.focus();
    }, 100);
  }, 15000);
}
function showDonatePopup() {
  const modal = document.getElementById("donateModal");
  if (!modal) return;

  modal.classList.remove("hidden");

  setTimeout(function() {
    const btn = modal.querySelector("button");
    if (btn) btn.focus();
  }, 200);
}

function closeDonatePopup() {
  const modal = document.getElementById("donateModal");
  if (modal) modal.classList.add("hidden");

  setTimeout(function() {
    const btn = document.querySelector("button.donate");
    if (btn) btn.focus();
  }, 100);
}

function cleanupAll() {
  run(
    BASE + "/scripts/uninstall.sh",
    t("cleanupLabel"),
    30000
  );
}
