# Defines the NixOS module for Cocoon PDS
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hailey-at-cocoon;
in
{
  options.services.hailey-at-cocoon = {
    enable = mkEnableOption "Cocoon Personal Data Server (PDS)";

    package = mkOption {
      type = types.package;
      default = pkgs.hailey-at-cocoon or pkgs.cocoon;
      description = "The Cocoon package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/cocoon";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "cocoon";
      description = "User account for Cocoon service.";
    };

    group = mkOption {
      type = types.str;
      default = "cocoon";
      description = "Group for Cocoon service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          did = mkOption {
            type = types.str;
            description = "DID for the PDS (did:web format).";
            example = "did:web:pds.example.com";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the PDS.";
            example = "pds.example.com";
          };

          contactEmail = mkOption {
            type = types.str;
            description = "Contact email for the PDS administrator.";
            example = "admin@example.com";
          };

          relays = mkOption {
            type = types.str;
            default = "https://bsky.network";
            description = "ATProto relay URLs (comma-separated if multiple).";
          };


          server = {
            addr = mkOption {
              type = types.str;
              default = ":8080";
              description = "Address to bind the server to.";
            };

            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port for the Cocoon server.";
            };
          };

          blockstoreVariant = mkOption {
            type = types.enum [ "sqlite" "s3" ];
            default = "sqlite";
            description = "Blockstore variant to use (sqlite or s3).";
          };

          smtp = {
            user = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "SMTP username for sending emails.";
            };

            pass = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "SMTP password for sending emails.";
            };

            host = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "SMTP host.";
            };

            port = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "SMTP port.";
            };

            email = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "From email address.";
            };

            name = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "From name.";
            };
          };

          s3 = {
            backupsEnabled = mkOption {
              type = types.bool;
              default = false;
              description = "Enable S3 backups.";
            };

            blobstoreEnabled = mkOption {
              type = types.bool;
              default = false;
              description = "Enable S3 blobstore.";
            };

            region = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "S3 region.";
            };

            bucket = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "S3 bucket name.";
            };

            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "S3 endpoint URL.";
            };

            accessKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "S3 access key.";
            };

            secretKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "S3 secret key.";
            };
          };

          fallbackProxy = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Fallback proxy URL for unimplemented endpoints.";
          };

          logLevel = mkOption {
            type = types.enum [ "debug" "info" "warn" "error" ];
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Cocoon service configuration.";
    };

    keysDir = mkOption {
      type = types.str;
      default = "${cfg.dataDir}/keys";
      description = "Directory to store cryptographic keys.";
    };

    rotationKeyPath = mkOption {
      type = types.str;
      default = "${cfg.keysDir}/rotation.key";
      description = "Path to the rotation key file.";
    };

    jwkPath = mkOption {
      type = types.str;
      default = "${cfg.keysDir}/jwk.key";
      description = "Path to the JWK key file.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.did != "";
        message = "services.hailey-at-cocoon: DID must be specified";
      }
      {
        assertion = cfg.settings.hostname != "";
        message = "services.hailey-at-cocoon: Hostname must be specified";
      }
      {
        assertion = cfg.settings.contactEmail != "";
        message = "services.hailey-at-cocoon: Contact email must be specified";
      }

    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.keysDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/db' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Cocoon PDS service
    systemd.services.hailey-at-cocoon = {
      description = "Cocoon Personal Data Server (PDS)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

    serviceConfig = {
      Type = "exec";
      User = "cocoon";
      Group = "cocoon";
      WorkingDirectory = "/var/lib/cocoon";
      Path = lib.makeBinPath [ pkgs.python313Packages.python ];
        Restart = "on-failure";
        RestartSec = "10s";


        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;

        # File system access
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        COCOON_DID = cfg.settings.did;
        COCOON_HOSTNAME = cfg.settings.hostname;
        COCOON_CONTACT_EMAIL = cfg.settings.contactEmail;
        COCOON_RELAYS = cfg.settings.relays;
        COCOON_ROTATION_KEY_PATH = cfg.rotationKeyPath;
        COCOON_JWK_PATH = cfg.jwkPath;
        COCOON_ADDR = cfg.settings.server.addr;
        COCOON_DB_NAME = "${cfg.dataDir}/db/cocoon.db";
        COCOON_BLOCKSTORE_VARIANT = cfg.settings.blockstoreVariant;
        LOG_LEVEL = cfg.settings.logLevel;
      } // optionalAttrs (cfg.settings.smtp.user != null) {
        COCOON_SMTP_USER = cfg.settings.smtp.user;
      } // optionalAttrs (cfg.settings.smtp.pass != null) {
        COCOON_SMTP_PASS = cfg.settings.smtp.pass;
      } // optionalAttrs (cfg.settings.smtp.host != null) {
        COCOON_SMTP_HOST = cfg.settings.smtp.host;
      } // optionalAttrs (cfg.settings.smtp.port != null) {
        COCOON_SMTP_PORT = toString cfg.settings.smtp.port;
      } // optionalAttrs (cfg.settings.smtp.email != null) {
        COCOON_SMTP_EMAIL = cfg.settings.smtp.email;
      } // optionalAttrs (cfg.settings.smtp.name != null) {
        COCOON_SMTP_NAME = cfg.settings.smtp.name;
      } // optionalAttrs (cfg.settings.s3.backupsEnabled) {
        COCOON_S3_BACKUPS_ENABLED = "true";
      } // optionalAttrs (cfg.settings.s3.blobstoreEnabled) {
        COCOON_S3_BLOBSTORE_ENABLED = "true";
      } // optionalAttrs (cfg.settings.s3.region != null) {
        COCOON_S3_REGION = cfg.settings.s3.region;
      } // optionalAttrs (cfg.settings.s3.bucket != null) {
        COCOON_S3_BUCKET = cfg.settings.s3.bucket;
      } // optionalAttrs (cfg.settings.s3.endpoint != null) {
        COCOON_S3_ENDPOINT = cfg.settings.s3.endpoint;
      } // optionalAttrs (cfg.settings.s3.accessKey != null) {
        COCOON_S3_ACCESS_KEY = cfg.settings.s3.accessKey;
      } // optionalAttrs (cfg.settings.s3.secretKey != null) {
        COCOON_S3_SECRET_KEY = cfg.settings.s3.secretKey;
      } // optionalAttrs (cfg.settings.fallbackProxy != null) {
        COCOON_FALLBACK_PROXY = cfg.settings.fallbackProxy;
      };

      script = ''
        set -x
        rm -rf "${cfg.keysDir}"/*
        export COCOON_ADMIN_PASSWORD=$(cat /run/secrets/cocoon-admin-password)
        export COCOON_SESSION_SECRET=$(cat /run/secrets/cocoon-session-secret)

        # Ensure keys exist or create them
        if [ ! -f "${cfg.rotationKeyPath}" ]; then
          echo "Generating rotation key at ${cfg.rotationKeyPath}..."
          # Generate a temporary PEM private key
          TEMP_PEM_KEY=$(mktemp)
          ${pkgs.openssl}/bin/openssl ecparam -name secp256k1 -genkey -noout -outform PEM -out "$TEMP_PEM_KEY"
          # Extract the raw 32-byte private key from the temporary PEM file
          ${pkgs.openssl}/bin/openssl ec -in "$TEMP_PEM_KEY" -outform DER | tail -c 32 > "${cfg.rotationKeyPath}"
          chmod 600 "${cfg.rotationKeyPath}"
          echo "--- Content of rotation.key after generation (raw bytes) ---"
          ${pkgs.hexdump}/bin/hexdump -C "${cfg.rotationKeyPath}"
          echo "------------------------------------------------"

          # Generate JWK key from the temporary PEM private key
          echo "Generating JWK key at ${cfg.jwkPath} from temporary PEM private key..."
          # Use python and pyjwkest to convert PEM to JWK
          ${pkgs.python313Packages.python}/bin/python -c '
import sys
from jwcrypto import jwk
import json

pem_data = sys.stdin.read()
key = jwk.JWK.from_pem(pem_data.encode("utf-8"))
print(json.dumps(json.loads(key.export_public()), indent=2))
          ' < "$TEMP_PEM_KEY" > /var/lib/cocoon/keys/jwk.key
          chmod 664 "${cfg.jwkPath}"
          rm "$TEMP_PEM_KEY" # Clean up temporary file
        fi

        # If rotationKeyPath exists but jwkPath doesn't, generate jwkPath from rotationKeyPath (assuming rotationKeyPath is PEM for this case)
        # This block is for backward compatibility if rotationKeyPath was previously generated as PEM
        if [ -f "${cfg.rotationKeyPath}" ] && [ ! -f "${cfg.jwkPath}" ]; then
          echo "JWK key not found, attempting to generate from existing rotation key (assuming PEM format)..."
          # Attempt to generate JWK from rotationKeyPath, assuming it might be PEM from a previous run
          # If rotationKeyPath is raw bytes, this command will fail, but the primary generation block above handles the correct flow.
          ${pkgs.openssl}/bin/openssl ec -in "${cfg.rotationKeyPath}" -inform PEM -pubout -outform PEM -out "${cfg.jwkPath}" || true
          chmod 664 "${cfg.jwkPath}"
        fi

        # Ensure jwkPath exists after all attempts, if not, it means rotationKeyPath was raw and jwkPath wasn't generated.
        # In this case, we need to regenerate both. This scenario should ideally not happen with the new logic.
        if [ ! -f "${cfg.jwkPath}" ]; then
          echo "JWK key still not found after all attempts. This indicates an issue with key generation. Please check logs."
          exit 1
        fi

        exec ${cfg.package}/bin/cocoon run
      '';
    };
  };
}
