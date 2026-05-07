<div align="center">

<img src="k8s.png" alt="K8S Setup" width="700"/>

**Un instalador de herramientas Kubernetes para cualquier distro Linux.**  
Ejecuta un comando. Elige qué instalar. Listo.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://github.com/insanerask77/k8s-setup/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/insanerask77/k8s-setup/actions/workflows/shellcheck.yml)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20amd64%20%7C%20arm64-lightgrey)](https://github.com/insanerask77/k8s-setup)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/insanerask77/k8s-setup/main/install.sh | bash
```

### Instalar todo sin interacción

```bash
curl -fsSL https://raw.githubusercontent.com/insanerask77/k8s-setup/main/install.sh | bash -s -- --auto
```

### Seleccionar herramientas específicas

```bash
curl -fsSL https://raw.githubusercontent.com/insanerask77/k8s-setup/main/install.sh | bash -s -- --tools kubectl,helm,k9s
```

### Usar a través de un proxy HTTP/HTTPS

```bash
curl -fsSL https://raw.githubusercontent.com/insanerask77/k8s-setup/main/install.sh | bash -s -- --proxy http://proxy.empresa.com:3128

# Con autenticación
curl -fsSL https://raw.githubusercontent.com/insanerask77/k8s-setup/main/install.sh | bash -s -- --proxy http://usuario:contraseña@proxy.empresa.com:3128

# Combinado con otras flags
curl -fsSL https://raw.githubusercontent.com/insanerask77/k8s-setup/main/install.sh | bash -s -- --auto --proxy http://proxy.empresa.com:3128
```

---

## Menú interactivo

Al ejecutar sin flags se abre un menú navegable en la terminal:

```
  ╔══════════════════════════════════════════════════╗
  ║  ⎈  k8s-setup — Seleccionar herramientas        ║
  ╠══════════════════════════════════════════════════╣
  ║   ✔ ⎈  kubectl        CLI oficial de Kubernetes ║
  ║   ✔ ⛵  helm           Package manager           ║
  ║ ❯ ✔ 🐶  k9s            TUI para workloads        ║
  ║   ✔ 🔀  kubectx        Cambiar entre contextos   ║
  ║   ✔ 📦  kubens         Cambiar entre namespaces  ║
  ║   ✔ ⚡  kubectl-aliases ~200 aliases             ║
  ╠══════════════════════════════════════════════════╣
  ║  ████████████████████  6/6 seleccionadas         ║
  ╠══════════════════════════════════════════════════╣
  ║  ↑↓ Mover  SPACE Toggle  A Todo/Nada  ENTER OK  ║
  ╚══════════════════════════════════════════════════╝
```

---

## Herramientas incluidas

| Herramienta | Descripción | Versión |
|---|---|---|
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | CLI oficial para interactuar con clusters | latest stable |
| [helm](https://helm.sh/) | Package manager para Kubernetes | latest |
| [k9s](https://k9scli.io/) | TUI para inspeccionar y gestionar workloads | latest |
| [kubectx](https://github.com/ahmetb/kubectx) | Cambiar entre contextos de Kubernetes | latest |
| [kubens](https://github.com/ahmetb/kubectx) | Cambiar entre namespaces rápidamente | latest |
| [kubectl-aliases](https://github.com/ahmetb/kubectl-aliases) | ~200 aliases bash/zsh para kubectl | latest |

Todas las versiones se resuelven en tiempo de ejecución consultando la API de GitHub o los canales oficiales — siempre instala lo más reciente.

---

## Distros soportadas

| Distro | Package Manager |
|---|---|
| Ubuntu, Debian, Linux Mint, Pop!_OS | `apt` |
| Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux | `dnf` / `yum` |
| openSUSE, SLES | `zypper` |
| Arch Linux, Manjaro, EndeavourOS | `pacman` |
| Alpine Linux | `apk` |
| Cualquier Linux con `curl` + `tar` | instalación directa |

Arquitecturas: `amd64` (x86_64) y `arm64` (aarch64).

---

## Sin dependencias previas

El script detecta si faltan `curl`, `tar` o `gzip` e **los instala automáticamente** usando el package manager del sistema antes de continuar. Para el menú interactivo usa `whiptail` si está disponible; si no, lo instala o cae en un menú bash puro.

---

## Flags disponibles

| Flag | Descripción |
|---|---|
| `--auto` / `-a` | Instala todas las herramientas sin interacción |
| `--tools x,y,z` | Instala solo las herramientas listadas |
| `--proxy <url>` | Enruta todas las descargas a través del proxy indicado |
| `--help` / `-h` | Muestra la ayuda |

### Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `INSTALL_DIR` | `/usr/local/bin` | Directorio donde se instalan los binarios |

> **Entornos con proxy:** el flag `--proxy` configura automáticamente `http_proxy`, `https_proxy`, `HTTP_PROXY` y `HTTPS_PROXY`, por lo que el proxy aplica también a las descargas internas del instalador de helm y a los package managers del sistema.

---

## Probar con Docker

```bash
# Ubuntu
docker run --rm -it -v "$PWD/install.sh:/install.sh" ubuntu:22.04 bash /install.sh --auto

# Fedora
docker run --rm -it -v "$PWD/install.sh:/install.sh" fedora:39 bash /install.sh --auto

# Alpine
docker run --rm -it -v "$PWD/install.sh:/install.sh" alpine:3.19 sh /install.sh --auto

# Arch Linux
docker run --rm -it -v "$PWD/install.sh:/install.sh" archlinux bash /install.sh --auto
```

---

## Contribuir

¿Querés agregar soporte para otra herramienta, distro o arquitectura? Lee [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Licencia

[MIT](LICENSE) © Rafael Madolell
