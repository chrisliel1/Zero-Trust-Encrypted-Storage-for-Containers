#!/bin/bash
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR (e.g. http://vault:8200)}"

MOUNT_POINT="/app/cifrado"
DESCIFRADO_DIR="/app/descifrado"

echo "===================================="
echo " Zero-Trust container decryption PoC"
echo "===================================="

cleanup() {
    fusermount -u "$DESCIFRADO_DIR" 2>/dev/null || true
    unset ROLE_ID SECRET_ID TOKEN PASSWORD
    exit
}
trap cleanup EXIT

# 1. Prompt for Role ID
echo -n "Introduzca el VAULT_ROLE_ID: "
read -r ROLE_ID

# 2. Prompt for Secret ID (hidden)
echo -n "Introduzca el VAULT_SECRET_ID: "
read -s SECRET_ID
echo ""

if [ -z "$ROLE_ID" ] || [ -z "$SECRET_ID" ]; then
    echo "Error: Las credenciales no pueden estar vacías."
    exit 1
fi

# 3. Authenticate against Vault (AppRole) and fetch the master key
LOGIN_PAYLOAD=$(jq -n --arg r "${ROLE_ID}" --arg s "${SECRET_ID}" '{role_id: $r, secret_id: $s}')
unset ROLE_ID SECRET_ID

LOGIN_RESPONSE=$(printf '%s' "${LOGIN_PAYLOAD}" | vault write -format=json auth/approle/login -)
unset LOGIN_PAYLOAD

VAULT_TOKEN=$(printf '%s' "${LOGIN_RESPONSE}" | jq -r '.auth.client_token')
unset LOGIN_RESPONSE

if [ -z "${VAULT_TOKEN}" ] || [ "${VAULT_TOKEN}" = "null" ]; then
    echo "[ERROR] Fallo en la autenticación con HashiCorp Vault." >&2
    exit 1
fi
export VAULT_TOKEN

# ------------------------------------------------------------------------------
# 4. Obtención de clave y revocación inmediata del token
# ------------------------------------------------------------------------------
echo "[VAULT] Extrayendo clave de cifrado..."
PASSWORD=$(vault kv get -field=password secret/gocryptfs)

# Revocación inmediata: el token no persiste durante el ciclo de vida del contenedor
vault token revoke -self >/dev/null 2>&1 || true
unset VAULT_TOKEN



# 5. Mount the encrypted NFS volume via gocryptfs (key via stdin, never on disk)
echo "$PASSWORD" | gocryptfs -passfile /dev/stdin "$MOUNT_POINT" "$DESCIFRADO_DIR"
unset PASSWORD

echo "-> Sistema de archivos listo y descifrado de forma segura."

while true; do
    sleep 3600 &
    wait $!
done
