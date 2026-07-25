#!/usr/bin/env bash
set -euo pipefail

TEMPLATE="system/prompt_optimizer.md"

for file in *.md; do
    [[ "$file" == "run_optimizer.sh" ]] && continue
    [[ -f "$file" ]] || continue

    echo "=== $file ==="

    tmp=$(mktemp /tmp/prompt_optimizer_XXXXXX.md)
    log=$(mktemp /tmp/prompt_optimizer_log_XXXXXX.txt)

    template=$(< "$TEMPLATE")
    content=$(< "$file")

    prefix="${template%<original_prompt>*}<original_prompt>"
    suffix="</original_prompt>${template#*</original_prompt>}"

    printf '%s\n%s\n%s\n' "$prefix" "$content" "$suffix" > "$tmp"

    merged_hash=$(md5sum "$tmp" | cut -d' ' -f1)

    opencode run "$tmp" > "$log" 2>&1 || true

    # fall 1: model hat per write-tool in datei geschrieben
    if [[ "$(md5sum "$tmp" | cut -d' ' -f1)" != "$merged_hash" ]]; then
        result=$(awk '
            /^---- CUT HERE ----/   { cut=1; next }
            cut && /^```/           { inblock=1; next }
            cut && inblock && /^```/ { inblock=0; next }
            cut && inblock          { print; next }
            cut && !inblock         { print }
        ' "$tmp")
        if [[ -z "$result" ]]; then
            result=$(awk '
                /^```/ { c++; next }
                c == 1 { print }
            ' "$tmp")
        fi
        if [[ -z "$result" ]]; then
            result=$(< "$tmp")
        fi

    # fall 2: model hat nur in konsole geantwortet
    else
        result=$(awk '
            /^```/ { c++; next }
            c == 1 { print }
        ' "$log")
    fi

    if [[ -z "$result" ]]; then
        echo "  ⚠️  Kein optimierter Prompt gefunden"
        rm -f "$tmp" "$log"
        continue
    fi

    echo "$result" > "$file"
    echo "  ✓ $file aktualisiert"
    rm -f "$tmp" "$log"
done
