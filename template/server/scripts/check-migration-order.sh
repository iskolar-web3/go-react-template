#!/usr/bin/env bash
# Fails when a branch adds a goose migration whose version is not newer than
# every migration already on the base branch. goose refuses to apply such
# "missing" migrations on a database that already ran the newer ones.
#
# Usage (from server/): bash scripts/check-migration-order.sh [base-ref]
set -euo pipefail

base_ref=${1:-origin/main}
dir=migrations
pattern='^([0-9]+)_.+\.sql$'

if ! git rev-parse --verify --quiet "${base_ref}^{commit}" >/dev/null; then
  echo "ERROR: base ref not found: $base_ref" >&2
  exit 1
fi

max_base=0
max_version() {
  local file version
  while IFS= read -r -d '' file; do
    if [[ ${file##*/} =~ $pattern ]]; then
      version=$((10#${BASH_REMATCH[1]}))
      ((version > max_base)) && max_base=$version
    fi
  done < <(git ls-tree -r --name-only -z "$1" -- "$dir")
  return 0
}
max_version "$base_ref"

# PRs into develop also check main, so a hotfix migration on main is caught
# now instead of when develop merges into main.
main_ref=${base_ref%/*}/main
[[ $base_ref == */* ]] || main_ref=main
if [[ $base_ref != "$main_ref" ]] && git rev-parse --verify --quiet "${main_ref}^{commit}" >/dev/null; then
  max_version "$main_ref"
fi

failed=0
declare -A seen=()
shopt -s nullglob
for file in "$dir"/*.sql; do
  name=${file##*/}
  if [[ ! $name =~ $pattern ]]; then
    echo "ERROR: invalid migration filename: $file (want <version>_<name>.sql)"
    failed=1
    continue
  fi
  version=$((10#${BASH_REMATCH[1]}))
  if [[ -v seen[$version] ]]; then
    echo "ERROR: duplicate migration version $version: ${seen[$version]} and $name"
    failed=1
  fi
  seen[$version]=$name
done

merge_base=$(git merge-base "$base_ref" HEAD)
while IFS= read -r -d '' file; do
  [[ ${file##*/} =~ $pattern ]] || continue # reported above
  version=$((10#${BASH_REMATCH[1]}))
  if ((version <= max_base)); then
    echo "ERROR: $file (ver. $version) is <= base max ($max_base)"
    failed=1
  else
    echo "OK: $file"
  fi
done < <(git diff --no-renames --diff-filter=A --name-only -z "$merge_base" HEAD -- "$dir/*.sql")

if ((failed)); then
  echo "Fix: rename with 'goose create' or a version greater than $max_base, e.g. $(date -u +%Y%m%d%H%M%S)_name.sql"
  exit 1
fi
echo "OK: migration order valid (base: $base_ref, max: $max_base)"
