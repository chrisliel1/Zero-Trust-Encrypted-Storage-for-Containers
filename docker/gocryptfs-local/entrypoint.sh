#!/bin/bash
set -euo pipefail

# NOTE: password is a throwaway lab value for the isolated benchmark scenario.
# The production PoC (docker/poc) fetches the key from Vault instead.
PASSWORD="${GOCRYPTFS_PASSWORD:?Set GOCRYPTFS_PASSWORD}"

if [ ! -f /app/cifrado/gocryptfs.conf ]; then
    echo "-> Inicializando gocryptfs en disco local ..."
    echo "$PASSWORD" | gocryptfs -init -passfile /dev/stdin /app/cifrado >/dev/null 2>&1
else
    echo "-> gocryptfs ya estaba inicializado. Saltando formateo ..."
fi

echo "-> Montando volumen cifrado local ..."
echo "$PASSWORD" | gocryptfs -passfile /dev/stdin /app/cifrado /app/descifrado

unset PASSWORD
echo "-> Entorno cifrado local listo"
exec tail -f /dev/null
