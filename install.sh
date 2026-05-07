#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# CONSTANTES Y COLORES
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

TOOLS_ALL=(kubectl helm k9s kubectx kubens kubectl-aliases)
TOOLS_SELECTED=()
AUTO_MODE=false
ARCH=""
OS_ID=""
OS_LIKE=""
PKG_MANAGER=""
SUDO_CMD=""

# ─────────────────────────────────────────────
# HELPERS DE LOG
# ─────────────────────────────────────────────
log()     { echo -e "${BLUE}==>${RESET} $*"; }
success() { echo -e "${GREEN}✔${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✖ ERROR:${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

banner() {
  echo -e "${CYAN}${BOLD}"
  cat <<'EOF'
 ██╗  ██╗ █████╗ ███████╗    ███████╗███████╗████████╗██╗   ██╗██████╗
 ██║ ██╔╝██╔══██╗██╔════╝    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
 █████╔╝ ╚█████╔╝███████╗    ███████╗█████╗     ██║   ██║   ██║██████╔╝
 ██╔═██╗ ██╔══██╗╚════██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
 ██║  ██╗╚█████╔╝███████║    ███████║███████╗   ██║   ╚██████╔╝██║
 ╚═╝  ╚═╝ ╚════╝ ╚══════╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
EOF
  echo -e "${RESET}"
  echo -e "  ${BOLD}Instalador de herramientas Kubernetes${RESET} — k9s · helm · kubectl · kubectx · kubens"
  echo ""
}

# ─────────────────────────────────────────────
# PARSING DE ARGUMENTOS
# ─────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auto|-a)
        AUTO_MODE=true
        ;;
      --tools)
        shift
        IFS=',' read -ra TOOLS_SELECTED <<< "${1:-}"
        ;;
      --help|-h)
        echo ""
        echo -e "${BOLD}Uso:${RESET}"
        echo "  curl -fsSL <url> | bash"
        echo "  curl -fsSL <url> | bash -s -- --auto"
        echo "  curl -fsSL <url> | bash -s -- --tools kubectl,helm,k9s"
        echo ""
        echo -e "${BOLD}Flags:${RESET}"
        echo "  --auto, -a          Instala todas las herramientas sin interacción"
        echo "  --tools k1,k2,...   Instala solo las herramientas especificadas"
        echo "  --help, -h          Muestra esta ayuda"
        echo ""
        echo -e "${BOLD}Herramientas disponibles:${RESET}"
        echo "  kubectl, helm, k9s, kubectx, kubens, kubectl-aliases"
        echo ""
        exit 0
        ;;
      *)
        warn "Argumento desconocido: $1 (ignorado)"
        ;;
    esac
    shift
  done
}

# ─────────────────────────────────────────────
# DETECCIÓN DE SO Y ARQUITECTURA
# ─────────────────────────────────────────────
detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    OS_ID="macos"
    OS_LIKE="macos"
  else
    OS_ID="unknown"
    OS_LIKE=""
  fi

  # Detectar package manager
  if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
  elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
  elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
  elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
  elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
  elif command -v apk &>/dev/null; then
    PKG_MANAGER="apk"
  elif command -v brew &>/dev/null; then
    PKG_MANAGER="brew"
  else
    PKG_MANAGER="none"
  fi

  log "Sistema detectado: ${BOLD}${OS_ID}${RESET} | Package manager: ${BOLD}${PKG_MANAGER}${RESET}"
}

detect_arch() {
  local raw_arch
  raw_arch="$(uname -m)"
  case "$raw_arch" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l)  ARCH="arm" ;;
    *)       die "Arquitectura no soportada: $raw_arch" ;;
  esac
  log "Arquitectura: ${BOLD}${ARCH}${RESET}"
}

detect_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO_CMD=""
  elif command -v sudo &>/dev/null; then
    SUDO_CMD="sudo"
  else
    warn "No eres root y 'sudo' no está disponible. Intentando instalar en ~/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
  fi
}

# ─────────────────────────────────────────────
# INSTALACIÓN DE DEPENDENCIAS DEL SCRIPT
# ─────────────────────────────────────────────
pkg_install() {
  local pkg="$1"
  log "Instalando dependencia del sistema: ${pkg}"
  case "$PKG_MANAGER" in
    apt)     $SUDO_CMD apt-get install -y -qq "$pkg" ;;
    dnf)     $SUDO_CMD dnf install -y -q "$pkg" ;;
    yum)     $SUDO_CMD yum install -y -q "$pkg" ;;
    zypper)  $SUDO_CMD zypper install -y --quiet "$pkg" ;;
    pacman)  $SUDO_CMD pacman -S --noconfirm --quiet "$pkg" ;;
    apk)     $SUDO_CMD apk add --quiet "$pkg" ;;
    brew)    brew install "$pkg" ;;
    none)    warn "No se pudo instalar $pkg: no se encontró package manager" ;;
  esac
}

check_and_install_deps() {
  log "Verificando dependencias del instalador..."

  for dep in curl tar gzip; do
    if ! command -v "$dep" &>/dev/null; then
      warn "$dep no encontrado, instalando..."
      pkg_install "$dep"
    fi
  done

  # unzip necesario para algunos binarios
  if ! command -v unzip &>/dev/null; then
    pkg_install "unzip" 2>/dev/null || true
  fi

  success "Dependencias listas"
}

ensure_whiptail() {
  if command -v whiptail &>/dev/null; then
    return 0
  fi

  log "Instalando whiptail para el menú interactivo..."
  case "$PKG_MANAGER" in
    apt)     $SUDO_CMD apt-get install -y -qq whiptail 2>/dev/null && return 0 ;;
    dnf|yum) $SUDO_CMD "${PKG_MANAGER}" install -y newt 2>/dev/null && return 0 ;;
    zypper)  $SUDO_CMD zypper install -y newt 2>/dev/null && return 0 ;;
    pacman)  $SUDO_CMD pacman -S --noconfirm libnewt 2>/dev/null && return 0 ;;
    apk)     $SUDO_CMD apk add --quiet newt 2>/dev/null && return 0 ;;
  esac
  return 1
}

# ─────────────────────────────────────────────
# MENÚ INTERACTIVO
# ─────────────────────────────────────────────

# Menú fallback puro en bash con checkboxes ASCII
show_menu_bash() {
  local -a items=("$@")
  local -a selected=()
  local -a state=()
  local count=${#items[@]}

  # inicializar todos como seleccionados
  for ((i=0; i<count; i++)); do
    state[$i]=1
  done

  local cursor=0

  # Función para dibujar el menú
  draw_menu() {
    clear
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}  Seleccionar herramientas a instalar${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════════════${RESET}"
    echo -e "  ${YELLOW}↑/↓${RESET} Mover  ${YELLOW}SPACE${RESET} Toggle  ${YELLOW}a${RESET} Todo/Nada  ${YELLOW}ENTER${RESET} Instalar"
    echo -e "${CYAN}───────────────────────────────────────────────${RESET}"
    for ((i=0; i<count; i++)); do
      local mark="[ ]"
      [[ ${state[$i]} -eq 1 ]] && mark="[${GREEN}✔${RESET}]"
      if [[ $i -eq $cursor ]]; then
        echo -e "  ${BOLD}${BLUE}▶ ${mark} ${items[$i]}${RESET}"
      else
        echo -e "    ${mark} ${items[$i]}"
      fi
    done
    echo -e "${CYAN}───────────────────────────────────────────────${RESET}"
    local sel_count=0
    for s in "${state[@]}"; do [[ $s -eq 1 ]] && ((sel_count++)) || true; done
    echo -e "  ${sel_count}/${count} seleccionadas"
    echo ""
  }

  # Leer teclas
  while true; do
    draw_menu
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 -t 0.1 rest || true
      key="${key}${rest}"
    fi
    case "$key" in
      $'\x1b[A'|k) ((cursor > 0)) && ((cursor--)) || true ;;
      $'\x1b[B'|j) ((cursor < count-1)) && ((cursor++)) || true ;;
      ' ')
        if [[ ${state[$cursor]} -eq 1 ]]; then
          state[$cursor]=0
        else
          state[$cursor]=1
        fi
        ;;
      a|A)
        local any_off=0
        for s in "${state[@]}"; do [[ $s -eq 0 ]] && any_off=1 && break; done
        if [[ $any_off -eq 1 ]]; then
          for ((i=0; i<count; i++)); do state[$i]=1; done
        else
          for ((i=0; i<count; i++)); do state[$i]=0; done
        fi
        ;;
      ''|$'\n')
        break
        ;;
    esac
  done

  clear
  TOOLS_SELECTED=()
  for ((i=0; i<count; i++)); do
    [[ ${state[$i]} -eq 1 ]] && TOOLS_SELECTED+=("${items[$i]}")
  done
}

show_menu_whiptail() {
  local options=()
  for tool in "${TOOLS_ALL[@]}"; do
    options+=("$tool" "" "ON")
  done

  local result
  result=$(whiptail --title "k8s-setup" \
    --checklist "Seleccionar herramientas a instalar:\n(SPACE para toggle, ENTER para confirmar)" \
    20 60 "${#TOOLS_ALL[@]}" \
    "${options[@]}" \
    3>&1 1>&2 2>&3) || die "Instalación cancelada."

  TOOLS_SELECTED=()
  for tool in $result; do
    TOOLS_SELECTED+=("${tool//\"/}")
  done
}

show_menu() {
  if [[ "$AUTO_MODE" == true ]]; then
    TOOLS_SELECTED=("${TOOLS_ALL[@]}")
    log "Modo automático: instalando todas las herramientas"
    return
  fi

  if [[ ${#TOOLS_SELECTED[@]} -gt 0 ]]; then
    log "Herramientas especificadas vía --tools: ${TOOLS_SELECTED[*]}"
    return
  fi

  if ensure_whiptail 2>/dev/null; then
    show_menu_whiptail
  else
    show_menu_bash "${TOOLS_ALL[@]}"
  fi
}

# ─────────────────────────────────────────────
# FUNCIONES DE INSTALACIÓN
# ─────────────────────────────────────────────

github_latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | grep '"tag_name"' \
    | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

install_binary() {
  local src="$1"
  local name="$2"
  $SUDO_CMD install -o root -g root -m 0755 "${src}" "${INSTALL_DIR}/${name}" 2>/dev/null \
    || install -m 0755 "${src}" "${INSTALL_DIR}/${name}"
}

# ── kubectl ──────────────────────────────────
install_kubectl() {
  log "Instalando kubectl..."
  local version
  version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt")
  curl -fsSL "https://dl.k8s.io/release/${version}/bin/linux/${ARCH}/kubectl" \
    -o "${TMPDIR_WORK}/kubectl"
  install_binary "${TMPDIR_WORK}/kubectl" kubectl
  success "kubectl ${version} instalado"
}

# ── helm ─────────────────────────────────────
install_helm() {
  log "Instalando helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | HELM_INSTALL_DIR="${INSTALL_DIR}" USE_SUDO="${SUDO_CMD:+true}" bash
  success "helm $(helm version --short 2>/dev/null || echo '') instalado"
}

# ── k9s ──────────────────────────────────────
install_k9s() {
  log "Instalando k9s..."
  local version
  version=$(github_latest_tag "derailed/k9s")
  local arch_k9s="$ARCH"
  [[ "$ARCH" == "amd64" ]] && arch_k9s="amd64"
  [[ "$ARCH" == "arm64" ]] && arch_k9s="arm64"

  curl -fsSL \
    "https://github.com/derailed/k9s/releases/download/${version}/k9s_Linux_${arch_k9s}.tar.gz" \
    | tar xz -C "${TMPDIR_WORK}" k9s
  install_binary "${TMPDIR_WORK}/k9s" k9s
  success "k9s ${version} instalado"
}

# ── kubectx + kubens ─────────────────────────
install_kubectx() {
  log "Instalando kubectx..."
  local version
  version=$(github_latest_tag "ahmetb/kubectx")
  local ver_no_v="${version#v}"

  curl -fsSL \
    "https://github.com/ahmetb/kubectx/releases/download/${version}/kubectx_${version}_linux_${ARCH}.tar.gz" \
    | tar xz -C "${TMPDIR_WORK}" kubectx 2>/dev/null \
    || curl -fsSL \
    "https://github.com/ahmetb/kubectx/releases/download/${version}/kubectx_v${ver_no_v}_linux_${ARCH}.tar.gz" \
    | tar xz -C "${TMPDIR_WORK}" kubectx

  install_binary "${TMPDIR_WORK}/kubectx" kubectx
  success "kubectx ${version} instalado"
}

install_kubens() {
  log "Instalando kubens..."
  local version
  version=$(github_latest_tag "ahmetb/kubectx")
  local ver_no_v="${version#v}"

  curl -fsSL \
    "https://github.com/ahmetb/kubectx/releases/download/${version}/kubens_${version}_linux_${ARCH}.tar.gz" \
    | tar xz -C "${TMPDIR_WORK}" kubens 2>/dev/null \
    || curl -fsSL \
    "https://github.com/ahmetb/kubectx/releases/download/${version}/kubens_v${ver_no_v}_linux_${ARCH}.tar.gz" \
    | tar xz -C "${TMPDIR_WORK}" kubens

  install_binary "${TMPDIR_WORK}/kubens" kubens
  success "kubens ${version} instalado"
}

# ── kubectl-aliases ───────────────────────────
detect_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *)    echo "$HOME/.bashrc" ;;
  esac
}

install_kubectl_aliases() {
  log "Instalando kubectl-aliases..."
  curl -fsSL \
    "https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases" \
    -o "$HOME/.kubectl_aliases"

  local rc_file
  rc_file="$(detect_shell_rc)"
  local source_line='[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases'

  if ! grep -qF "$source_line" "$rc_file" 2>/dev/null; then
    echo "" >> "$rc_file"
    echo "# kubectl aliases" >> "$rc_file"
    echo "$source_line" >> "$rc_file"
    success "kubectl-aliases instalado → añadido a ${rc_file}"
  else
    success "kubectl-aliases instalado (ya estaba en ${rc_file})"
  fi
  warn "Ejecuta: source ${rc_file}  para activar los aliases en la sesión actual"
}

# ─────────────────────────────────────────────
# DISPATCHER DE INSTALACIÓN
# ─────────────────────────────────────────────
run_installations() {
  if [[ ${#TOOLS_SELECTED[@]} -eq 0 ]]; then
    warn "No se seleccionó ninguna herramienta. Saliendo."
    exit 0
  fi

  echo ""
  log "Instalando: ${BOLD}${TOOLS_SELECTED[*]}${RESET}"
  echo ""

  local failed=()

  for tool in "${TOOLS_SELECTED[@]}"; do
    case "$tool" in
      kubectl)        install_kubectl        || failed+=("kubectl") ;;
      helm)           install_helm           || failed+=("helm") ;;
      k9s)            install_k9s            || failed+=("k9s") ;;
      kubectx)        install_kubectx        || failed+=("kubectx") ;;
      kubens)         install_kubens         || failed+=("kubens") ;;
      kubectl-aliases) install_kubectl_aliases || failed+=("kubectl-aliases") ;;
      *)              warn "Herramienta desconocida: $tool (ignorada)" ;;
    esac
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    error "Fallaron: ${failed[*]}"
    return 1
  fi
}

# ─────────────────────────────────────────────
# VERIFICACIÓN POST-INSTALACIÓN
# ─────────────────────────────────────────────
verify_installations() {
  echo ""
  echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  Resumen de instalación${RESET}"
  echo -e "${CYAN}═══════════════════════════════════════════════${RESET}"

  local binaries=(kubectl helm k9s kubectx kubens)
  for bin in "${binaries[@]}"; do
    if command -v "$bin" &>/dev/null; then
      local ver
      ver=$("$bin" version --short 2>/dev/null \
            || "$bin" version --client --short 2>/dev/null \
            || "$bin" version 2>/dev/null | head -1 \
            || echo "instalado")
      success "${bin}: ${ver}"
    else
      # puede que esté instalado pero no en PATH aún
      if [[ -x "${INSTALL_DIR}/${bin}" ]]; then
        success "${bin}: instalado en ${INSTALL_DIR}/${bin}"
      fi
    fi
  done

  if [[ -f "$HOME/.kubectl_aliases" ]]; then
    success "kubectl-aliases: ~/.kubectl_aliases presente"
  fi

  echo ""
  if [[ "$INSTALL_DIR" != "/usr/local/bin" ]]; then
    warn "Asegúrate de que ${INSTALL_DIR} esté en tu PATH:"
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
  fi

  echo ""
  echo -e "${GREEN}${BOLD}¡Instalación completada!${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
main() {
  parse_args "$@"
  banner
  detect_os
  detect_arch
  detect_sudo
  check_and_install_deps
  show_menu
  run_installations
  verify_installations
}

main "$@"
