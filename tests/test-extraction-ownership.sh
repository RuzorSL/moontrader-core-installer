#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  printf 'This test must run as root to exercise tar owner restoration.\n' >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../install.sh
source "$REPO_ROOT/install.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

SOURCE_DIR="$TEST_DIR/source"
TARGET_DIR="$TEST_DIR/target-home"
ARCHIVE="$TEST_DIR/payload.tar.xz"

mkdir -p "$SOURCE_DIR/MoonTrader_Data" "$TARGET_DIR"
printf '#!/usr/bin/env bash\n' > "$SOURCE_DIR/MTCore"
printf 'test\n' > "$SOURCE_DIR/MoonTrader_Data/payload.txt"
chmod 0700 "$SOURCE_DIR/MTCore"
chmod 0711 "$TARGET_DIR"
chown root:root "$TARGET_DIR"

# Reproduce the upstream archive metadata: every member, including ./, is
# stored as www-data (UID/GID 33).
tar \
  --create \
  --xz \
  --file "$ARCHIVE" \
  --directory "$SOURCE_DIR" \
  --owner=33 \
  --group=33 \
  --numeric-owner \
  .

RUN_USER=root
before="$(stat -c '%u:%g:%a' "$TARGET_DIR")"
extract_core_archive "$ARCHIVE" "$TARGET_DIR"
after="$(stat -c '%u:%g:%a' "$TARGET_DIR")"

[[ "$before" == "$after" ]] || {
  printf 'Target directory metadata changed: before=%s after=%s\n' "$before" "$after" >&2
  exit 1
}

while IFS= read -r path; do
  owner="$(stat -c '%u:%g' "$path")"
  [[ "$owner" == '0:0' ]] || {
    printf 'Unexpected extracted owner for %s: %s\n' "$path" "$owner" >&2
    exit 1
  }
done < <(find "$TARGET_DIR" -mindepth 1 -print)

printf 'Extraction ownership test passed.\n'

