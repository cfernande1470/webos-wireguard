package main

import (
	"bufio"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const base = "/var/lib/webosbrew/wireguard"

var token string

func main() {
	token = os.Getenv("WG_UPLOAD_TOKEN")
	if token == "" {
		token = randomToken()
	}

	log.Printf("wg-upload listening on :8088")
	log.Printf("token: %s", token)

	http.HandleFunc("/", index)
	http.HandleFunc("/upload", upload)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "OK")
	})

	log.Fatal(http.ListenAndServe(":8088", nil))
}

func randomToken() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	return hex.EncodeToString(b[:])
}

func index(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		writeError(w, langFromRequest(r), http.StatusNotFound, "Page not found")
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, indexHTML)
}

const indexHTML = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>WireGuard webOS upload</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #0c1117;
      --card: #111a24;
      --card-2: #162230;
      --text: #f4f7fb;
      --muted: #9fb0c4;
      --accent: #58f0aa;
      --accent-2: #168458;
      --danger: #ff6b6b;
      --border: #2d3d50;
      --input: #071018;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: Arial, Helvetica, sans-serif;
      background:
        radial-gradient(circle at top left, rgba(88, 240, 170, 0.16), transparent 32rem),
        radial-gradient(circle at bottom right, rgba(108, 76, 165, 0.22), transparent 34rem),
        var(--bg);
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 32px 18px;
    }

    .shell {
      width: 100%;
      max-width: 860px;
    }

    .topbar {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
      margin-bottom: 14px;
    }

    .lang-button {
      border: 1px solid var(--border);
      background: rgba(17, 26, 36, 0.86);
      color: var(--muted);
      border-radius: 999px;
      padding: 10px 16px;
      font-size: 16px;
      cursor: pointer;
      transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
    }

    .lang-button.active {
      color: var(--text);
      border-color: var(--accent);
      background: rgba(88, 240, 170, 0.14);
      box-shadow: 0 0 0 1px rgba(88, 240, 170, 0.16) inset;
    }

    .card {
      background: linear-gradient(180deg, rgba(22, 34, 48, 0.98), rgba(12, 17, 23, 0.98));
      border: 1px solid var(--border);
      border-radius: 28px;
      box-shadow: 0 24px 80px rgba(0, 0, 0, 0.4);
      overflow: hidden;
    }

    .hero {
      padding: 34px 34px 22px 34px;
      border-bottom: 1px solid var(--border);
      background: rgba(88, 240, 170, 0.05);
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(88, 240, 170, 0.12);
      color: var(--accent);
      font-weight: bold;
      font-size: 14px;
      margin-bottom: 16px;
    }

    h1 {
      margin: 0;
      font-size: 38px;
      line-height: 1.08;
    }

    .subtitle {
      margin: 14px 0 0 0;
      color: var(--muted);
      font-size: 18px;
      line-height: 1.45;
    }

    .content {
      padding: 30px 34px 34px 34px;
    }

    .field {
      margin-bottom: 22px;
    }

    label {
      display: block;
      margin-bottom: 10px;
      color: var(--text);
      font-weight: bold;
      font-size: 16px;
    }

    .hint {
      color: var(--muted);
      font-size: 14px;
      margin-top: 8px;
      line-height: 1.4;
    }

    input[type="text"],
    input[type="file"] {
      width: 100%;
      border: 1px solid var(--border);
      border-radius: 16px;
      background: var(--input);
      color: var(--text);
      font-size: 18px;
      padding: 14px 16px;
    }

    input[type="file"] {
      cursor: pointer;
    }

    input:focus,
    button:focus {
      outline: 4px solid rgba(88, 240, 170, 0.45);
      outline-offset: 2px;
    }

    .submit {
      width: 100%;
      border: 0;
      border-radius: 18px;
      padding: 16px 22px;
      background: var(--accent-2);
      color: #fff;
      font-size: 20px;
      font-weight: bold;
      cursor: pointer;
      box-shadow: 0 14px 32px rgba(22, 132, 88, 0.28);
    }

    .submit:hover {
      filter: brightness(1.08);
    }

    .steps {
      margin-top: 24px;
      padding: 18px;
      border: 1px solid var(--border);
      border-radius: 18px;
      background: rgba(255, 255, 255, 0.03);
      color: var(--muted);
      line-height: 1.55;
    }

    code {
      background: rgba(255, 255, 255, 0.09);
      color: #fff;
      padding: 2px 6px;
      border-radius: 6px;
    }

    @media (max-width: 620px) {
      body {
        padding: 18px 12px;
      }

      .hero,
      .content {
        padding-left: 22px;
        padding-right: 22px;
      }

      h1 {
        font-size: 30px;
      }
    }
  </style>
</head>
<body>
  <main class="shell">
    <div class="topbar" aria-label="Language selector">
      <button id="langEn" class="lang-button" type="button" onclick="setLanguage('en')">🇬🇧 English</button>
      <button id="langEs" class="lang-button" type="button" onclick="setLanguage('es')">🇪🇸 Español</button>
    </div>

    <section class="card">
      <div class="hero">
        <div class="badge">WireGuard · webOS</div>
        <h1 data-i18n="title">Upload WireGuard configuration</h1>
        <p class="subtitle" data-i18n-html="subtitle">
          Upload a standard <code>wg-quick</code> configuration file. The TV will convert it automatically.
        </p>
      </div>

      <div class="content">
        <form action="/upload" method="post" enctype="multipart/form-data">
          <input id="uploadLang" type="hidden" name="lang" value="en">

          <div class="field">
            <label for="pin" data-i18n="pinLabel">PIN shown on the TV</label>
            <input id="pin" type="text" name="token" inputmode="numeric" autocomplete="one-time-code" required>
            <div class="hint" data-i18n="pinHint">Enter the 4-digit PIN displayed in the WireGuard app.</div>
          </div>

          <div class="field">
            <label for="conf" data-i18n="fileLabel">wg0.conf file</label>
            <input id="conf" type="file" name="conf" accept=".conf,text/plain" required>
            <div class="hint" data-i18n-html="fileHint">Use your normal <code>wg0.conf</code> or <code>wg-quick</code> config.</div>
          </div>

          <button class="submit" type="submit" data-i18n="submit">Upload configuration</button>
        </form>

        <div class="steps" data-i18n-html="steps">
          After uploading it, return to the app and press <b>Stop VPN</b>, then <b>Start VPN</b>.
        </div>
      </div>
    </section>
  </main>

  <script>
    const I18N = {
      en: {
        title: "Upload WireGuard configuration",
        subtitle: 'Upload a standard <code>wg-quick</code> configuration file. The TV will convert it automatically.',
        pinLabel: "PIN shown on the TV",
        pinHint: "Enter the 4-digit PIN displayed in the WireGuard app.",
        fileLabel: "wg0.conf file",
        fileHint: 'Use your normal <code>wg0.conf</code> or <code>wg-quick</code> config.',
        submit: "Upload configuration",
        steps: "After uploading it, return to the app and press <b>Stop VPN</b>, then <b>Start VPN</b>."
      },
      es: {
        title: "Subir configuración WireGuard",
        subtitle: 'Sube un archivo de configuración <code>wg-quick</code> normal. La TV lo convertirá automáticamente.',
        pinLabel: "PIN mostrado en la TV",
        pinHint: "Introduce el PIN de 4 cifras que aparece en la app WireGuard.",
        fileLabel: "Archivo wg0.conf",
        fileHint: 'Usa tu <code>wg0.conf</code> normal o una configuración <code>wg-quick</code>.',
        submit: "Subir configuración",
        steps: "Después de subirla, vuelve a la app y pulsa <b>Parar VPN</b>, y luego <b>Arrancar VPN</b>."
      }
    };

    let currentLang = "en";

    try {
      currentLang = localStorage.getItem("wgUploadLanguage") || "en";
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

      const hidden = document.getElementById("uploadLang");
      if (hidden) hidden.value = currentLang;

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
        localStorage.setItem("wgUploadLanguage", currentLang);
      } catch (e) {}

      applyLanguage();
    }

    document.addEventListener("DOMContentLoaded", applyLanguage);
  </script>
</body>
</html>`

func upload(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		writeError(w, langFromRequest(r), http.StatusMethodNotAllowed, tr(langFromRequest(r), "methodNotAllowed"))
		return
	}

	if err := r.ParseMultipartForm(2 << 20); err != nil {
		lang := langFromRequest(r)
		writeError(w, lang, http.StatusBadRequest, tr(lang, "badUpload"))
		return
	}

	lang := normalizeLang(r.FormValue("lang"))

	if r.FormValue("token") != token {
		writeError(w, lang, http.StatusForbidden, tr(lang, "invalidPin"))
		return
	}

	file, header, err := r.FormFile("conf")
	if err != nil {
		writeError(w, lang, http.StatusBadRequest, tr(lang, "missingFile"))
		return
	}
	defer file.Close()

	data, err := io.ReadAll(io.LimitReader(file, 2<<20))
	if err != nil {
		writeError(w, lang, http.StatusBadRequest, tr(lang, "readFailed"))
		return
	}

	converted, address, err := convertConfig(string(data))
	if err != nil {
		writeError(w, lang, http.StatusBadRequest, tr(lang, "invalidConfig")+": "+err.Error())
		return
	}

	if err := os.MkdirAll(filepath.Join(base, "conf"), 0700); err != nil {
		writeError(w, lang, http.StatusInternalServerError, err.Error())
		return
	}
	if err := os.MkdirAll(filepath.Join(base, "uploads"), 0700); err != nil {
		writeError(w, lang, http.StatusInternalServerError, err.Error())
		return
	}

	ts := time.Now().Format("20060102-150405")
	backup := filepath.Join(base, "uploads", "uploaded-"+ts+"-"+filepath.Base(header.Filename))

	if err := os.WriteFile(backup, data, 0600); err != nil {
		writeError(w, lang, http.StatusInternalServerError, err.Error())
		return
	}

	if err := os.WriteFile(filepath.Join(base, "conf", "wg0.conf"), []byte(converted), 0600); err != nil {
		writeError(w, lang, http.StatusInternalServerError, err.Error())
		return
	}

	if err := os.WriteFile(filepath.Join(base, "conf", "address"), []byte(address+"\n"), 0600); err != nil {
		writeError(w, lang, http.StatusInternalServerError, err.Error())
		return
	}

	writeSuccess(w, lang, backup, address)
}

func langFromRequest(r *http.Request) string {
	if r == nil {
		return "en"
	}

	lang := r.URL.Query().Get("lang")
	if lang == "" {
		lang = r.FormValue("lang")
	}

	return normalizeLang(lang)
}

func normalizeLang(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case "es", "es-es":
		return "es"
	default:
		return "en"
	}
}

func tr(lang string, key string) string {
	m := map[string]map[string]string{
		"en": {
			"methodNotAllowed": "Method not allowed",
			"badUpload":        "The upload could not be processed.",
			"invalidPin":       "Invalid PIN.",
			"missingFile":      "Missing configuration file.",
			"readFailed":       "Could not read the uploaded file.",
			"invalidConfig":    "Invalid WireGuard configuration",
			"successTitle":     "Configuration uploaded",
			"successText":      "Your WireGuard configuration has been saved on the TV.",
			"backup":           "Backup",
			"address":          "Address",
			"next":             "Return to the app and press Stop VPN, then Start VPN.",
			"back":             "Upload another file",
			"errorTitle":       "Upload failed",
		},
		"es": {
			"methodNotAllowed": "Método no permitido",
			"badUpload":        "No se ha podido procesar la subida.",
			"invalidPin":       "PIN incorrecto.",
			"missingFile":      "Falta el archivo de configuración.",
			"readFailed":       "No se ha podido leer el archivo subido.",
			"invalidConfig":    "Configuración WireGuard no válida",
			"successTitle":     "Configuración subida",
			"successText":      "La configuración WireGuard se ha guardado en la TV.",
			"backup":           "Copia de seguridad",
			"address":          "Address",
			"next":             "Vuelve a la app y pulsa Parar VPN, y luego Arrancar VPN.",
			"back":             "Subir otro archivo",
			"errorTitle":       "Error al subir",
		},
	}

	lang = normalizeLang(lang)

	if v, ok := m[lang][key]; ok {
		return v
	}

	return m["en"][key]
}

func writeSuccess(w http.ResponseWriter, lang string, backup string, address string) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	title := html.EscapeString(tr(lang, "successTitle"))
	text := html.EscapeString(tr(lang, "successText"))
	backupLabel := html.EscapeString(tr(lang, "backup"))
	addressLabel := html.EscapeString(tr(lang, "address"))
	next := html.EscapeString(tr(lang, "next"))
	back := html.EscapeString(tr(lang, "back"))

	fmt.Fprintf(w, resultHTML,
		normalizeLang(lang),
		title,
		text,
		backupLabel,
		html.EscapeString(backup),
		addressLabel,
		html.EscapeString(address),
		next,
		back,
	)
}

func writeError(w http.ResponseWriter, lang string, status int, message string) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(status)

	title := html.EscapeString(tr(lang, "errorTitle"))
	text := html.EscapeString(message)
	back := html.EscapeString(tr(lang, "back"))

	fmt.Fprintf(w, errorHTML,
		normalizeLang(lang),
		title,
		http.StatusText(status),
		text,
		back,
	)
}

const resultHTML = `<!doctype html>
<html lang="%s">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>WireGuard webOS upload</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      font-family: Arial, Helvetica, sans-serif;
      background: radial-gradient(circle at top left, rgba(88,240,170,.16), transparent 32rem), #0c1117;
      color: #f4f7fb;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 28px;
    }
    .card {
      width: 100%%;
      max-width: 760px;
      border: 1px solid #2d3d50;
      border-radius: 28px;
      background: linear-gradient(180deg, #162230, #0c1117);
      box-shadow: 0 24px 80px rgba(0,0,0,.4);
      padding: 34px;
    }
    .badge {
      display: inline-block;
      color: #58f0aa;
      background: rgba(88,240,170,.12);
      border-radius: 999px;
      padding: 8px 12px;
      font-weight: bold;
      margin-bottom: 16px;
    }
    h1 { margin: 0 0 12px; font-size: 36px; }
    p { color: #9fb0c4; font-size: 18px; line-height: 1.5; }
    .box {
      margin: 22px 0;
      padding: 18px;
      border-radius: 18px;
      border: 1px solid #2d3d50;
      background: rgba(255,255,255,.03);
    }
    .label { color: #9fb0c4; font-size: 14px; margin-top: 12px; }
    code {
      display: block;
      word-break: break-all;
      color: #fff;
      background: rgba(255,255,255,.08);
      border-radius: 10px;
      padding: 10px;
      margin-top: 6px;
    }
    a {
      display: inline-block;
      margin-top: 18px;
      color: #fff;
      background: #168458;
      text-decoration: none;
      border-radius: 16px;
      padding: 14px 18px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <main class="card">
    <div class="badge">WireGuard · webOS</div>
    <h1>%s</h1>
    <p>%s</p>

    <div class="box">
      <div class="label">%s</div>
      <code>%s</code>

      <div class="label">%s</div>
      <code>%s</code>
    </div>

    <p>%s</p>
    <a href="/">%s</a>
  </main>
</body>
</html>`

const errorHTML = `<!doctype html>
<html lang="%s">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>WireGuard webOS upload</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      font-family: Arial, Helvetica, sans-serif;
      background: radial-gradient(circle at top left, rgba(255,107,107,.16), transparent 32rem), #0c1117;
      color: #f4f7fb;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 28px;
    }
    .card {
      width: 100%%;
      max-width: 760px;
      border: 1px solid #4b3038;
      border-radius: 28px;
      background: linear-gradient(180deg, #231820, #0c1117);
      box-shadow: 0 24px 80px rgba(0,0,0,.4);
      padding: 34px;
    }
    .badge {
      display: inline-block;
      color: #ff8d8d;
      background: rgba(255,107,107,.12);
      border-radius: 999px;
      padding: 8px 12px;
      font-weight: bold;
      margin-bottom: 16px;
    }
    h1 { margin: 0 0 12px; font-size: 36px; }
    .status { color: #9fb0c4; margin-bottom: 18px; }
    p { color: #f4f7fb; font-size: 18px; line-height: 1.5; }
    a {
      display: inline-block;
      margin-top: 18px;
      color: #fff;
      background: #a23535;
      text-decoration: none;
      border-radius: 16px;
      padding: 14px 18px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <main class="card">
    <div class="badge">WireGuard · webOS</div>
    <h1>%s</h1>
    <div class="status">%s</div>
    <p>%s</p>
    <a href="/">%s</a>
  </main>
</body>
</html>`

func convertConfig(input string) (string, string, error) {
	var out []string
	var address string

	allowed := map[string]bool{
		"PrivateKey":          true,
		"ListenPort":          true,
		"FwMark":              true,
		"PublicKey":           true,
		"PresharedKey":        true,
		"AllowedIPs":          true,
		"Endpoint":            true,
		"PersistentKeepalive": true,
	}

	sc := bufio.NewScanner(strings.NewReader(input))

	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())

		if line == "" {
			continue
		}

		if strings.HasPrefix(line, "#") {
			continue
		}

		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			out = append(out, "", line)
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			return "", "", fmt.Errorf("unrecognised line: %s", line)
		}

		key := strings.TrimSpace(parts[0])
		val := strings.TrimSpace(parts[1])

		switch key {
		case "Address":
			if address == "" {
				address = firstIPv4OrFirst(val)
			}
			continue
		case "DNS", "MTU", "Table", "SaveConfig", "PostUp", "PostDown", "PreUp", "PreDown":
			continue
		}

		if !allowed[key] {
			return "", "", fmt.Errorf("unsupported key: %s", key)
		}

		out = append(out, key+" = "+val)
	}

	if err := sc.Err(); err != nil {
		return "", "", err
	}

	if address == "" {
		return "", "", fmt.Errorf("Address not found in the file")
	}

	return strings.TrimSpace(strings.Join(out, "\n")) + "\n", address, nil
}

func firstIPv4OrFirst(s string) string {
	parts := strings.Split(s, ",")
	first := ""
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		if first == "" {
			first = p
		}
		if !strings.Contains(p, ":") {
			return p
		}
	}
	return first
}
