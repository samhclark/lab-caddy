#!/usr/bin/env bash
# Derive local and published image metadata from the actual build inputs.
set -euo pipefail

fail() {
    printf 'image metadata: %s\n' "$*" >&2
    exit 1
}

tag_only=false
if [[ ${1:-} == --tag ]]; then
    tag_only=true
    shift
fi
(( $# <= 1 )) || fail "usage: $0 [--tag] [CONTAINERFILE]"
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
containerfile="${1:-${repo_dir}/Containerfile}"
[[ -f $containerfile && -r $containerfile ]] || fail "cannot read ${containerfile}"

caddy_pattern='^[[:space:]]*FROM[[:space:]]+docker\.io/library/caddy:([^[:space:]]+)'
reference_pattern='^([0-9]+\.[0-9]+\.[0-9]+)(-builder)?@sha256:[a-f0-9]{64}$'
cloudflare_pattern='--with[[:space:]]+github\.com/caddy-dns/cloudflare@([^[:space:]\\]+)'
module_version_pattern='^v([0-9]+\.[0-9]+\.[0-9]+)$'
builder_versions=()
runtime_versions=()
cloudflare_versions=()

while IFS= read -r line || [[ -n $line ]]; do
    [[ $line =~ ^[[:space:]]*# ]] && continue
    line="${line%%[[:space:]]#*}"
    if [[ $line =~ $caddy_pattern ]]; then
        reference="${BASH_REMATCH[1]}"
        [[ $reference =~ $reference_pattern ]] || fail "invalid digest-pinned Caddy reference: ${reference}"
        version="${BASH_REMATCH[1]}"
        if [[ ${BASH_REMATCH[2]} == -builder ]]; then
            builder_versions+=("$version")
        else
            runtime_versions+=("$version")
        fi
    fi
    # Scan every --with occurrence so duplicate pins on one line also fail.
    while [[ $line =~ $cloudflare_pattern ]]; do
        match="${BASH_REMATCH[0]}"
        pin="${BASH_REMATCH[1]}"
        [[ $pin =~ $module_version_pattern ]] || fail "invalid stable Cloudflare version: ${pin}"
        cloudflare_versions+=("${BASH_REMATCH[1]}")
        line="${line#*"$match"}"
    done
done < "$containerfile"

(( ${#builder_versions[@]} == 1 )) || fail 'expected exactly one digest-pinned Caddy builder reference'
(( ${#runtime_versions[@]} == 1 )) || fail 'expected exactly one digest-pinned Caddy runtime reference'
(( ${#cloudflare_versions[@]} == 1 )) || fail 'expected exactly one Cloudflare module pin'
[[ ${builder_versions[0]} == "${runtime_versions[0]}" ]] || fail 'Caddy builder and runtime versions must match'

caddy_version="${runtime_versions[0]}"
cloudflare_version="${cloudflare_versions[0]}"
image_tag="${caddy_version}-cf-${cloudflare_version}"
if $tag_only; then
    printf '%s\n' "$image_tag"
else
    printf 'caddy_version=%s\ncloudflare_version=%s\nimage_tag=%s\n' \
        "$caddy_version" "$cloudflare_version" "$image_tag"
fi
