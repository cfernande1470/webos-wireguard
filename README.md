# WireGuard for LG webOS Homebrew

A WireGuard client for rooted LG webOS TVs using Homebrew Channel.

This project provides a simple webOS app that can install, configure, start, stop and monitor a WireGuard VPN tunnel on LG webOS. It uses **WireGuard in userspace** through `wireguard-go`, because LG webOS builds generally do not include the WireGuard kernel module.

The app is designed for rooted TVs with Homebrew Channel installed.

---

## Features

- WireGuard userspace tunnel using `wireguard-go`
- Bundled `wg`, `wireguard-go` and upload helper binaries
- Simple TV-friendly webOS UI
- English and Spanish UI
- Manual **Install / update** button for runtime components
- No automatic payload installation on app launch
- Temporary web upload server for `wg0.conf`
- PIN-protected configuration upload
- Start / stop / status / routes / config / logs from the app
- Optional autostart on boot
- Uninstall button to remove runtime files
- PayPal donation QR popup

---

## Why userspace WireGuard?

On standard Linux systems, WireGuard usually runs as a kernel module. On LG webOS TVs, the WireGuard kernel module is normally not available in the stock kernel, so this project uses:

- `wireguard-go` for the userspace WireGuard interface
- `wg` from `wireguard-tools` to configure the tunnel
- a TUN interface created from userspace

This makes it possible to run WireGuard without needing a custom webOS kernel.

---

## Requirements

- Rooted LG webOS TV
- Homebrew Channel installed
- Homebrew root service available
- `/dev/net/tun` support on the TV
- A compatible CPU architecture

The bundled binaries in the current package are built for:

```text
linux/arm64 / aarch64
```

Check your TV architecture with:

```sh
uname -m
```

If your TV is `armv7l`, you need to rebuild the binaries for ARMv7.

---

## Installation

### 1. Build or download the IPK

The packaged app is:

```text
org.webosbrew.wireguard_1.0.0_all.ipk
```

To package it manually:

```sh
rm -rf dist
mkdir -p dist
ares-package -o dist app/org.webosbrew.wireguard
```

The output will be:

```text
dist/org.webosbrew.wireguard_1.0.0_all.ipk
```

### 2. Install using Homebrew Channel

Copy or upload the IPK to your TV and install it from Homebrew Channel.

### 3. Open the app

After launching the app, press:

```text
Install / update
```

This copies the bundled runtime files to:

```text
/var/lib/webosbrew/wireguard
```

Runtime files include:

```text
/var/lib/webosbrew/wireguard/bin/wg
/var/lib/webosbrew/wireguard/bin/wireguard-go
/var/lib/webosbrew/wireguard/bin/wg-upload
/var/lib/webosbrew/wireguard/scripts/*.sh
/var/lib/webosbrew/wireguard/conf
/var/lib/webosbrew/wireguard/run
```

The app does **not** install the payload automatically. This is intentional.

---

## First-time setup

1. Open the WireGuard app on the TV.
2. Press **Install / update**.
3. Press **Upload config**.
4. Open the displayed URL from a computer or phone on the same LAN.
5. Enter the displayed PIN.
6. Upload your `wg0.conf`.
7. Return to the TV.
8. Press **Start VPN**.
9. Use **Status** or **Log** to verify the tunnel.

---

## Example configuration

A safe example configuration is included at:

```text
examples/wg0.example.conf
```

Copy it, replace the placeholder keys and endpoint, then upload your real `wg0.conf` from the app.

Do not commit real WireGuard configuration files. They contain private keys and private VPN details.

---

## Configuration format

Upload a normal `wg-quick` style config, for example:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.2/32
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = vpn.example.com:51820
PersistentKeepalive = 25
```

The uploader converts the config for `wg setconf`.

Handled fields:

```text
PrivateKey
ListenPort
FwMark
PublicKey
PresharedKey
AllowedIPs
Endpoint
PersistentKeepalive
Address
MTU
```

Ignored fields:

```text
DNS
Table
SaveConfig
PreUp
PostUp
PreDown
PostDown
```

`Address` is extracted and stored separately in:

```text
/var/lib/webosbrew/wireguard/conf/address
```

The converted config is stored as:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

A backup of every uploaded config is stored in:

```text
/var/lib/webosbrew/wireguard/uploads
```

---

## Full-tunnel routing

If your config contains:

```ini
AllowedIPs = 0.0.0.0/0
```

the start script converts it into split default routes:

```text
0.0.0.0/1
128.0.0.0/1
```

This avoids replacing the default route directly and tends to behave better on webOS.

The VPN endpoint is pinned outside the tunnel using the original default route, so WireGuard can still reach the server after the tunnel starts.

---

## IPv6 status

IPv6 routes and IPv6 addresses are currently ignored.

This is intentional for version `1.0.0`.

---

## Autostart

The app can enable WireGuard autostart.

When enabled, it creates:

```text
/var/lib/webosbrew/init.d/90-wireguard
```

At boot, the script waits for a default route and then starts WireGuard.

Disable it from the app before uninstalling if needed.

---

## Uninstall

The **Uninstall** button stops WireGuard and removes:

```text
/var/lib/webosbrew/wireguard
/var/lib/webosbrew/init.d/90-wireguard
/var/run/wireguard/wg0.sock
```

After that, you can remove the app from Homebrew Channel.

---

## Build notes

### Build `wg-upload`

```sh
cd uploader

GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/org.webosbrew.wireguard/payload/wireguard/bin/wg-upload \
  ./wg-upload.go

cd ..
```

### Build `wireguard-go`

```sh
cd wireguard-go

GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/org.webosbrew.wireguard/payload/wireguard/bin/wireguard-go .

cd ..
```

### Build for ARMv7

For older ARMv7 TVs:

```sh
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build ...
```

Make sure every bundled binary matches the TV architecture.

Check binaries with:

```sh
file app/org.webosbrew.wireguard/payload/wireguard/bin/*
```

---

## Troubleshooting

### `Text file busy` during install/update

This means a binary was still running while being replaced.

The installer stops `wireguard-go` and `wg-upload` before copying new binaries.

Run **Install / update** again.

### `ERROR luna-call`

This usually means the Homebrew root service failed or rejected the command.

Check that Homebrew Channel and its root service are working.

From the TV over SSH:

```sh
luna-send -n 1 'luna://org.webosbrew.hbchannel.service/exec' '{"command":"id; echo OK"}'
```

### `interface was not created`

Check TUN support:

```sh
ls -l /dev/net/tun
```

### VPN starts but traffic does not route

Open **Routes** and **Log** from the app.

Check:

```sh
ip route
ip addr show wg0
wg show wg0
```

### Uploaded config works but DNS does not change

DNS handling is not implemented in version `1.0.0`.

Use IP-based tests first, for example:

```sh
curl -4 http://ifconfig.me/ip
```

---

## Security notes

- Your private key is stored on the TV in:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

- The config upload server is temporary and PIN-protected.
- The upload server should only be used on a trusted LAN.
- Close the upload popup to stop the temporary upload server.
- Do not publish real `wg0.conf` files or logs containing private data.

---

## Project layout

```text
app/org.webosbrew.wireguard/
  appinfo.json
  index.html
  css/
  js/
  lib/
  qrcode.png
  payload/wireguard/
    install.sh
    bin/
      wg
      wireguard-go
      wg-upload
    scripts/
      start.sh
      stop.sh
      status.sh
      upload-start.sh
      upload-stop.sh
      autostart.sh
      uninstall.sh

uploader/
  wg-upload.go

wireguard-go/
wireguard-tools/
```

---

## Changelog

### 1.0.0

Initial stable release.

Added:

- LG webOS Homebrew app for WireGuard
- Userspace WireGuard support through `wireguard-go`
- Bundled `wg`, `wireguard-go` and `wg-upload`
- Manual Install / update workflow
- No automatic payload installation on app startup
- Bilingual UI: English and Spanish
- Bilingual upload web server
- PIN-protected `wg0.conf` upload
- Start, stop, status, routes, config and log actions
- Optional autostart on boot
- Runtime uninstall action
- PayPal donation QR popup

Notes:

- WireGuard runs in userspace because the WireGuard kernel module is not normally available on LG webOS stock kernels.
- Current bundled binaries are built for `linux/arm64`.
- IPv6 and DNS handling are not implemented in this release.

---

## License

This project bundles or uses components from WireGuard projects. Check the license files included in the repository:

```text
wireguard-go/LICENSE
wireguard-tools/COPYING
```

Your own app code should be licensed separately if you publish the repository.

---

# WireGuard para LG webOS Homebrew

Cliente WireGuard para televisores LG webOS con root y Homebrew Channel.

Este proyecto proporciona una app sencilla para webOS que permite instalar, configurar, arrancar, parar y monitorizar un túnel VPN WireGuard en LG webOS. Usa **WireGuard en userspace** mediante `wireguard-go`, porque las compilaciones normales de LG webOS aparentemente no incluyen el módulo WireGuard en el kernel.

La app está pensada para televisores con root y Homebrew Channel instalado.

---

## Funciones

- Túnel WireGuard en userspace usando `wireguard-go`
- Binarios incluidos: `wg`, `wireguard-go` y helper de subida
- Interfaz sencilla adaptada a TV
- Interfaz en inglés y español
- Botón manual **Instalar / actualizar** para los componentes runtime
- Sin instalación automática del payload al abrir la app
- Servidor web temporal para subir `wg0.conf`
- Subida de configuración protegida con PIN
- Arrancar / parar / estado / rutas / configuración / logs desde la app
- Inicio automático opcional al arrancar
- Botón de desinstalación para eliminar los ficheros runtime
- Popup de donación con QR de PayPal

---

## ¿Por qué WireGuard en userspace?

En Linux normal, WireGuard suele funcionar como módulo del kernel. En televisores LG webOS, el módulo WireGuard normalmente no está disponible en el kernel de fábrica, así que este proyecto usa:

- `wireguard-go` para crear la interfaz WireGuard desde userspace
- `wg` de `wireguard-tools` para configurar el túnel
- una interfaz TUN creada desde userspace

Así se puede usar WireGuard sin tener que compilar o instalar un kernel personalizado para webOS.

---

## Requisitos

- TV LG webOS con root
- Homebrew Channel instalado
- Servicio root de Homebrew disponible
- Soporte para `/dev/net/tun` en la TV
- Arquitectura de CPU compatible

Los binarios incluidos actualmente están compilados para:

```text
linux/arm64 / aarch64
```

Comprueba la arquitectura de tu TV con:

```sh
uname -m
```

Si tu TV es `armv7l`, tendrás que recompilar los binarios para ARMv7.

---

## Instalación

### 1. Compilar o descargar el IPK

La app empaquetada es:

```text
org.webosbrew.wireguard_1.0.0_all.ipk
```

Para empaquetarla manualmente:

```sh
rm -rf dist
mkdir -p dist
ares-package -o dist app/org.webosbrew.wireguard
```

El resultado será:

```text
dist/org.webosbrew.wireguard_1.0.0_all.ipk
```

### 2. Instalar usando Homebrew Channel

Copia o sube el IPK a la TV e instálalo desde Homebrew Channel.

### 3. Abrir la app

Después de abrir la app, pulsa:

```text
Instalar / actualizar
```

Esto copia los componentes incluidos a:

```text
/var/lib/webosbrew/wireguard
```

Ficheros runtime principales:

```text
/var/lib/webosbrew/wireguard/bin/wg
/var/lib/webosbrew/wireguard/bin/wireguard-go
/var/lib/webosbrew/wireguard/bin/wg-upload
/var/lib/webosbrew/wireguard/scripts/*.sh
/var/lib/webosbrew/wireguard/conf
/var/lib/webosbrew/wireguard/run
```

La app **no** instala el payload automáticamente. Esto es intencionado.

---

## Primer uso

1. Abre la app WireGuard en la TV.
2. Pulsa **Instalar / actualizar**.
3. Pulsa **Subir config**.
4. Abre la URL mostrada desde un ordenador o móvil en la misma LAN.
5. Introduce el PIN mostrado.
6. Sube tu `wg0.conf`.
7. Vuelve a la TV.
8. Pulsa **Arrancar VPN**.
9. Usa **Estado** o **Log** para verificar el túnel.

---

## Configuración de ejemplo

Se incluye una configuración de ejemplo segura en:

```text
examples/wg0.example.conf
```

Cópiala, sustituye las claves y el endpoint de ejemplo, y luego sube tu `wg0.conf` real desde la app.

No subas configuraciones WireGuard reales al repositorio. Contienen claves privadas y datos privados de tu VPN.

---

## Formato de configuración

Puedes subir una configuración normal de `wg-quick`, por ejemplo:

```ini
[Interface]
PrivateKey = TU_CLAVE_PRIVADA
Address = 10.0.0.2/32
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = CLAVE_PUBLICA_SERVIDOR
AllowedIPs = 0.0.0.0/0
Endpoint = vpn.example.com:51820
PersistentKeepalive = 25
```

El uploader la convierte a un formato compatible con `wg setconf`.

Campos gestionados:

```text
PrivateKey
ListenPort
FwMark
PublicKey
PresharedKey
AllowedIPs
Endpoint
PersistentKeepalive
Address
MTU
```

Campos ignorados:

```text
DNS
Table
SaveConfig
PreUp
PostUp
PreDown
PostDown
```

`Address` se extrae y se guarda aparte en:

```text
/var/lib/webosbrew/wireguard/conf/address
```

La configuración convertida se guarda como:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

Cada configuración subida se copia como backup en:

```text
/var/lib/webosbrew/wireguard/uploads
```

---

## Rutas full tunnel

Si tu configuración contiene:

```ini
AllowedIPs = 0.0.0.0/0
```

el script de arranque lo convierte en dos medias rutas:

```text
0.0.0.0/1
128.0.0.0/1
```

Esto evita reemplazar directamente la ruta por defecto y suele funcionar mejor en webOS.

La ruta hacia el endpoint VPN se fija fuera del túnel usando la ruta por defecto original, para que WireGuard pueda seguir llegando al servidor después de levantar el túnel.

---

## Estado de IPv6

Las rutas IPv6 y direcciones IPv6 se ignoran actualmente.

Esto es intencionado en la versión `1.0.0`.

---

## Inicio automático

La app puede activar WireGuard al arrancar.

Cuando está activado, crea:

```text
/var/lib/webosbrew/init.d/90-wireguard
```

Durante el arranque, el script espera a que exista una ruta por defecto y luego inicia WireGuard.

Puedes desactivarlo desde la app.

---

## Desinstalación

El botón **Desinstalar** para WireGuard y elimina:

```text
/var/lib/webosbrew/wireguard
/var/lib/webosbrew/init.d/90-wireguard
/var/run/wireguard/wg0.sock
```

Después puedes eliminar la app desde Homebrew Channel.

---

## Notas de compilación

### Compilar `wg-upload`

```sh
cd uploader

GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/org.webosbrew.wireguard/payload/wireguard/bin/wg-upload \
  ./wg-upload.go

cd ..
```

### Compilar `wireguard-go`

```sh
cd wireguard-go

GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/org.webosbrew.wireguard/payload/wireguard/bin/wireguard-go .

cd ..
```

### Compilar para ARMv7

Para TVs antiguas ARMv7:

```sh
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build ...
```

Asegúrate de que todos los binarios incluidos coinciden con la arquitectura de la TV.

Comprueba los binarios con:

```sh
file app/org.webosbrew.wireguard/payload/wireguard/bin/*
```

---

## Solución de problemas

### `Text file busy` durante Install / update

Significa que un binario seguía ejecutándose mientras se intentaba reemplazar.

El instalador para `wireguard-go` y `wg-upload` antes de copiar binarios nuevos.

Pulsa **Instalar / actualizar** otra vez.

### `ERROR luna-call`

Normalmente significa que el servicio root de Homebrew ha fallado o ha rechazado el comando.

Comprueba que Homebrew Channel y su servicio root funcionan.

Desde SSH en la TV:

```sh
luna-send -n 1 'luna://org.webosbrew.hbchannel.service/exec' '{"command":"id; echo OK"}'
```

### `interface was not created`

Comprueba soporte TUN:

```sh
ls -l /dev/net/tun
```

### La VPN arranca pero el tráfico no va por el túnel

Abre **Rutas** y **Log** desde la app.

Comprueba:

```sh
ip route
ip addr show wg0
wg show wg0
```

### La configuración sube bien pero DNS no cambia

La gestión de DNS no está implementada en la versión `1.0.0`.

Prueba primero con IP pública:

```sh
curl -4 http://ifconfig.me/ip
```

---

## Seguridad

- Tu clave privada se guarda en la TV en:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

- El servidor de subida es temporal y está protegido con PIN.
- Usa el servidor de subida solo en una red LAN de confianza.
- Cierra el popup de subida para parar el servidor temporal.
- No publiques configuraciones reales ni logs con datos privados.

---

## Estructura del proyecto

```text
app/org.webosbrew.wireguard/
  appinfo.json
  index.html
  css/
  js/
  lib/
  qrcode.png
  payload/wireguard/
    install.sh
    bin/
      wg
      wireguard-go
      wg-upload
    scripts/
      start.sh
      stop.sh
      status.sh
      upload-start.sh
      upload-stop.sh
      autostart.sh
      uninstall.sh

uploader/
  wg-upload.go

wireguard-go/
wireguard-tools/
```

---

## Registro de cambios

### 1.0.0

Primera versión estable.

Añadido:

- App LG webOS Homebrew para WireGuard
- Soporte WireGuard en userspace mediante `wireguard-go`
- Binarios incluidos: `wg`, `wireguard-go` y `wg-upload`
- Flujo manual de Instalar / actualizar
- Sin instalación automática del payload al abrir la app
- Interfaz bilingüe: inglés y español
- Servidor web de subida bilingüe
- Subida de `wg0.conf` protegida por PIN
- Acciones de arrancar, parar, estado, rutas, configuración y log
- Inicio automático opcional al arrancar
- Acción de desinstalación del runtime
- Popup de donación con QR de PayPal

Notas:

- WireGuard se ejecuta en userspace porque el módulo WireGuard del kernel no suele estar disponible en kernels stock de LG webOS.
- Los binarios incluidos actualmente están compilados para `linux/arm64`.
- IPv6 y gestión de DNS no están implementados en esta versión.

---

## Licencia

Este proyecto incluye o usa componentes de WireGuard. Revisa los ficheros de licencia incluidos en el repositorio:

```text
wireguard-go/LICENSE
wireguard-tools/COPYING
```

El código propio de la app debería llevar una licencia separada si publicas el repositorio.
