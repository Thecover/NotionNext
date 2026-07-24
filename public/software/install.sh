#!/usr/bin/env bash
set -Eeuo pipefail

INSTALLER_VERSION="1.1.0"
SITE_URL="${ITHECOVER_SITE_URL:-https://ithecover.com}"
THECOVER_URL="${THECOVER_URL:-${SITE_URL}/software/thecover}"
THECOVER_SHA256="${THECOVER_SHA256:-26bd542a496e145692369a1c0ef207ff38dc88cb7da5d0ae3c3d67e5c50cf74b}"
MOYUKIT_INSTALLER_URL="${MOYUKIT_INSTALLER_URL:-${SITE_URL}/software/moyukit/install.sh}"
TEMP_DIR=""

COLOR_RESET=""
COLOR_BOLD=""
COLOR_DIM=""
COLOR_CYAN=""
COLOR_GREEN=""
COLOR_MAGENTA=""
COLOR_YELLOW=""
COLOR_RED=""

cleanup() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}

trap cleanup EXIT

init_colors() {
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        COLOR_RESET=$'\033[0m'
        COLOR_BOLD=$'\033[1m'
        COLOR_DIM=$'\033[2m'
        COLOR_CYAN=$'\033[96m'
        COLOR_GREEN=$'\033[92m'
        COLOR_MAGENTA=$'\033[95m'
        COLOR_YELLOW=$'\033[93m'
        COLOR_RED=$'\033[91m'
    fi
}

warn() {
    printf '%s[!]%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*" >&2
}

fail() {
    printf '%s[×]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
用法：
  wget -qO- https://ithecover.com/software/install | bash
  bash install.sh --install thecover
  bash install.sh --install moyukit
  bash install.sh --install all

选项：
  --list              列出可安装的软件
  --install NAME      直接安装指定软件：thecover、moyukit 或 all
  --no-color          禁用终端颜色
  -h, --help          显示帮助
  -v, --version       显示安装器版本

环境变量：
  ITHECOVER_SITE_URL  软件源地址，默认 https://ithecover.com
  NO_COLOR=1          禁用终端颜色
EOF
}

print_header() {
    printf '\n'
    printf '%s%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃           █ ▀█▀ █ █ █▀▀ █▀▀ █▀█ █ █ █▀▀ █▀█            ┃%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃           █  █  █▀█ █▀▀ █   █ █ ▀▄▀ █▀▀ █▀▄            ┃%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃           █  █  █ █ █▄▄ █▄▄ █▄█  █  █▄▄ █ █            ┃%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃              TERMINAL SOFTWARE CENTER v%s           ┃%s\n' \
        "$COLOR_BOLD" "$COLOR_CYAN" "$INSTALLER_VERSION" "$COLOR_RESET"
    printf '%s%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%sSOURCE %s · SECURE INSTALL CHANNEL%s\n\n' "$COLOR_DIM" "$SITE_URL" "$COLOR_RESET"
}

print_software_list() {
    printf '%s┏━ SOFTWARE SELECT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓%s\n' "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s                                                        %s┃%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s  %s[1]%s %sTHE COVER%s      %sLINUX x86_64%s                       %s┃%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_GREEN" "$COLOR_RESET" \
        "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
        "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s      高性能磁盘空间分析工具                            %s┃%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s                                                        %s┃%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s  %s[2]%s %sMOYUKIT%s        %sBASH / R TOOLKIT%s                   %s┃%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_GREEN" "$COLOR_RESET" \
        "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
        "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s      Linux 服务器工作流工具箱                          %s┃%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s                                                        %s┃%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s  %s[3]%s %sINSTALL ALL%s                                       %s┃%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_MAGENTA" "$COLOR_RESET" \
        "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┃%s  %s[0] EXIT%s                                              %s┃%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
        "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛%s\n\n' "$COLOR_CYAN" "$COLOR_RESET"
}

pixel_panel_open() {
    local title="$1"

    printf '\n%s┌─ %s%s%s ─────────────────────────────────────────────%s\n' \
        "$COLOR_CYAN" "$COLOR_BOLD" "$title" "$COLOR_CYAN" "$COLOR_RESET"
}

pixel_progress() {
    local bar="$1"
    local label="$2"

    printf '%s│%s %s[%s]%s %s%s%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_MAGENTA" "$bar" "$COLOR_RESET" \
        "$COLOR_BOLD" "$label" "$COLOR_RESET"
}

pixel_step_done() {
    local label="$1"
    local detail="${2:-}"

    printf '%s│%s %s[✓]%s %-18s %s%s%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_GREEN" "$COLOR_RESET" \
        "$label" "$COLOR_DIM" "$detail" "$COLOR_RESET"
}

pixel_step_note() {
    local label="$1"
    local detail="${2:-}"

    printf '%s│%s %s[!]%s %-18s %s%s%s\n' \
        "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_YELLOW" "$COLOR_RESET" \
        "$label" "$COLOR_DIM" "$detail" "$COLOR_RESET"
}

pixel_panel_ready() {
    printf '%s└─ %sSTATUS: READY%s ───────────────────────────────────────%s\n' \
        "$COLOR_CYAN" "$COLOR_GREEN" "$COLOR_CYAN" "$COLOR_RESET"
}

pixel_child_output() {
    local output="$1"
    local line

    [[ -n "$output" ]] || return 0
    while IFS= read -r line; do
        printf '%s│%s %s%s%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_DIM" "$line" "$COLOR_RESET"
    done <<< "$output"
}

ensure_temp_dir() {
    if [[ -z "$TEMP_DIR" ]]; then
        TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ithecover-software.XXXXXX")"
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error \
            --retry 3 --retry-delay 1 \
            "$url" --output "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --tries=3 --output-document="$output" "$url"
    else
        fail "缺少下载工具，请先安装 curl 或 wget。"
    fi
}

verify_sha256() {
    local expected="$1"
    local file="$2"
    local actual

    command -v sha256sum >/dev/null 2>&1 ||
        fail "缺少 sha256sum，无法校验下载文件。"

    actual="$(sha256sum "$file" | awk '{print $1}')"
    [[ "$actual" == "$expected" ]] ||
        fail "SHA-256 校验失败，已停止安装。"
}

ensure_supported_thecover_platform() {
    local system
    local machine

    system="$(uname -s)"
    machine="$(uname -m)"

    [[ "$system" == "Linux" ]] ||
        fail "THE COVER 当前只提供 Linux 版本，检测到：$system。"

    case "$machine" in
        x86_64|amd64) ;;
        *) fail "THE COVER 当前只支持 x86_64，检测到：$machine。" ;;
    esac
}

ensure_local_bin_on_path() {
    local bashrc="${HOME}/.bashrc"
    local begin_mark="# >>> iTHECOVER software >>>"
    local end_mark="# <<< iTHECOVER software <<<"
    local new_bashrc
    local backup

    if [[ ":${PATH}:" == *":${HOME}/.local/bin:"* ]]; then
        return 0
    fi

    ensure_temp_dir
    new_bashrc="$TEMP_DIR/bashrc.new"

    if [[ -f "$bashrc" ]]; then
        awk -v begin="$begin_mark" -v end="$end_mark" '
            $0 == begin { skip = 1; next }
            $0 == end { skip = 0; next }
            skip != 1 { print }
        ' "$bashrc" > "$new_bashrc"
    else
        : > "$new_bashrc"
    fi

    if [[ -s "$new_bashrc" ]]; then
        printf '\n' >> "$new_bashrc"
    fi

    {
        printf '%s\n' "$begin_mark"
        printf 'export PATH="$HOME/.local/bin:$PATH"\n'
        printf '%s\n' "$end_mark"
    } >> "$new_bashrc"

    if [[ -f "$bashrc" ]]; then
        backup="${bashrc}.ithecover.bak.$(date +%Y%m%d%H%M%S)"
        cp -- "$bashrc" "$backup"
        pixel_step_done "BASHRC BACKUP" "$backup"
    fi

    mv -- "$new_bashrc" "$bashrc"
    pixel_step_note "RELOAD SHELL" "source ~/.bashrc"
}

install_thecover() {
    local binary
    local install_dir="${HOME}/.local/bin"
    local install_path="${install_dir}/thecover"

    [[ -n "${HOME:-}" ]] || fail "未检测到 HOME 目录。"
    pixel_panel_open "THE COVER"
    pixel_progress "▓░░░░░░░" "PLATFORM CHECK"
    ensure_supported_thecover_platform
    pixel_step_done "PLATFORM" "LINUX x86_64"
    ensure_temp_dir
    binary="$TEMP_DIR/thecover"

    pixel_progress "▓▓▓░░░░░" "DOWNLOADING PACKAGE"
    download_file "$THECOVER_URL" "$binary"
    pixel_step_done "DOWNLOAD" "COMPLETE"

    pixel_progress "▓▓▓▓▓░░░" "VERIFYING CHECKSUM"
    verify_sha256 "$THECOVER_SHA256" "$binary"
    pixel_step_done "SHA-256" "VERIFIED"

    pixel_progress "▓▓▓▓▓▓▓░" "INSTALLING BINARY"
    mkdir -p -- "$install_dir"
    if command -v install >/dev/null 2>&1; then
        install -m 0755 "$binary" "$install_path"
    else
        cp -- "$binary" "$install_path"
        chmod 0755 "$install_path"
    fi

    ensure_local_bin_on_path
    pixel_step_done "INSTALL" "$install_path"
    pixel_progress "▓▓▓▓▓▓▓▓" "INSTALL COMPLETE"
    pixel_panel_ready
}

install_moyukit() {
    local installer
    local installer_output

    [[ -n "${HOME:-}" ]] || fail "未检测到 HOME 目录。"
    command -v curl >/dev/null 2>&1 ||
        fail "MoyuKit 安装器需要 curl，请先安装 curl。"

    pixel_panel_open "MOYUKIT"
    ensure_temp_dir
    installer="$TEMP_DIR/moyukit-install.sh"

    pixel_progress "▓▓░░░░░░" "DOWNLOADING INSTALLER"
    download_file "$MOYUKIT_INSTALLER_URL" "$installer"
    pixel_step_done "DOWNLOAD" "COMPLETE"

    pixel_progress "▓▓▓▓░░░░" "VALIDATING INSTALLER"
    bash -n "$installer" || fail "MoyuKit 安装器语法校验失败。"
    pixel_step_done "INSTALLER" "VALID"

    pixel_progress "▓▓▓▓▓▓░░" "INSTALLING PACKAGE"
    if ! installer_output="$(
        MOYUKIT_SERVER_URL="${SITE_URL}/software/moyukit" \
            bash "$installer" 2>&1
    )"; then
        pixel_child_output "$installer_output"
        fail "MoyuKit 安装失败。"
    fi
    pixel_child_output "$installer_output"
    pixel_step_done "PACKAGE" "INSTALLED"
    pixel_progress "▓▓▓▓▓▓▓▓" "INSTALL COMPLETE"
    pixel_panel_ready
}

install_named() {
    local name="${1,,}"

    case "$name" in
        1|thecover|the-cover)
            install_thecover
            ;;
        2|moyukit|moyu-kit)
            install_moyukit
            ;;
        3|all)
            install_thecover
            printf '\n'
            install_moyukit
            ;;
        *)
            fail "未知软件：$1。可选值：thecover、moyukit、all。"
            ;;
    esac
}

read_from_terminal() {
    local prompt="$1"
    local answer

    printf '%s' "$prompt" >/dev/tty 2>/dev/null ||
        fail "未检测到交互终端，请使用 --install NAME。"
    if ! IFS= read -r answer </dev/tty; then
        fail "无法读取终端输入，请使用 --install NAME。"
    fi
    printf '%s' "$answer"
}

pause_menu() {
    read_from_terminal "${COLOR_DIM}PRESS ENTER TO RETURN > ${COLOR_RESET}" >/dev/null
}

interactive_menu() {
    local choice

    while true; do
        print_header
        print_software_list
        choice="$(read_from_terminal "${COLOR_MAGENTA}${COLOR_BOLD}SELECT MODULE > ${COLOR_RESET}")"

        case "$choice" in
            1|2|3)
                printf '\n'
                install_named "$choice"
                pause_menu
                ;;
            0|q|Q|quit|exit)
                printf '\n%sSYSTEM HALTED. BYE.%s\n' "$COLOR_DIM" "$COLOR_RESET"
                return 0
                ;;
            *)
                warn "请输入 0、1、2 或 3。"
                ;;
        esac
    done
}

main() {
    local action="menu"
    local install_target=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list)
                action="list"
                shift
                ;;
            --install)
                [[ $# -ge 2 ]] || fail "--install 需要软件名称。"
                action="install"
                install_target="$2"
                shift 2
                ;;
            --no-color)
                NO_COLOR=1
                shift
                ;;
            -h|--help)
                usage
                return 0
                ;;
            -v|--version)
                printf 'iTHECOVER Software Installer %s\n' "$INSTALLER_VERSION"
                return 0
                ;;
            *)
                fail "未知参数：$1。使用 --help 查看帮助。"
                ;;
        esac
    done

    init_colors

    case "$action" in
        list)
            print_header
            print_software_list
            ;;
        install)
            print_header
            install_named "$install_target"
            ;;
        menu)
            interactive_menu
            ;;
    esac
}

main "$@"
