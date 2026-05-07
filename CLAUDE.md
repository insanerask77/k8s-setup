# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué hace este proyecto

Script de instalación único (`install.sh`) distribuible vía `curl <url> | bash` que instala herramientas Kubernetes en su última versión disponible: `kubectl`, `helm`, `k9s`, `kubectx`, `kubens`, y `kubectl-aliases`.

## Uso

```bash
# Interactivo (menú de selección)
curl -fsSL https://raw.githubusercontent.com/<user>/k8s-setup/main/install.sh | bash

# Instalar todo sin interacción
curl -fsSL https://raw.githubusercontent.com/<user>/k8s-setup/main/install.sh | bash -s -- --auto

# Herramientas específicas
curl -fsSL https://raw.githubusercontent.com/<user>/k8s-setup/main/install.sh | bash -s -- --tools kubectl,helm,k9s

# Ejecución local
bash install.sh --auto
bash install.sh --help
```

## Verificar sintaxis

```bash
bash -n install.sh
```

## Probar en contenedores Docker (distros)

```bash
# Ubuntu/Debian
docker run --rm -it -v "$PWD/install.sh:/install.sh" ubuntu:22.04 bash /install.sh --auto

# Fedora
docker run --rm -it -v "$PWD/install.sh:/install.sh" fedora:39 bash /install.sh --auto

# Arch Linux
docker run --rm -it -v "$PWD/install.sh:/install.sh" archlinux bash /install.sh --auto

# Alpine
docker run --rm -it -v "$PWD/install.sh:/install.sh" alpine:3.19 sh /install.sh --auto

# openSUSE
docker run --rm -it -v "$PWD/install.sh:/install.sh" opensuse/leap bash /install.sh --auto
```

## Arquitectura del script

El script es un único archivo bash con estas secciones en orden:

1. **Constantes/colores** — variables de entorno y códigos ANSI
2. **Helpers de log** — `log()`, `success()`, `warn()`, `error()`, `die()`
3. **`parse_args()`** — flags `--auto`, `--tools`, `--help`
4. **`detect_os()`** — lee `/etc/os-release`, detecta package manager (`apt`/`dnf`/`yum`/`zypper`/`pacman`/`apk`/`brew`)
5. **`detect_arch()`** — mapea `uname -m` a `amd64`/`arm64`
6. **`detect_sudo()`** — decide si usar `sudo` o instalar en `~/.local/bin`
7. **`check_and_install_deps()`** — garantiza que `curl`, `tar`, `gzip` estén presentes
8. **`show_menu()`** — dispatcher: usa `whiptail` si está disponible (lo instala si no), o cae a menú bash puro con checkboxes ASCII navegables con teclado
9. **`install_<tool>()`** — una función por herramienta; descarga desde GitHub Releases o fuentes oficiales usando `github_latest_tag()`
10. **`run_installations()`** — itera sobre `TOOLS_SELECTED` y llama a cada instalador
11. **`verify_installations()`** — imprime resumen final con versiones

## Variables de entorno respetadas

| Variable | Default | Descripción |
|---|---|---|
| `INSTALL_DIR` | `/usr/local/bin` | Directorio de instalación de binarios |

## Convenciones importantes

- Los binarios se instalan en `INSTALL_DIR` (por defecto `/usr/local/bin`) usando `install_binary()` que maneja tanto root como no-root.
- `github_latest_tag()` hace una llamada a la GitHub API para obtener el tag más reciente — no hardcodear versiones.
- `kubectl-aliases` es el único "tool" que no instala un binario: escribe `~/.kubectl_aliases` y añade el source al RC del shell detectado.
- El menú bash puro (`show_menu_bash`) es completamente interactivo: `↑/↓` para mover cursor, `SPACE` para toggle, `a` para todo/nada, `ENTER` para confirmar.
