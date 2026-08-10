#!/usr/bin/env bash
set -Eeuo pipefail

BOOTSTRAP_VERSION="0.2.0"
MOYUKIT_SERVER_URL="${MOYUKIT_SERVER_URL:-https://ithecover.com/software/moyukit}"
MOYUKIT_BOOTSTRAP_TMP=""

cleanup() {
    if [[ -n "${MOYUKIT_BOOTSTRAP_TMP:-}" && -d "$MOYUKIT_BOOTSTRAP_TMP" ]]; then
        rm -rf -- "$MOYUKIT_BOOTSTRAP_TMP"
    fi
}

fail() {
    printf 'MoyuKit bootstrap: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        fail "缺少必需命令：$1"
}

main() {
    local archive checksum extract_dir installer source_root

    require_command curl
    require_command tar
    require_command sha256sum
    require_command find

    MOYUKIT_BOOTSTRAP_TMP="$(mktemp -d "${TMPDIR:-/tmp}/moyukit-bootstrap.XXXXXX")"
    trap cleanup EXIT

    archive="$MOYUKIT_BOOTSTRAP_TMP/latest.tar.gz"
    checksum="$MOYUKIT_BOOTSTRAP_TMP/latest.tar.gz.sha256"
    extract_dir="$MOYUKIT_BOOTSTRAP_TMP/extract"

    printf 'MoyuKit bootstrap %s：正在下载稳定版...\n' "$BOOTSTRAP_VERSION"
    curl --fail --location --silent --show-error --retry 3 --retry-delay 1 \
        "$MOYUKIT_SERVER_URL/latest.tar.gz" --output "$archive"
    curl --fail --location --silent --show-error --retry 3 --retry-delay 1 \
        "$MOYUKIT_SERVER_URL/latest.tar.gz.sha256" --output "$checksum"

    (
        cd "$MOYUKIT_BOOTSTRAP_TMP"
        sha256sum --check "$(basename "$checksum")" >/dev/null
    ) || fail "SHA-256 校验失败"

    mkdir -p "$extract_dir"
    tar -xzf "$archive" -C "$extract_dir" ||
        fail "软件包解压失败"

    installer="$(find "$extract_dir" -mindepth 2 -maxdepth 2 -type f -name install.sh -print -quit)"
    [[ -n "$installer" ]] ||
        fail "软件包中未找到 install.sh"
    source_root="$(cd "$(dirname "$installer")" && pwd -P)"
    [[ -r "$source_root/lib/channel.sh" && -r "$source_root/VERSION" ]] ||
        fail "软件包结构不完整"

    MOYUKIT_SERVER_URL="$MOYUKIT_SERVER_URL" \
        bash "$installer" --local-source "$source_root" "$@"
}

main "$@"
