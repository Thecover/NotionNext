#!/usr/bin/env bash
set -Eeuo pipefail

INSTALLER_VERSION="1.0.0"
SITE_URL="${ITHECOVER_SITE_URL:-https://ithecover.com}"
THECOVER_URL="${THECOVER_URL:-${SITE_URL}/software/thecover}"
THECOVER_SHA256="${THECOVER_SHA256:-26bd542a496e145692369a1c0ef207ff38dc88cb7da5d0ae3c3d67e5c50cf74b}"
MOYUKIT_INSTALLER_URL="${MOYUKIT_INSTALLER_URL:-${SITE_URL}/software/moyukit/install.sh}"
TEMP_DIR=""

COLOR_RESET=""
COLOR_BOLD=""
COLOR_DIM=""
COLOR_BLUE=""
COLOR_CYAN=""
COLOR_GREEN=""
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
        COLOR_BLUE=$'\033[34m'
        COLOR_CYAN=$'\033[36m'
        COLOR_GREEN=$'\033[32m'
        COLOR_YELLOW=$'\033[33m'
        COLOR_RED=$'\033[31m'
    fi
}

info() {
    printf '%s[信息]%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$*"
}

success() {
    printf '%s[完成]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$*"
}

warn() {
    printf '%s[提示]%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*" >&2
}

fail() {
    printf '%s[错误]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
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
    printf '%s%s╭──────────────────────────────────────────╮%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s│       iTHECOVER Software Center          │%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s│          终端软件安装中心                │%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s╰──────────────────────────────────────────╯%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s版本 %s · 安装源 %s%s\n\n' "$COLOR_DIM" "$INSTALLER_VERSION" "$SITE_URL" "$COLOR_RESET"
}

print_software_list() {
    printf '  %s%s1)%s THE COVER%s\n' "$COLOR_BOLD" "$COLOR_GREEN" "$COLOR_RESET" \
        '     Linux x86_64 命令行工具'
    printf '  %s%s2)%s MoyuKit%s\n' "$COLOR_BOLD" "$COLOR_GREEN" "$COLOR_RESET" \
        '       Shell / R 工作流工具箱'
    printf '  %s%s3)%s 安装全部%s\n' "$COLOR_BOLD" "$COLOR_GREEN" "$COLOR_RESET" \
        '      依次安装以上软件'
    printf '  %s0)%s 退出\n\n' "$COLOR_DIM" "$COLOR_RESET"
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
        info "已备份 .bashrc：$backup"
    fi

    mv -- "$new_bashrc" "$bashrc"
    warn "PATH 已写入 ~/.bashrc；安装完成后执行 source ~/.bashrc。"
}

install_thecover() {
    local binary
    local install_dir="${HOME}/.local/bin"
    local install_path="${install_dir}/thecover"

    [[ -n "${HOME:-}" ]] || fail "未检测到 HOME 目录。"
    ensure_supported_thecover_platform
    ensure_temp_dir
    binary="$TEMP_DIR/thecover"

    info "正在下载 THE COVER…"
    download_file "$THECOVER_URL" "$binary"
    verify_sha256 "$THECOVER_SHA256" "$binary"

    mkdir -p -- "$install_dir"
    if command -v install >/dev/null 2>&1; then
        install -m 0755 "$binary" "$install_path"
    else
        cp -- "$binary" "$install_path"
        chmod 0755 "$install_path"
    fi

    ensure_local_bin_on_path
    success "THE COVER 已安装：$install_path"
}

install_moyukit() {
    local installer

    [[ -n "${HOME:-}" ]] || fail "未检测到 HOME 目录。"
    command -v curl >/dev/null 2>&1 ||
        fail "MoyuKit 安装器需要 curl，请先安装 curl。"

    ensure_temp_dir
    installer="$TEMP_DIR/moyukit-install.sh"

    info "正在获取 MoyuKit 安装器…"
    download_file "$MOYUKIT_INSTALLER_URL" "$installer"
    bash -n "$installer" || fail "MoyuKit 安装器语法校验失败。"
    MOYUKIT_SERVER_URL="${SITE_URL}/software/moyukit" bash "$installer"
    success "MoyuKit 安装完成。"
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
    read_from_terminal $'\n按 Enter 返回菜单…' >/dev/null
}

interactive_menu() {
    local choice

    while true; do
        print_header
        print_software_list
        choice="$(read_from_terminal "${COLOR_BOLD}请选择 [0-3]：${COLOR_RESET}")"

        case "$choice" in
            1|2|3)
                printf '\n'
                install_named "$choice"
                pause_menu
                ;;
            0|q|Q|quit|exit)
                printf '\n再见！\n'
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
