#!/usr/bin/env bash
set -euo pipefail

if ! command -v AzureSignTool &>/dev/null; then
    echo "AzureSignTool not installed. Signing will be skipped."
    exit
fi

SIGN_LOG="${FIREZONE_SIGN_LOG:-}"
if [ -n "$SIGN_LOG" ]; then
    mkdir -p "$(dirname "$SIGN_LOG")"
fi

for exe in "$@"
do
    if [ -n "$SIGN_LOG" ]; then
        {
            echo
            echo "== $(date -u +"%Y-%m-%dT%H:%M:%SZ") signing $exe =="
            echo "PWD=$(pwd)"
            echo "AzureSignTool=$(command -v AzureSignTool)"
            if [ -e "$exe" ]; then
                ls -l "$exe"
            else
                echo "Bash cannot stat input path: $exe"
            fi
        } >> "$SIGN_LOG"
        OUTPUT="$(mktemp)"
        if AzureSignTool sign \
            --azure-key-vault-url "$AZURE_KEY_VAULT_URI" \
            --azure-key-vault-client-id "$AZURE_CLIENT_ID" \
            --azure-key-vault-tenant-id "$AZURE_TENANT_ID" \
            --azure-key-vault-client-secret "$AZURE_CLIENT_SECRET" \
            --azure-key-vault-certificate "$AZURE_CERT_NAME" \
            --timestamp-rfc3161 "http://timestamp.digicert.com" \
            --verbose "$exe" >"$OUTPUT" 2>&1
        then
            cat "$OUTPUT" | tee -a "$SIGN_LOG"
            rm -f "$OUTPUT"
        else
            STATUS="$?"
            cat "$OUTPUT" | tee -a "$SIGN_LOG" >&2
            rm -f "$OUTPUT"
            exit "$STATUS"
        fi
    else
        AzureSignTool sign \
            --azure-key-vault-url "$AZURE_KEY_VAULT_URI" \
            --azure-key-vault-client-id "$AZURE_CLIENT_ID" \
            --azure-key-vault-tenant-id "$AZURE_TENANT_ID" \
            --azure-key-vault-client-secret "$AZURE_CLIENT_SECRET" \
            --azure-key-vault-certificate "$AZURE_CERT_NAME" \
            --timestamp-rfc3161 "http://timestamp.digicert.com" \
            --verbose "$exe"
    fi
done
