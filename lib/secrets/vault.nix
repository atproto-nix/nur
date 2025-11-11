# HashiCorp Vault Backend for Secrets Management
#
# This backend integrates with HashiCorp Vault for enterprise secrets management.
# Secrets are fetched from Vault at runtime using the vault CLI or agent.
#
# Usage:
#   secrets = (pkgs.callPackage ./lib/secrets.nix { }).withBackend
#     (import ./lib/secrets/vault.nix { inherit lib config pkgs; });
#
# Requirements:
#   - Vault agent configured with authentication
#   - Vault CLI available in PATH
#   - Proper Vault policies and tokens
#
# Reference: https://www.vaultproject.io/

{ lib, config, pkgs }:

with lib;

let
  vaultBin = "${pkgs.vault}/bin/vault";

in

{
  # Create a secret definition with Vault specific options
  #
  # Args:
  #   name: Secret identifier
  #   vaultPath: Path to secret in Vault (e.g., "secret/data/myapp/database")
  #   vaultKey: Key within the secret (e.g., "password")
  #   vaultAddress: Vault server address (default: from VAULT_ADDR)
  #   cacheDir: Directory to cache decrypted secrets (default: /run/vault-secrets)
  #   owner: File owner (default: "root")
  #   group: File group (default: owner)
  #   mode: File permissions (default: "0400")
  #   renewToken: Whether to renew token before fetching (default: true)
  #
  # Example:
  #   mkSecret {
  #     name = "postgres-password";
  #     vaultPath = "secret/data/database/postgres";
  #     vaultKey = "password";
  #     owner = "postgres";
  #   }
  mkSecret = args@{
    name,
    vaultPath,
    vaultKey ? "value",
    vaultAddress ? "$VAULT_ADDR",
    cacheDir ? "/run/vault-secrets",
    owner ? "root",
    group ? owner,
    mode ? "0400",
    renewToken ? true,
    ...
  }:
  {
    inherit name vaultPath vaultKey vaultAddress cacheDir owner group mode renewToken;
    type = "vault";
  };

  # Get the runtime path where the cached secret will be available
  getSecretPath = secret:
    "${secret.cacheDir}/${secret.name}";

  # Generate NixOS config for vault secrets
  #
  # Creates:
  #   - tmpfiles.d rules for cache directory
  #   - vault-agent configuration (if using agent)
  getSecretOptions = secret:
    let
      cacheDir = secret.cacheDir;
    in
    {
      # Create cache directory with proper permissions
      systemd.tmpfiles.rules = [
        "d '${cacheDir}' 0750 root root - -"
      ];

      # Optional: Configure vault agent
      # Users should configure this separately based on their needs
    };

  # Generate shell code to fetch secret from Vault and load into env var
  #
  # This will:
  #   1. Fetch secret from Vault using vault CLI
  #   2. Cache it to disk
  #   3. Load into environment variable
  #
  # Example output:
  #   # Fetch from Vault if not cached
  #   if [ ! -f /run/vault-secrets/postgres-password ]; then
  #     VAULT_SECRET=$(vault kv get -field=password secret/database/postgres)
  #     echo "$VAULT_SECRET" > /run/vault-secrets/postgres-password
  #     chmod 0400 /run/vault-secrets/postgres-password
  #   fi
  #   export DB_PASSWORD=$(cat /run/vault-secrets/postgres-password)
  mkSecretEnvVar = varName: secret:
    let
      secretPath = getSecretPath secret;
      renewCmd = optionalString secret.renewToken ''
        ${vaultBin} token renew -i 60 2>/dev/null || true
      '';
    in
    ''
      # Fetch secret from Vault if not cached
      if [ ! -f ${secretPath} ]; then
        ${renewCmd}
        VAULT_SECRET=$(${vaultBin} kv get -field=${secret.vaultKey} ${secret.vaultPath})
        echo "$VAULT_SECRET" > ${secretPath}
        chmod ${secret.mode} ${secretPath}
        chown ${secret.owner}:${secret.group} ${secretPath}
      fi
      export ${varName}=$(cat ${secretPath})
    '';

  # Additional Vault specific helpers
  extra = {
    # Fetch dynamic database credentials from Vault
    #
    # Example:
    #   dynamicDbCreds "postgres" {
    #     vaultPath = "database/creds/myapp-role";
    #   }
    dynamicDbCreds = name: opts: mkSecret ({
      inherit name;
      vaultKey = "password";
    } // opts);

    # Fetch PKI certificate from Vault
    #
    # Example:
    #   pkiCert "myapp-tls" {
    #     vaultPath = "pki/issue/myapp";
    #     commonName = "myapp.example.com";
    #   }
    pkiCert = name: { vaultPath, commonName, ... }@opts: mkSecret ({
      inherit name vaultPath;
      vaultKey = "certificate";
    } // opts);
  };
}
