#!/usr/bin/env bash
# Prints the Scope section of a PR description as Markdown: files by kind
# (production, migrations, resources, tests, build/config/docs), new/changed/
# moved/deleted counts, line totals, and production files by area.
#
#   pr-scope.sh                        # committed changes vs origin/develop
#   pr-scope.sh origin/master          # against another base
#   pr-scope.sh --working              # include uncommitted changes (not untracked files)
#   pr-scope.sh --stack laravel        # override detection: android|laravel|ios|go|dbt|terraform|generic
#
# Run from anywhere inside the repo. Counts come from `git diff -M` against the
# merge base, the same range GitHub shows. The goal and "Where to look" are left
# for a person.
set -euo pipefail

BASE="origin/develop"
WORKING=""
STACK=""
while [ $# -gt 0 ]; do
  case "$1" in
    --working) WORKING=1 ;;
    --stack) STACK="$2"; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) BASE="$1" ;;
  esac
  shift
done

cd "$(git rev-parse --show-toplevel)"

if [ -z "$STACK" ]; then
  if [ -f artisan ] && [ -f composer.json ]; then STACK=laravel
  elif [ -f go.mod ]; then STACK=go
  elif [ -n "$(find . -maxdepth 2 -name dbt_project.yml -print -quit)" ]; then STACK=dbt
  elif [ -n "$(find . -maxdepth 2 -name 'settings.gradle*' -print -quit)" ]; then STACK=android
  elif [ -n "$(find . -maxdepth 1 -name '*.xcodeproj' -print -quit)" ]; then STACK=ios
  elif [ -n "$(find . -maxdepth 1 -name '*.tf' -print -quit)" ]; then STACK=terraform
  else STACK=generic
  fi
fi

MERGE_BASE="$(git merge-base "$BASE" HEAD)"
RANGE=("$MERGE_BASE")
[ -z "$WORKING" ] && RANGE+=(HEAD)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# status <TAB> path, keyed on the new path for renames.
git diff -M -z --name-status "${RANGE[@]}" | while IFS= read -r -d '' status; do
  IFS= read -r -d '' path
  case "$status" in R*) IFS= read -r -d '' path ;; esac
  printf '%s\t%s\n' "${status:0:1}" "$path"
done > "$TMP/status"

# path <TAB> added <TAB> deleted. A rename has an empty path, then old and new.
git diff -M -z --numstat "${RANGE[@]}" | while IFS= read -r -d '' rec; do
  path="${rec#*$'\t'}"; path="${path#*$'\t'}"
  if [ -z "$path" ]; then
    IFS= read -r -d '' _old
    IFS= read -r -d '' path
  fi
  added="${rec%%$'\t'*}"; rest="${rec#*$'\t'}"; deleted="${rest%%$'\t'*}"
  printf '%s\t%s\t%s\n' "$path" "$added" "$deleted"
done > "$TMP/numstat"

if [ ! -s "$TMP/status" ]; then
  echo "No changes between $BASE and ${WORKING:+the working tree}${WORKING:-HEAD}." >&2
  exit 1
fi

awk -F'\t' -v stack="$STACK" '
  function plural(n) { return n == 1 ? "file" : "files" }
  # Area: the first `depth` directories of p, or "(root)".
  function dirs(p, depth,   n, seg, out, i) {
    n = split(p, seg, "/")
    if (n <= 1) return "(root)"
    out = seg[1]
    for (i = 2; i <= depth && i < n; i++) out = out "/" seg[i]
    return out
  }
  # Sets the globals kind and area for one path. area is only read for Production kinds.
  function classify(path,   module, a) {
    area = ""
    if (path ~ /^\./ || path ~ /(^|\/)(docs?|scripts|\.github|\.claude)\// || path ~ /\.md$/) { kind = "Build / config / docs"; return }

    if (stack == "android") {
      module = path; sub(/\/src\/.*/, "", module); sub(/.*\//, "", module)
      if (path ~ /\/src\/(test|androidTest|testFixtures)[A-Za-z]*\//) kind = "Tests"
      else if (path ~ /\/src\/[A-Za-z]*\/(java|kotlin)\/.*\.(kt|java)$/) {
        kind = "Production: `:" module "`"
        # Module plus up to two package levels below com/blackout_technologies.
        a = path; sub(/.*\/(java|kotlin)\//, "", a); sub(/^com\/blackout_technologies\//, "", a)
        area = module ": " dirs(a, 2)
      }
      else if (path ~ /\/src\/[A-Za-z]*\//) kind = "Resources / manifest: `:" module "`"
      else kind = "Build / config / docs"
    }
    else if (stack == "laravel") {
      if (path ~ /^tests\//) kind = "Tests"
      else if (path ~ /^database\/migrations\//) kind = "Migrations"
      else if (path ~ /^(app|routes)\// || path ~ /^database\/(seeders|factories)\//) { kind = "Production"; area = dirs(path, 3) }
      else if (path ~ /^resources\/(views|js|css)\//) { kind = "Production: views / frontend"; area = dirs(path, 3) }
      else if (path ~ /^(lang|resources|public)\//) kind = "Resources / lang"
      else kind = "Build / config / docs"
    }
    else if (stack == "ios") {
      if (path ~ /(^|\/)[A-Za-z]*(UI)?Tests\// || path ~ /Tests?\.swift$/) kind = "Tests"
      else if (path ~ /\.(swift|m|h)$/) {
        # Target is the first directory; a file at the root has none.
        kind = "Production: " (path ~ /\// ? "`" dirs(path, 1) "`" : "(root)")
        area = dirs(path, 3)
      }
      else if (path ~ /\.(xcodeproj|xcworkspace)\// || path ~ /(^|\/)(fastlane|Gemfile)/ || path ~ /\.(entitlements|xcconfig|sh|yml)$/) kind = "Build / config / docs"
      else kind = "Resources / plist"
    }
    else if (stack == "go") {
      if (path ~ /_test\.go$/ || path ~ /(^|\/)testdata\//) kind = "Tests"
      else if (path ~ /\.go$/) { kind = "Production"; area = dirs(path, 2) }
      else kind = "Build / config / docs"
    }
    else if (stack == "dbt") {
      if (path ~ /(^|\/)tests\// || path ~ /(^|\/)models\/.*\.yml$/) kind = "Tests / schema"
      else if (path ~ /(^|\/)(models|macros|snapshots|seeds)\//) { kind = "Production"; area = dirs(path, 3) }
      else kind = "Build / config / docs"
    }
    else if (stack == "terraform") {
      if (path ~ /\.(tf|tftpl)$/ || path ~ /\.tpl$/) { kind = "Production: Terraform"; area = dirs(path, 2) }
      else if (path ~ /(^|\/)lambdas?\// && path !~ /test/) { kind = "Production: lambdas"; area = dirs(path, 2) }
      else if (path ~ /test/) kind = "Tests"
      else kind = "Build / config / docs"
    }
    else {
      if (path ~ /(^|\/)(tests?|spec|__tests__)\// || path ~ /[._-](test|spec)\.[a-z]+$/ || path ~ /Tests?\.[a-z]+$/) kind = "Tests"
      else if (path ~ /\.(go|kt|java|swift|php|py|ts|tsx|js|jsx|svelte|vue|rb|rs|sql)$/) { kind = "Production"; area = dirs(path, 2) }
      else kind = "Build / config / docs"
    }
  }

  NR == FNR { added[$1] = ($2 == "-" ? 0 : $2); deleted[$1] = ($3 == "-" ? 0 : $3); next }
  {
    status = $1; path = $2
    a = added[path] + 0; d = deleted[path] + 0
    classify(path)

    if (!(kind in files)) {
      # Production first, then migrations, resources, tests, build/config.
      rank = (kind ~ /^Production/) ? 1 : (kind == "Migrations") ? 2 : (kind ~ /^Resources/) ? 3 : (kind ~ /^Tests/) ? 4 : 5
      order[++kinds] = rank "\t" kind
    }
    files[kind]++; adds[kind] += a; dels[kind] += d
    if (status == "A") new[kind]++
    else if (status == "D") gone[kind]++
    else if (status == "R") moved[kind]++
    else changed[kind]++
    total++
    if (kind ~ /^Tests/) tests++
    else if (kind ~ /^Production/) {
      prodA += a; prodD += d; prod++
      if (!(area in areaFiles)) areas[++areaCount] = area
      areaFiles[area]++
    }
  }
  END {
    printf "> **%d %s, one goal: <!-- goal -->.** Tests: %d %s. ", total, plural(total), tests, plural(tests)
    if (prod) printf "Production: +%d / \342\210\222%d across %d %s.\n\n", prodA, prodD, prod, plural(prod)
    else print "No production code.\n"
    print "| Kind | Files | New | Changed | Lines |"
    print "|---|--:|--:|--:|---|"
    for (i = 1; i <= kinds; i++) for (j = i + 1; j <= kinds; j++)
      if (order[j] < order[i]) { t = order[i]; order[i] = order[j]; order[j] = t }
    for (i = 1; i <= kinds; i++) {
      k = order[i]; sub(/^[0-9]\t/, "", k)
      c = changed[k] ? changed[k] "" : ""
      if (moved[k]) c = c (c == "" ? "" : " + ") moved[k] " moved"
      if (gone[k]) c = c (c == "" ? "" : " + ") gone[k] " deleted"
      if (c == "") c = "0"
      printf "| %s | %d | %d | %s | +%d \342\210\222%d |\n", k, files[k], new[k], c, adds[k], dels[k]
    }
    print ""
    print "**Where to look:** <!-- the few files that carry the logic; the rest is mechanical -->"
    print "- "
    if (areaCount > 1) {
      # Largest areas first.
      for (i = 1; i <= areaCount; i++) for (j = i + 1; j <= areaCount; j++)
        if (areaFiles[areas[j]] > areaFiles[areas[i]]) { t = areas[i]; areas[i] = areas[j]; areas[j] = t }
      printf "\n<details><summary>By area (%d production files)</summary>\n\n", prod
      print "| Area | Files |"
      print "|---|--:|"
      for (i = 1; i <= areaCount; i++) printf "| `%s` | %d |\n", areas[i], areaFiles[areas[i]]
      print "\n</details>"
    }
  }
' "$TMP/numstat" "$TMP/status"
