#!/usr/bin/env bash
# ============================================================
# install.sh — WhatsApp CLI/TUI toolkit setup for RHEL 10
#
# Instala e configura:
#   - wacli  : CLI de WhatsApp orientada a scripts/automação
#   - nchat  : cliente TUI (interface ncurses de 3 painéis)
#   - wa-chat: menu interativo de conversas (wrapper sobre o wacli)
#
# Ambos usam a biblioteca whatsmeow (protocolo oficial de
# "dispositivo vinculado", o mesmo do WhatsApp Web/Desktop).
# São ferramentas de terceiros, não afiliadas ao WhatsApp/Meta.
#
# Uso:
#   sudo ./install.sh [usuario_admin]
#
#   usuario_admin: usuário do sistema que poderá rodar wacli/nchat
#                  via sudo como o usuário de serviço dedicado.
#                  Default: $SUDO_USER (quem chamou o sudo).
# ============================================================
set -euo pipefail

SERVICE_USER="${WA_SERVICE_USER:-wacli}"
ADMIN_USER="${1:-${SUDO_USER:-}}"
WACLI_MODULE="github.com/openclaw/wacli/cmd/wacli@latest"
NCHAT_REPO="https://github.com/d99kris/nchat"
FILE_VERSION="5.45"
BUILD_DIR="$(mktemp -d)"

log() { echo "[install.sh] $*"; }

if [[ $EUID -ne 0 ]]; then
  echo "Rode como root (sudo ./install.sh)." >&2
  exit 1
fi

if [[ -z "$ADMIN_USER" ]]; then
  echo "Não foi possível determinar o usuário admin." >&2
  echo "Uso: sudo ./install.sh <usuario_admin>" >&2
  exit 1
fi

id "$ADMIN_USER" >/dev/null 2>&1 || { echo "Usuário '$ADMIN_USER' não existe." >&2; exit 1; }

log "Usuário de serviço: $SERVICE_USER"
log "Usuário admin (vai ganhar sudo pro serviço): $ADMIN_USER"
log "Diretório de build temporário: $BUILD_DIR"

# ---- 1. Dependências de build ----
log "Instalando Go e ferramentas de build..."
dnf install -y golang >/dev/null
dnf groupinstall -y "Development Tools" >/dev/null
dnf install -y cmake clang gperf readline-devel sqlite-devel ncurses-devel zlib-devel >/dev/null

GO_VERSION="$(go version | awk '{print $3}' | sed 's/go//')"
log "Go instalado: $GO_VERSION"

# ---- 2. libmagic (RHEL 10 não tem pacote -devel disponível) ----
if [[ ! -f /usr/local/include/magic.h ]]; then
  log "Compilando libmagic $FILE_VERSION a partir do código-fonte (sem pacote -devel no RHEL10)..."
  curl -sL -o "$BUILD_DIR/file-${FILE_VERSION}.tar.gz" \
    "http://ftp.astron.com/pub/file/file-${FILE_VERSION}.tar.gz"
  tar xzf "$BUILD_DIR/file-${FILE_VERSION}.tar.gz" -C "$BUILD_DIR"
  (cd "$BUILD_DIR/file-${FILE_VERSION}" && \
    ./configure --prefix=/usr/local >/dev/null && \
    make -j"$(nproc)" >/dev/null && \
    make install >/dev/null)
  ldconfig
else
  log "libmagic já presente em /usr/local, pulando."
fi

# ---- 3. wacli (CLI orientada a script) ----
log "Compilando wacli (isso baixa dependências Go, pode levar alguns minutos)..."
GOTOOLCHAIN=auto CGO_ENABLED=1 CGO_CFLAGS="-Wno-error=missing-braces" \
  go install -tags sqlite_fts5 "$WACLI_MODULE"
install -m 755 -o root -g root "$(go env GOPATH)/bin/wacli" /usr/local/bin/wacli

# ---- 4. nchat (TUI 3 painéis) ----
log "Clonando e compilando nchat (só WhatsApp, sem Telegram — mais rápido)..."
git clone --depth 1 "$NCHAT_REPO" "$BUILD_DIR/nchat" >/dev/null
mkdir -p "$BUILD_DIR/nchat/build"
(cd "$BUILD_DIR/nchat/build" && \
  cmake -DHAS_TELEGRAM=OFF -DHAS_TESTS=OFF .. >/dev/null && \
  make -s -j"$(nproc)" && \
  make install >/dev/null)
ldconfig

# ---- 5. Usuário de serviço dedicado (sem privilégios) ----
if ! id "$SERVICE_USER" >/dev/null 2>&1; then
  log "Criando usuário de serviço '$SERVICE_USER'..."
  useradd -m -s /bin/bash "$SERVICE_USER"
  passwd -l "$SERVICE_USER" >/dev/null
  chmod 700 "/home/$SERVICE_USER"
else
  log "Usuário '$SERVICE_USER' já existe, pulando criação."
fi

# ---- 6. wa-chat (menu interativo) ----
log "Instalando wa-chat..."
install -m 755 -o root -g root "$(dirname "$0")/scripts/wa-chat" /usr/local/bin/wa-chat

# ---- 7. sudoers: só o admin informado, só estes 3 binários, sem senha ----
log "Configurando /etc/sudoers.d/${SERVICE_USER}..."
cat > "/etc/sudoers.d/${SERVICE_USER}" <<EOF
${ADMIN_USER} ALL=(${SERVICE_USER}) NOPASSWD: /usr/local/bin/wacli
${ADMIN_USER} ALL=(${SERVICE_USER}) NOPASSWD: /usr/local/bin/wa-chat
${ADMIN_USER} ALL=(${SERVICE_USER}) NOPASSWD: /usr/local/bin/nchat
EOF
chmod 440 "/etc/sudoers.d/${SERVICE_USER}"
visudo -c -f "/etc/sudoers.d/${SERVICE_USER}"

# ---- limpeza ----
rm -rf "$BUILD_DIR"

cat <<EOF

============================================================
Instalação concluída.

Próximo passo (interativo, requer QR code — rode você mesmo):

  Pareamento do wacli (uso via script/automação):
    sudo -u ${SERVICE_USER} wacli auth

  Pareamento do nchat (interface TUI):
    sudo -u ${SERVICE_USER} nchat -s
    (escolha "WhatsAppMd", escaneie o QR)

Uso do dia a dia:
    sudo -u ${SERVICE_USER} nchat        # TUI completa
    sudo -u ${SERVICE_USER} wa-chat      # menu simples de conversas não lidas

Veja o README.md para detalhes, atalhos de teclado e troubleshooting.
============================================================
EOF
