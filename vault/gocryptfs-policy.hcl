# gocryptfs-policy.hcl
# Least-privilege Vault ACL: read-only access to a single KV-v2 path.
path "secret/data/gocryptfs" {
  capabilities = ["read"]
}
