# Contribuir a k8s-setup

¡Gracias por tu interés! Cualquier mejora es bienvenida.

## Cómo contribuir

1. **Fork** este repositorio
2. Crea una rama: `git checkout -b feat/nombre-del-cambio`
3. Haz tus cambios en `install.sh`
4. Verifica que pasa ShellCheck: `shellcheck install.sh`
5. Abre un **Pull Request** describiendo qué cambia y por qué

## Guías para `install.sh`

- Cada herramienta nueva necesita:
  - Una función `install_<nombre>()` siguiendo el patrón existente
  - Su entrada en el array `TOOLS_ALL`
  - Un ícono en `tool_icon()` y descripción en `tool_desc()`
  - Un `case` en `run_installations()`
- Usá `github_latest_tag "<owner>/<repo>"` para resolver la versión latest — nunca hardcodees versiones.
- Las dependencias del sistema se instalan con `pkg_install`, que ya soporta todos los package managers.
- Testear en al menos una distro Debian-based y una RPM-based antes de hacer PR.

## Reportar bugs

Abrí un [Issue](https://github.com/insanerask77/k8s-setup/issues) indicando:
- Distro y versión (`cat /etc/os-release`)
- Arquitectura (`uname -m`)
- Output completo del error
