#!/usr/bin/env bash
set -Eeuo pipefail

INSTALLER_VERSION="1.2.1"
SITE_URL="${ITHECOVER_SITE_URL:-https://ithecover.com}"
THECOVER_URL="${THECOVER_URL:-${SITE_URL}/software/thecover}"
THECOVER_SHA256="${THECOVER_SHA256:-26bd542a496e145692369a1c0ef207ff38dc88cb7da5d0ae3c3d67e5c50cf74b}"
MOYUKIT_INSTALLER_URL="${MOYUKIT_INSTALLER_URL:-${SITE_URL}/software/moyukit/install.sh}"
TEMP_DIR=""
LANGUAGE=""

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

init_language() {
    LANGUAGE="zh"
    if [[ -n "${ITHECOVER_LANG:-}" ]]; then
        set_language "$ITHECOVER_LANG" || LANGUAGE="zh"
    fi
}

set_language() {
    case "${1,,}" in
        zh|zh-cn|zh_cn|chinese|中文) LANGUAGE="zh" ;;
        en|en-us|en_us|english) LANGUAGE="en" ;;
        *) return 1 ;;
    esac
}

toggle_language() {
    if [[ "$LANGUAGE" == "zh" ]]; then
        LANGUAGE="en"
    else
        LANGUAGE="zh"
    fi
}

text() {
    local key="$1"

    case "${LANGUAGE}:${key}" in
        zh:source_line) printf '安装源 %s · 安全安装通道' "$SITE_URL" ;;
        en:source_line) printf 'SOURCE %s · SECURE INSTALL CHANNEL' "$SITE_URL" ;;
        zh:platform_check) printf '检测运行平台' ;;
        en:platform_check) printf 'PLATFORM CHECK' ;;
        zh:platform) printf '运行平台' ;;
        en:platform) printf 'PLATFORM' ;;
        zh:downloading_package) printf '正在下载软件包' ;;
        en:downloading_package) printf 'DOWNLOADING PACKAGE' ;;
        zh:download) printf '下载' ;;
        en:download) printf 'DOWNLOAD' ;;
        zh:complete) printf '完成' ;;
        en:complete) printf 'COMPLETE' ;;
        zh:verifying_checksum) printf '正在校验文件' ;;
        en:verifying_checksum) printf 'VERIFYING CHECKSUM' ;;
        zh:verified) printf '校验通过' ;;
        en:verified) printf 'VERIFIED' ;;
        zh:installing_binary) printf '正在安装程序' ;;
        en:installing_binary) printf 'INSTALLING BINARY' ;;
        zh:bashrc_backup) printf 'BASHRC 备份' ;;
        en:bashrc_backup) printf 'BASHRC BACKUP' ;;
        zh:shell_config) printf 'SHELL 配置' ;;
        en:shell_config) printf 'SHELL CONFIG' ;;
        zh:reload_shell) printf '重新加载 SHELL' ;;
        en:reload_shell) printf 'RELOAD SHELL' ;;
        zh:updated) printf '已更新' ;;
        en:updated) printf 'UPDATED' ;;
        zh:install) printf '安装位置' ;;
        en:install) printf 'INSTALL' ;;
        zh:install_complete) printf '安装完成' ;;
        en:install_complete) printf 'INSTALL COMPLETE' ;;
        zh:status_ready) printf '状态：就绪' ;;
        en:status_ready) printf 'STATUS: READY' ;;
        zh:downloading_installer) printf '正在下载安装器' ;;
        en:downloading_installer) printf 'DOWNLOADING INSTALLER' ;;
        zh:validating_installer) printf '正在验证安装器' ;;
        en:validating_installer) printf 'VALIDATING INSTALLER' ;;
        zh:installer) printf '安装器' ;;
        en:installer) printf 'INSTALLER' ;;
        zh:valid) printf '有效' ;;
        en:valid) printf 'VALID' ;;
        zh:installing_package) printf '正在安装软件包' ;;
        en:installing_package) printf 'INSTALLING PACKAGE' ;;
        zh:package) printf '软件包' ;;
        en:package) printf 'PACKAGE' ;;
        zh:installed) printf '已安装' ;;
        en:installed) printf 'INSTALLED' ;;
        zh:runtime) printf '运行环境' ;;
        en:runtime) printf 'RUNTIME' ;;
        zh:rscript_missing) printf '未找到 Rscript，rr 暂不可用' ;;
        en:rscript_missing) printf 'Rscript not found; rr is unavailable' ;;
        zh:press_enter) printf '按 ENTER 返回 > ' ;;
        en:press_enter) printf 'PRESS ENTER TO RETURN > ' ;;
        zh:select_prompt) printf '请选择软件 > ' ;;
        en:select_prompt) printf 'SELECT MODULE > ' ;;
        zh:halted) printf '系统已退出，再见。' ;;
        en:halted) printf 'SYSTEM HALTED. BYE.' ;;
        zh:invalid_choice) printf '请输入 0、1、2、3 或 L。' ;;
        en:invalid_choice) printf 'Enter 0, 1, 2, 3, or L.' ;;
        zh:missing_download_tool) printf '缺少下载工具，请先安装 curl 或 wget。' ;;
        en:missing_download_tool) printf 'No download tool found. Install curl or wget first.' ;;
        zh:missing_sha256) printf '缺少 sha256sum，无法校验下载文件。' ;;
        en:missing_sha256) printf 'sha256sum is required to verify downloads.' ;;
        zh:checksum_failed) printf 'SHA-256 校验失败，已停止安装。' ;;
        en:checksum_failed) printf 'SHA-256 verification failed. Installation stopped.' ;;
        zh:linux_only) printf 'THE COVER 当前只提供 Linux 版本，检测到：%s。' ;;
        en:linux_only) printf 'THE COVER supports Linux only. Detected: %s.' ;;
        zh:x64_only) printf 'THE COVER 当前只支持 x86_64，检测到：%s。' ;;
        en:x64_only) printf 'THE COVER supports x86_64 only. Detected: %s.' ;;
        zh:missing_home) printf '未检测到 HOME 目录。' ;;
        en:missing_home) printf 'HOME is not set.' ;;
        zh:moyukit_needs_curl) printf 'MoyuKit 安装器需要 curl，请先安装 curl。' ;;
        en:moyukit_needs_curl) printf 'MoyuKit requires curl. Install curl first.' ;;
        zh:installer_invalid) printf 'MoyuKit 安装器语法校验失败。' ;;
        en:installer_invalid) printf 'MoyuKit installer validation failed.' ;;
        zh:moyukit_failed) printf 'MoyuKit 安装失败。' ;;
        en:moyukit_failed) printf 'MoyuKit installation failed.' ;;
        zh:unknown_software) printf '未知软件：%s。可选值：thecover、moyukit、all。' ;;
        en:unknown_software) printf 'Unknown software: %s. Choose thecover, moyukit, or all.' ;;
        zh:no_terminal) printf '未检测到交互终端，请使用 --install NAME。' ;;
        en:no_terminal) printf 'No interactive terminal detected. Use --install NAME.' ;;
        zh:terminal_read_failed) printf '无法读取终端输入，请使用 --install NAME。' ;;
        en:terminal_read_failed) printf 'Cannot read terminal input. Use --install NAME.' ;;
        zh:lang_needs_value) printf '%s 需要语言参数 zh 或 en。' ;;
        en:lang_needs_value) printf '%s requires zh or en.' ;;
        zh:invalid_language) printf '不支持的语言：%s。请使用 zh 或 en。' ;;
        en:invalid_language) printf 'Unsupported language: %s. Use zh or en.' ;;
        zh:install_needs_value) printf '%s 需要软件名称。' ;;
        en:install_needs_value) printf '%s requires a software name.' ;;
        zh:unknown_argument) printf '未知参数：%s。使用 --help 查看帮助。' ;;
        en:unknown_argument) printf 'Unknown argument: %s. Use --help for help.' ;;
        *) printf '%s' "$key" ;;
    esac
}

format_text() {
    local key="$1"
    shift
    local format

    format="$(text "$key")"
    printf "$format" "$@"
}

warn() {
    printf '%s[!]%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*" >&2
}

fail() {
    printf '%s[×]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
    exit 1
}

usage() {
    if [[ "$LANGUAGE" == "zh" ]]; then
        cat <<'EOF'
用法：
  wget -qO- https://ithecover.com/software/install | bash
  wget -qO- https://ithecover.com/software/install | bash -s -- --lang zh
  bash install.sh --install moyukit

选项：
  --list              列出可安装的软件
  --install NAME      直接安装指定软件：thecover、moyukit 或 all
  --lang LANG         指定界面语言：zh 或 en
  --no-color          禁用终端颜色
  -h, --help          显示帮助
  -v, --version       显示安装器版本

环境变量：
  ITHECOVER_SITE_URL  软件源地址，默认 https://ithecover.com
  ITHECOVER_LANG      界面语言；默认 zh，可设置为 en
  NO_COLOR=1          禁用终端颜色
EOF
    else
        cat <<'EOF'
Usage:
  wget -qO- https://ithecover.com/software/install | bash
  wget -qO- https://ithecover.com/software/install | bash -s -- --lang en
  bash install.sh --install moyukit

Options:
  --list              List available software
  --install NAME      Install thecover, moyukit, or all
  --lang LANG         Set the interface language: zh or en
  --no-color          Disable terminal colors
  -h, --help          Show help
  -v, --version       Show installer version

Environment:
  ITHECOVER_SITE_URL  Software source; default: https://ithecover.com
  ITHECOVER_LANG      Interface language; default: zh, optional: en
  NO_COLOR=1          Disable terminal colors
EOF
    fi
}

print_header() {
    printf '\n'
    printf '%s%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃           █ ▀█▀ █ █ █▀▀ █▀▀ █▀█ █ █ █▀▀ █▀█            ┃%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃           █  █  █▀█ █▀▀ █   █ █ █ █ █▀▀ █▀▄            ┃%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃           █  █  █ █ █▄▄ █▄▄ █▄█  ▀  █▄▄ █ █            ┃%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s┃              TERMINAL SOFTWARE CENTER v%s           ┃%s\n' \
        "$COLOR_BOLD" "$COLOR_CYAN" "$INSTALLER_VERSION" "$COLOR_RESET"
    printf '%s%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛%s\n' "$COLOR_BOLD" "$COLOR_CYAN" "$COLOR_RESET"
    printf '%s%s%s\n\n' "$COLOR_DIM" "$(text source_line)" "$COLOR_RESET"
}

print_software_list() {
    printf '%s┏━ SOFTWARE SELECT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓%s\n' "$COLOR_CYAN" "$COLOR_RESET"
    if [[ "$LANGUAGE" == "zh" ]]; then
        printf '%s┃%s  LANGUAGE: 中文                                        %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
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
        printf '%s┃%s  %s[3]%s %s安装全部%s                                          %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_MAGENTA" "$COLOR_RESET" \
            "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[L] SWITCH TO ENGLISH%s                                 %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_YELLOW" "$COLOR_RESET" \
            "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[0] 退出%s                                              %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
            "$COLOR_CYAN" "$COLOR_RESET"
    else
        printf '%s┃%s  LANGUAGE: ENGLISH                                     %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s                                                        %s┃%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[1]%s %sTHE COVER%s      %sLINUX x86_64%s                       %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_GREEN" "$COLOR_RESET" \
            "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
            "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s      High-performance disk usage analyzer              %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s                                                        %s┃%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[2]%s %sMOYUKIT%s        %sBASH / R TOOLKIT%s                   %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_GREEN" "$COLOR_RESET" \
            "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
            "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s      Linux server workflow toolkit                     %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s                                                        %s┃%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[3]%s %sINSTALL ALL%s                                       %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_MAGENTA" "$COLOR_RESET" \
            "$COLOR_BOLD" "$COLOR_RESET" "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[L] 切换到中文%s                                        %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_YELLOW" "$COLOR_RESET" \
            "$COLOR_CYAN" "$COLOR_RESET"
        printf '%s┃%s  %s[0] EXIT%s                                              %s┃%s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_DIM" "$COLOR_RESET" \
            "$COLOR_CYAN" "$COLOR_RESET"
    fi
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
    printf '%s└─ %s%s%s ─────────────────────────────────────────────%s\n' \
        "$COLOR_CYAN" "$COLOR_GREEN" "$(text status_ready)" \
        "$COLOR_CYAN" "$COLOR_RESET"
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
        fail "$(text missing_download_tool)"
    fi
}

verify_sha256() {
    local expected="$1"
    local file="$2"
    local actual

    command -v sha256sum >/dev/null 2>&1 ||
        fail "$(text missing_sha256)"

    actual="$(sha256sum "$file" | awk '{print $1}')"
    [[ "$actual" == "$expected" ]] ||
        fail "$(text checksum_failed)"
}

ensure_supported_thecover_platform() {
    local system
    local machine

    system="$(uname -s)"
    machine="$(uname -m)"

    [[ "$system" == "Linux" ]] ||
        fail "$(format_text linux_only "$system")"

    case "$machine" in
        x86_64|amd64) ;;
        *) fail "$(format_text x64_only "$machine")" ;;
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
        pixel_step_done "$(text bashrc_backup)" "$backup"
    fi

    mv -- "$new_bashrc" "$bashrc"
    pixel_step_done "$(text shell_config)" "~/.bashrc $(text updated)"
    pixel_step_note "$(text reload_shell)" "source ~/.bashrc"
}

install_thecover() {
    local binary
    local install_dir="${HOME}/.local/bin"
    local install_path="${install_dir}/thecover"

    [[ -n "${HOME:-}" ]] || fail "$(text missing_home)"
    pixel_panel_open "THE COVER"
    pixel_progress "▓░░░░░░░" "$(text platform_check)"
    ensure_supported_thecover_platform
    pixel_step_done "$(text platform)" "LINUX x86_64"
    ensure_temp_dir
    binary="$TEMP_DIR/thecover"

    pixel_progress "▓▓▓░░░░░" "$(text downloading_package)"
    download_file "$THECOVER_URL" "$binary"
    pixel_step_done "$(text download)" "$(text complete)"

    pixel_progress "▓▓▓▓▓░░░" "$(text verifying_checksum)"
    verify_sha256 "$THECOVER_SHA256" "$binary"
    pixel_step_done "SHA-256" "$(text verified)"

    pixel_progress "▓▓▓▓▓▓▓░" "$(text installing_binary)"
    mkdir -p -- "$install_dir"
    if command -v install >/dev/null 2>&1; then
        install -m 0755 "$binary" "$install_path"
    else
        cp -- "$binary" "$install_path"
        chmod 0755 "$install_path"
    fi

    ensure_local_bin_on_path
    pixel_step_done "$(text install)" "$install_path"
    pixel_progress "▓▓▓▓▓▓▓▓" "$(text install_complete)"
    pixel_panel_ready
}

install_moyukit() {
    local installer
    local installer_output

    [[ -n "${HOME:-}" ]] || fail "$(text missing_home)"
    command -v curl >/dev/null 2>&1 ||
        fail "$(text moyukit_needs_curl)"

    pixel_panel_open "MOYUKIT"
    ensure_temp_dir
    installer="$TEMP_DIR/moyukit-install.sh"

    pixel_progress "▓▓░░░░░░" "$(text downloading_installer)"
    download_file "$MOYUKIT_INSTALLER_URL" "$installer"
    pixel_step_done "$(text download)" "$(text complete)"

    pixel_progress "▓▓▓▓░░░░" "$(text validating_installer)"
    bash -n "$installer" || fail "$(text installer_invalid)"
    pixel_step_done "$(text installer)" "$(text valid)"

    if ! command -v Rscript >/dev/null 2>&1; then
        pixel_step_note "$(text runtime)" "$(text rscript_missing)"
    fi

    pixel_progress "▓▓▓▓▓▓░░" "$(text installing_package)"
    if ! installer_output="$(
        MOYUKIT_SERVER_URL="${SITE_URL}/software/moyukit" \
            bash "$installer" 2>&1
    )"; then
        pixel_child_output "$installer_output"
        fail "$(text moyukit_failed)"
    fi
    pixel_step_done "$(text package)" "$(text installed)"
    pixel_step_done "$(text shell_config)" "~/.bashrc $(text updated)"
    pixel_step_note "$(text reload_shell)" "source ~/.bashrc"
    pixel_progress "▓▓▓▓▓▓▓▓" "$(text install_complete)"
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
            fail "$(format_text unknown_software "$1")"
            ;;
    esac
}

read_from_terminal() {
    local prompt="$1"
    local answer

    printf '%s' "$prompt" >/dev/tty 2>/dev/null ||
        fail "$(text no_terminal)"
    if ! IFS= read -r answer </dev/tty; then
        fail "$(text terminal_read_failed)"
    fi
    printf '%s' "$answer"
}

pause_menu() {
    read_from_terminal "${COLOR_DIM}$(text press_enter)${COLOR_RESET}" >/dev/null
}

interactive_menu() {
    local choice

    while true; do
        print_header
        print_software_list
        choice="$(read_from_terminal "${COLOR_MAGENTA}${COLOR_BOLD}$(text select_prompt)${COLOR_RESET}")"

        case "$choice" in
            1|2|3)
                printf '\n'
                install_named "$choice"
                pause_menu
                ;;
            l|L)
                toggle_language
                ;;
            0|q|Q|quit|exit)
                printf '\n%s%s%s\n' "$COLOR_DIM" "$(text halted)" "$COLOR_RESET"
                return 0
                ;;
            *)
                warn "$(text invalid_choice)"
                ;;
        esac
    done
}

main() {
    local action="menu"
    local install_target=""
    local -a arguments=("$@")
    local index

    init_language

    for ((index = 0; index < ${#arguments[@]}; index++)); do
        case "${arguments[index]}" in
            --lang)
                if ((index + 1 >= ${#arguments[@]})); then
                    fail "$(format_text lang_needs_value --lang)"
                fi
                if ! set_language "${arguments[index + 1]}"; then
                    fail "$(format_text invalid_language "${arguments[index + 1]}")"
                fi
                ((index += 1))
                ;;
            --no-color)
                NO_COLOR=1
                ;;
        esac
    done

    init_colors

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list)
                action="list"
                shift
                ;;
            --install)
                [[ $# -ge 2 ]] ||
                    fail "$(format_text install_needs_value --install)"
                action="install"
                install_target="$2"
                shift 2
                ;;
            --lang)
                [[ $# -ge 2 ]] ||
                    fail "$(format_text lang_needs_value --lang)"
                shift 2
                ;;
            --no-color)
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
                fail "$(format_text unknown_argument "$1")"
                ;;
        esac
    done

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
