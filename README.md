# WireGuard for LG webOS Homebrew

[English](#english) · [Español](#español)

---

# English

A WireGuard client for rooted LG webOS TVs using Homebrew Channel.

This project provides a simple webOS app that can install, configure, start, stop and monitor a WireGuard VPN tunnel on LG webOS. It uses WireGuard in userspace through `wireguard-go`, because LG webOS stock kernels usually do not include the WireGuard kernel module.

The app is designed for rooted TVs with Homebrew Channel installed.

---

## Features

- WireGuard userspace tunnel using `wireguard-go`
- Bundled `wg`, `wireguard-go` and `wg-upload` binaries
- TV-friendly webOS interface
- English and Spanish UI
- Manual **Install / update** workflow
- No automatic payload installation on app launch
- Temporary web upload server for `wg0.conf`
- Time-limited configuration upload protected by a random access code and failed-attempt lockout
- Start, stop, status, routes, config and log actions
- Optional autostart on boot
- Runtime uninstall action
- PayPal donation QR popup

---

## Why userspace WireGuard?

On normal Linux systems, WireGuard usually runs as a kernel module.

On LG webOS TVs, the WireGuard kernel module is normally not available in the stock kernel. For that reason, this project uses:

- `wireguard-go` to create the WireGuard interface in userspace
- `wg` from `wireguard-tools` to configure the tunnel
- a TUN interface created from userspace

This makes it possible to run WireGuard without building or installing a custom webOS kernel.

---

## Requirements

- Rooted LG webOS TV
- Homebrew Channel installed
- Homebrew root service available
- `/dev/net/tun` support on the TV
- Compatible CPU architecture

The bundled binaries in the current release are built for:

```text
linux/armv7 (32-bit ARM)
```

Check your TV architecture with:

```sh
uname -m
```

The bundled ARMv7 binaries also run on supported 64-bit LG TVs.

---

## Installation

### 1. Download or build the IPK

Release package:

```text
com.github.cfernande1470.wireguard_1.0.4_all.ipk
```

To package manually:

```sh
make package
```

Packaging requires `ares-package` from either LG's `@webos-tools/cli` or
webOSBrew's `ares-cli-rs`. Set `ARES_PACKAGE=/path/to/ares-package` when it is
not available on `PATH`. The package is forced to architecture `all` because
the bundled ARMv7 binaries run on both 32-bit and 64-bit TVs.

Output:

```text
dist/com.github.cfernande1470.wireguard_1.0.4_all.ipk
```

### 2. Install using Homebrew Channel

Copy or upload the IPK to your TV and install it from Homebrew Channel.

### 3. Open the app

After launching the app, press:

```text
Install / update
```

This prepares persistent state under:

```text
/var/lib/webosbrew/wireguard
```

The packaged binaries and scripts stay inside the application directory. The state directory only contains the
configuration, logs, runtime files, and symlinks to the packaged payload, so updates take effect without duplicating
the binaries. The app does not prepare this state automatically; this is intentional.

---

## First-time setup

1. Open the WireGuard app on the TV.
2. Press **Install / update**.
3. Press **Upload config**.
4. Open the displayed URL from a computer or phone on the same LAN.
5. Enter the displayed access code.
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

Example:

```ini
[Interface]
PrivateKey = REPLACE_WITH_CLIENT_PRIVATE_KEY
Address = 10.10.10.2/32

[Peer]
PublicKey = REPLACE_WITH_SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = vpn.example.invalid:51820
PersistentKeepalive = 25
```

---

## Configuration handling

The uploader accepts normal `wg-quick` style configuration files and converts them for `wg setconf`.

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
```

Ignored fields:

```text
DNS
MTU
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

The converted WireGuard config is stored as:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

A backup of every uploaded config is stored in:

```text
/var/lib/webosbrew/wireguard/uploads
```

DNS handling is not implemented in version `1.0.2`.

Uploaded `MTU` values are ignored by the uploader. The start script uses a default tunnel MTU of `1420`.

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

This is intentional for version `1.0.2`.

---

## Autostart

The app can enable WireGuard autostart.

When enabled, it creates:

```text
/var/lib/webosbrew/init.d/90-wireguard
```

This is a symlink to the packaged `boot.sh`. At boot, the script waits for a default route and then starts WireGuard.
If the app is removed, the link becomes non-executable and the Homebrew hook runner skips it.

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

GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/com.github.cfernande1470.wireguard/payload/wireguard/bin/wg-upload \
  ./wg-upload.go

cd ..
```

### Build `wireguard-go`

```sh
cd wireguard-go

GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/com.github.cfernande1470.wireguard/payload/wireguard/bin/wireguard-go .

cd ..
```

### Build for ARMv7

For all supported TVs:

```sh
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build ...
```

All bundled binaries must remain 32-bit ARM to support both 32-bit and 64-bit LG TVs.

Check binaries with:

```sh
file app/com.github.cfernande1470.wireguard/payload/wireguard/bin/*
```

---

## Troubleshooting

### Updating from 1.0.1

Run **Install / update** once. The installer stops the old runtime, removes the copied payload, replaces it with
symlinks to the packaged files, and preserves the existing configuration.

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

DNS handling is not implemented in version `1.0.2`.

Use IP-based tests first, for example:

```sh
curl -4 http://ifconfig.me/ip
```

---

## Security notes

Your private key is stored on the TV in:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

The upload server uses a random eight-character access code. It stops after one successful upload, five incorrect
codes, or ten minutes. The connection is still plain HTTP, so it should only be used on a trusted LAN.

Do not publish real `wg0.conf` files or logs containing private data.

---

## Project layout

```text
app/com.github.cfernande1470.wireguard/
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
      boot.sh
      uninstall.sh

examples/
  wg0.example.conf

uploader/
  wg-upload.go

wireguard-go/
wireguard-tools/
```

---

## Changelog

### 1.0.4

Changed:

- Refresh the TV interface with a compact dashboard layout, clearer status panel, and improved remote-friendly controls

### 1.0.3

Fixed:

- Add explicit five-way remote navigation for arrow keys and OK/Enter
- Handle the Back key for upload and donation dialogs

### 1.0.2

Changed:

- Keep binaries and scripts in the application directory and link to them instead of copying the payload
- Use a symlinked boot hook so removing the app cannot keep starting the VPN
- Preserve only configuration, logs, and runtime state under `/var/lib/webosbrew/wireguard`
- Replace the four-digit PIN with a random eight-character access code
- Stop the upload server after one successful upload or ten minutes, and lock it after five incorrect codes
- Package releases with the standard `ares-package` tool instead of a custom IPK builder

### 1.0.1

Fixed:

- Renamed the application and package consistently to `com.github.cfernande1470.wireguard`
- Rebuilt all bundled executables for 32-bit ARMv7 compatibility
- Added an MIT licence and reproducible build, package and release verification scripts

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
- Current bundled binaries are built for 32-bit `linux/armv7`.
- IPv6 and DNS handling are not implemented in this release.

---

## License

The app-specific code is licensed under the [MIT License](LICENSE). Bundled WireGuard components retain their own licences:

```text
wireguard-go/LICENSE
wireguard-tools/COPYING
```

---

# Español

Cliente WireGuard para televisores LG webOS con root y Homebrew Channel.

Este proyecto proporciona una app sencilla para webOS que permite instalar, configurar, arrancar, parar y monitorizar un túnel VPN WireGuard en LG webOS. Usa WireGuard en userspace mediante `wireguard-go`, porque los kernels stock de LG webOS normalmente no incluyen el módulo WireGuard en el kernel.

La app está pensada para televisores con root y Homebrew Channel instalado.

---

## Funciones

- Túnel WireGuard en userspace usando `wireguard-go`
- Binarios incluidos: `wg`, `wireguard-go` y `wg-upload`
- Interfaz adaptada a TV
- Interfaz en inglés y español
- Flujo manual de **Instalar / actualizar**
- Sin instalación automática del payload al abrir la app
- Servidor web temporal para subir `wg0.conf`
- Subida temporal protegida por un código aleatorio, con caducidad y bloqueo tras varios intentos fallidos
- Acciones de arrancar, parar, estado, rutas, configuración y log
- Inicio automático opcional al arrancar
- Acción de desinstalación del runtime
- Popup de donación con QR de PayPal

---

## ¿Por qué WireGuard en userspace?

En Linux normal, WireGuard suele funcionar como módulo del kernel.

En televisores LG webOS, el módulo WireGuard normalmente no está disponible en el kernel de fábrica. Por eso este proyecto usa:

- `wireguard-go` para crear la interfaz WireGuard desde userspace
- `wg` de `wireguard-tools` para configurar el túnel
- una interfaz TUN creada desde userspace

Así se puede usar WireGuard sin compilar ni instalar un kernel personalizado para webOS.

---

## Requisitos

- TV LG webOS con root
- Homebrew Channel instalado
- Servicio root de Homebrew disponible
- Soporte para `/dev/net/tun` en la TV
- Arquitectura de CPU compatible

Los binarios incluidos actualmente están compilados para:

```text
linux/armv7 (32-bit ARM)
```

Comprueba la arquitectura de tu TV con:

```sh
uname -m
```

Los binarios ARMv7 incluidos también funcionan en televisores LG de 64 bits compatibles.

---

## Instalación

### 1. Descargar o compilar el IPK

Paquete de release:

```text
com.github.cfernande1470.wireguard_1.0.4_all.ipk
```

Para empaquetar manualmente:

```sh
make package
```

El empaquetado requiere `ares-package`, incluido tanto en `@webos-tools/cli`
de LG como en `ares-cli-rs` de webOSBrew. Si no está disponible en `PATH`, usa
`ARES_PACKAGE=/ruta/a/ares-package`. El paquete fuerza la arquitectura `all`
porque los binarios ARMv7 incluidos funcionan en televisores de 32 y 64 bits.

Resultado:

```text
dist/com.github.cfernande1470.wireguard_1.0.4_all.ipk
```

### 2. Instalar usando Homebrew Channel

Copia o sube el IPK a la TV e instálalo desde Homebrew Channel.

### 3. Abrir la app

Después de abrir la app, pulsa:

```text
Instalar / actualizar
```

Esto prepara el estado persistente en:

```text
/var/lib/webosbrew/wireguard
```

Los binarios y scripts permanecen dentro del directorio de la aplicación. El directorio de estado solo contiene la
configuración, los logs, los datos de ejecución y enlaces al payload empaquetado, por lo que las actualizaciones se
aplican sin duplicar los binarios. La app no prepara este estado automáticamente; esto es intencionado.

---

## Primer uso

1. Abre la app WireGuard en la TV.
2. Pulsa **Instalar / actualizar**.
3. Pulsa **Subir config**.
4. Abre la URL mostrada desde un ordenador o móvil en la misma LAN.
5. Introduce el código de acceso mostrado.
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

Ejemplo:

```ini
[Interface]
PrivateKey = REPLACE_WITH_CLIENT_PRIVATE_KEY
Address = 10.10.10.2/32

[Peer]
PublicKey = REPLACE_WITH_SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = vpn.example.invalid:51820
PersistentKeepalive = 25
```

---

## Gestión de la configuración

El uploader acepta configuraciones normales de tipo `wg-quick` y las convierte para `wg setconf`.

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
```

Campos ignorados:

```text
DNS
MTU
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

La gestión de DNS no está implementada en la versión `1.0.2`.

Los valores `MTU` subidos se ignoran en el uploader. El script de arranque usa una MTU de túnel por defecto de `1420`.

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

Esto es intencionado en la versión `1.0.2`.

---

## Inicio automático

La app puede activar WireGuard al arrancar.

Cuando está activado, crea:

```text
/var/lib/webosbrew/init.d/90-wireguard
```

Es un enlace al `boot.sh` incluido en la app. Durante el arranque, el script espera a que exista una ruta por defecto
y luego inicia WireGuard. Si se elimina la app, el enlace deja de ser ejecutable y Homebrew lo ignora.

---

## Desinstalación

El botón **Desinstalar** detiene WireGuard y elimina:

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

GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/com.github.cfernande1470.wireguard/payload/wireguard/bin/wg-upload \
  ./wg-upload.go

cd ..
```

### Compilar `wireguard-go`

```sh
cd wireguard-go

GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" \
  -o ../app/com.github.cfernande1470.wireguard/payload/wireguard/bin/wireguard-go .

cd ..
```

### Compilar para ARMv7

Para todos los televisores compatibles:

```sh
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build ...
```

Todos los binarios incluidos deben seguir siendo ARM de 32 bits para admitir televisores LG de 32 y 64 bits.

Comprueba los binarios con:

```sh
file app/com.github.cfernande1470.wireguard/payload/wireguard/bin/*
```

---

## Solución de problemas

### Actualizar desde 1.0.1

Pulsa **Instalar / actualizar** una vez. El instalador detiene el runtime antiguo, elimina la copia del payload, la
sustituye por enlaces a los archivos incluidos en la app y conserva la configuración existente.

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

La gestión de DNS no está implementada en la versión `1.0.2`.

Prueba primero con IP pública:

```sh
curl -4 http://ifconfig.me/ip
```

---

## Seguridad

Tu clave privada se guarda en la TV en:

```text
/var/lib/webosbrew/wireguard/conf/wg0.conf
```

El servidor de subida usa un código de acceso aleatorio de ocho caracteres. Se detiene tras una subida correcta,
cinco códigos incorrectos o diez minutos. La conexión sigue siendo HTTP sin cifrar, por lo que solo debe usarse en
una LAN de confianza.

No publiques configuraciones reales ni logs con datos privados.

---

## Estructura del proyecto

```text
app/com.github.cfernande1470.wireguard/
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
      boot.sh
      uninstall.sh

examples/
  wg0.example.conf

uploader/
  wg-upload.go

wireguard-go/
wireguard-tools/
```

---

## Registro de cambios

### 1.0.4

Cambios:

- Renovada la interfaz de TV con un dashboard compacto, estado más claro y controles mejorados para el mando

### 1.0.3

Corregido:

- Añadida navegación explícita con las flechas del mando y activación con OK/Enter
- El botón Back cierra los diálogos de subida y donación

### 1.0.2

Cambios:

- Los binarios y scripts permanecen en la aplicación y se enlazan en lugar de copiar el payload
- El hook de arranque es un enlace, así que eliminar la app no puede seguir iniciando la VPN
- Solo la configuración, los logs y el estado de ejecución permanecen en `/var/lib/webosbrew/wireguard`
- El PIN de cuatro cifras se sustituye por un código de acceso aleatorio de ocho caracteres
- El servidor se detiene tras una subida correcta o diez minutos y se bloquea tras cinco códigos incorrectos
- Las releases se empaquetan con la herramienta estándar `ares-package` en lugar de un generador IPK propio

### 1.0.1

Corregido:

- Renombrado coherente de la aplicación y el paquete a `com.github.cfernande1470.wireguard`
- Recompilación de todos los ejecutables incluidos para ARMv7 de 32 bits
- Añadida la licencia MIT y scripts reproducibles de compilación, empaquetado y verificación

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
- Los binarios incluidos actualmente están compilados para `linux/armv7` de 32 bits.
- IPv6 y gestión de DNS no están implementados en esta versión.

---

## Licencia

El código específico de la app está publicado bajo la [licencia MIT](LICENSE). Los componentes de WireGuard incluidos conservan sus propias licencias:

```text
wireguard-go/LICENSE
wireguard-tools/COPYING
```
