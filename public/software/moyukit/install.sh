#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -r "$SCRIPT_DIR/config.sh" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/config.sh"
fi

MOYUKIT_PROJECT_NAME="${MOYUKIT_PROJECT_NAME:-MoyuKit}"
MOYUKIT_DEFAULT_INSTALL_DIR="${MOYUKIT_DEFAULT_INSTALL_DIR:-${HOME}/.local/share/moyukit}"
MOYUKIT_SERVER_URL="${MOYUKIT_SERVER_URL:-https://ithecover.com/software/moyukit}"
MOYUKIT_BEGIN_MARK="# >>> MoyuKit >>>"
MOYUKIT_END_MARK="# <<< MoyuKit <<<"
MOYUKIT_INSTALL_TMP_DIR=""

cleanup_install_tmp() {
    if [[ -n "${MOYUKIT_INSTALL_TMP_DIR:-}" ]]; then
        rm -rf "$MOYUKIT_INSTALL_TMP_DIR"
    fi
}

usage() {
    cat <<'EOF'
用法：
  bash install.sh [--dir DIR] [--local-source DIR]
  bash install.sh --help

选项：
  --dir DIR            指定安装目录，默认 $HOME/.local/share/moyukit
  --local-source DIR   从本地源码目录安装，主要用于隔离测试
  -h, --help           显示帮助
EOF
}

fail() {
    echo "install.sh: $*" >&2
    exit 1
}

shell_quote() {
    local value="$1"
    value="${value//\'/\'\\\'\'}"
    printf "'%s'" "$value"
}

expand_path() {
    local input="$1"
    local parent base

    case "$input" in
        "~") input="$HOME" ;;
        "~/"*) input="$HOME/${input#~/}" ;;
    esac

    [[ -n "$input" ]] || fail "目录不能为空"
    [[ "$input" != *$'\n'* ]] || fail "目录不能包含换行"

    if [[ "$input" != /* ]]; then
        input="$PWD/$input"
    fi

    parent="$(dirname "$input")"
    base="$(basename "$input")"
    [[ "$base" != "." && "$base" != ".." ]] || fail "目录不能以 . 或 .. 结尾"
    mkdir -p "$parent"
    parent="$(cd "$parent" && pwd -P)" || fail "无法访问安装目录的父目录：$parent"
    printf '%s/%s\n' "$parent" "$base"
}

resolve_existing_path() {
    local input="$1"
    local parent base

    case "$input" in
        "~") input="$HOME" ;;
        "~/"*) input="$HOME/${input#~/}" ;;
    esac

    [[ -n "$input" ]] || fail "目录不能为空"
    [[ "$input" != *$'\n'* ]] || fail "目录不能包含换行"

    if [[ "$input" != /* ]]; then
        input="$PWD/$input"
    fi

    parent="$(dirname "$input")"
    base="$(basename "$input")"
    [[ "$base" != "." && "$base" != ".." ]] || fail "目录不能以 . 或 .. 结尾"
    parent="$(cd "$parent" && pwd -P)" || fail "无法访问目录的父目录：$parent"
    printf '%s/%s\n' "$parent" "$base"
}

assert_safe_install_dir() {
    local dir="$1"

    case "$dir" in
        ""|/|"$HOME"|/usr|/usr/*|/etc|/etc/*|/opt|/opt/*|/bin|/bin/*|/sbin|/sbin/*)
            fail "拒绝使用危险安装目录：$dir"
            ;;
    esac
}

check_dependencies() {
    local required=(bash awk column less tar curl sha256sum)
    local missing=()
    local dep

    for dep in "${required[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if ((${#missing[@]} > 0)); then
        fail "缺少必需命令：${missing[*]}"
    fi

    if ! command -v Rscript >/dev/null 2>&1; then
        echo "install.sh: 提示：未找到 Rscript，rr 只有在当前环境存在 Rscript 时才能运行。" >&2
    fi
}

copy_local_source() {
    local source_dir="$1"
    local dest_dir="$2"

    [[ -d "$source_dir" ]] || fail "本地源码目录不存在：$source_dir"
    [[ -r "$source_dir/init.sh" && -r "$source_dir/VERSION" ]] || fail "本地源码目录结构不完整：$source_dir"

    mkdir -p "$dest_dir"
    tar \
        --exclude='./.git' \
        --exclude='./dist' \
        --exclude='./tmp' \
        --exclude='./tests/tmp' \
        --exclude='*.log' \
        --exclude='*.tmp' \
        --exclude='*~' \
        -C "$source_dir" -cf - . | tar -C "$dest_dir" -xf -
}

download_release() {
    local dest_dir="$1"
    local archive="$2"
    local sha_file="$3"
    local expected actual candidate

    [[ -n "$MOYUKIT_SERVER_URL" ]] || fail "未配置服务器地址，请检查 config.sh 或设置 MOYUKIT_SERVER_URL"

    if ! curl -fsSL "$MOYUKIT_SERVER_URL/latest.tar.gz" -o "$archive"; then
        fail "下载失败：$MOYUKIT_SERVER_URL/latest.tar.gz"
    fi

    if curl -fsSL "$MOYUKIT_SERVER_URL/latest.tar.gz.sha256" -o "$sha_file"; then
        if ! (cd "$(dirname "$archive")" && sha256sum -c "$(basename "$sha_file")" >/dev/null 2>&1); then
            expected="$(awk 'NR == 1 {print $1}' "$sha_file")"
            actual="$(sha256sum "$archive" | awk '{print $1}')"
            [[ -n "$expected" && "$expected" == "$actual" ]] || fail "SHA-256 校验失败"
        fi
    else
        echo "install.sh: 提示：未找到 SHA-256 文件，跳过校验。" >&2
    fi

    mkdir -p "$dest_dir/extract"
    tar -xzf "$archive" -C "$dest_dir/extract" || fail "解压失败"
    candidate="$(find "$dest_dir/extract" -mindepth 1 -maxdepth 2 -type f -name init.sh -print -quit)"
    [[ -n "$candidate" ]] || fail "发布包中未找到 init.sh"
    candidate="$(cd "$(dirname "$candidate")" && pwd -P)"
    tar -C "$candidate" -cf - . | tar -C "$dest_dir/source" -xf -
}

install_files() {
    local source_dir="$1"
    local install_dir="$2"
    local tmp_dir="$3"
    local stage="$tmp_dir/stage"
    local backup=""
    local new_dir=""
    local parent

    mkdir -p "$stage"
    tar -C "$source_dir" -cf - . | tar -C "$stage" -xf -
    mkdir -p "$stage/bin"

    [[ -r "$stage/init.sh" && -r "$stage/VERSION" && -d "$stage/functions" ]] || fail "待安装内容结构不完整"

    parent="$(dirname "$install_dir")"
    mkdir -p "$parent"
    new_dir="$(mktemp -d "$parent/.moyukit-new.XXXXXX")" || fail "无法在目标目录旁创建临时目录"
    rmdir "$new_dir"

    if ! mv "$stage" "$new_dir"; then
        rm -rf "$new_dir"
        fail "无法准备新的安装目录：$new_dir"
    fi

    if [[ -e "$install_dir" ]]; then
        if [[ ! -d "$install_dir" ]]; then
            rm -rf "$new_dir"
            fail "目标路径已存在且不是目录：$install_dir"
        fi
        backup="$(mktemp -d "$parent/.moyukit-prev.XXXXXX")" || {
            rm -rf "$new_dir"
            fail "无法在目标目录旁创建备份目录"
        }
        rmdir "$backup"
        if ! mv "$install_dir" "$backup"; then
            rm -rf "$new_dir" "$backup"
            fail "无法暂存已有安装目录：$install_dir"
        fi
    fi

    if ! mv "$new_dir" "$install_dir"; then
        if [[ -n "$backup" && -d "$backup" ]]; then
            mv "$backup" "$install_dir"
        fi
        rm -rf "$new_dir"
        fail "写入安装目录失败：$install_dir"
    fi

    if [[ -n "$backup" ]]; then
        rm -rf "$backup"
    fi
}

write_bashrc_block() {
    local install_dir="$1"
    local bashrc="${HOME}/.bashrc"
    local tmp_file="$2/bashrc.new"
    local backup_file
    local init_path
    local init_path_quoted

    init_path="$install_dir/init.sh"
    init_path_quoted="$(shell_quote "$init_path")"

    if [[ -f "$bashrc" ]]; then
        awk -v begin="$MOYUKIT_BEGIN_MARK" -v end="$MOYUKIT_END_MARK" '
            $0 == begin {skip = 1; next}
            $0 == end {skip = 0; next}
            skip != 1 {print}
        ' "$bashrc" > "$tmp_file"
    else
        : > "$tmp_file"
    fi

    if [[ -s "$tmp_file" ]] && [[ -n "$(tail -n 1 "$tmp_file")" ]]; then
        printf '\n' >> "$tmp_file"
    fi

    {
        printf '%s\n' "$MOYUKIT_BEGIN_MARK"
        printf '[[ -r %s ]] && source %s\n' "$init_path_quoted" "$init_path_quoted"
        printf '%s\n' "$MOYUKIT_END_MARK"
    } >> "$tmp_file"

    if [[ -f "$bashrc" ]] && cmp -s "$bashrc" "$tmp_file"; then
        rm -f "$tmp_file"
        return 0
    fi

    if [[ -f "$bashrc" ]]; then
        backup_file="${bashrc}.moyukit.bak.$(date +%Y%m%d%H%M%S)"
        cp "$bashrc" "$backup_file"
        echo "install.sh: 已备份 .bashrc 到：$backup_file"
    fi

    mv "$tmp_file" "$bashrc"
}

main() {
    local install_dir="$MOYUKIT_DEFAULT_INSTALL_DIR"
    local local_source=""
    local tmp_dir source_dir archive sha_file

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dir)
                [[ $# -ge 2 ]] || fail "--dir 需要参数"
                install_dir="$2"
                shift 2
                ;;
            --local-source)
                [[ $# -ge 2 ]] || fail "--local-source 需要参数"
                local_source="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                fail "未知参数：$1"
                ;;
        esac
    done

    check_dependencies

    install_dir="$(expand_path "$install_dir")"
    assert_safe_install_dir "$install_dir"

    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/moyukit-install.XXXXXX")"
    MOYUKIT_INSTALL_TMP_DIR="$tmp_dir"
    trap cleanup_install_tmp EXIT

    source_dir="$tmp_dir/source"
    mkdir -p "$source_dir"

    if [[ -n "$local_source" ]]; then
        local_source="$(resolve_existing_path "$local_source")"
        copy_local_source "$local_source" "$source_dir"
    else
        archive="$tmp_dir/latest.tar.gz"
        sha_file="$tmp_dir/latest.tar.gz.sha256"
        download_release "$tmp_dir" "$archive" "$sha_file"
    fi

    install_files "$source_dir" "$install_dir" "$tmp_dir"
    write_bashrc_block "$install_dir" "$tmp_dir"

    echo "MoyuKit 已安装到：$install_dir"
    echo "请在当前会话执行一次：source ~/.bashrc"
}

main "$@"
