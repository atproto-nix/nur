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

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File to load environment variables from.

        Use it to set values of `COCOON_ADMIN_PASSWORD` and `COCOON_SESSION_SECRET`.
        These can be generated with:
        ```
        openssl rand -hex 16
        ```
      '';
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
      description = "Path to the rotation key file (DER-encoded secp256k1 private key).";
    };

    jwkPath = mkOption {
      type = types.str;
      default = "${cfg.keysDir}/jwk.key";
      description = "Path to the JWK key file (public key).";
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

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.keysDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/db' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.hailey-at-cocoon = {
      description = "Cocoon Personal Data Server (PDS)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      preStart = ''
        set -euo pipefail
        # Ensure the keys directory exists
        ${pkgs.coreutils}/bin/mkdir -p "${cfg.keysDir}"
        ${pkgs.coreutils}/bin/chown "${cfg.user}:${cfg.group}" "${cfg.keysDir}"

        # Generate rotation key if it doesn't exist
        if [ ! -f "${cfg.rotationKeyPath}" ]; then
          ${pkgs.coreutils}/bin/echo "Generating rotation key at ${cfg.rotationKeyPath}..."
          ${pkgs.openssl}/bin/openssl ecparam -name secp256k1 -genkey -noout -outform DER -out "${cfg.rotationKeyPath}"
          ${pkgs.coreutils}/bin/chown "${cfg.user}:${cfg.group}" "${cfg.rotationKeyPath}"
          ${pkgs.coreutils}/bin/chmod 600 "${cfg.rotationKeyPath}"
        fi

        # Generate JWK if it doesn't exist
        if [ ! -f "${cfg.jwkPath}" ]; then
          ${pkgs.coreutils}/bin/echo "Generating JWK at ${cfg.jwkPath}..."

          PUB_KEY_TEXT=$(${pkgs.openssl}/bin/openssl ec -in "${cfg.rotationKeyPath}" -inform DER -pubout | ${pkgs.openssl}/bin/openssl ec -pubin -text -noout 2>/dev/null)

          # The awk script extracts the hex key from the multiline 'pub:' section of the openssl output
          HEX_PUBKEY=$(echo "$PUB_KEY_TEXT" | ${pkgs.gawk}/bin/awk '/pub:/{flag=1; next} /ASN1 OID:/{flag=0} flag' | ${pkgs.coreutils}/bin/tr -d '[:space:]:' | ${pkgs.gnused}/bin/sed 's/^04//')

          HEX_X=''${HEX_PUBKEY:0:64}
          HEX_Y=''${HEX_PUBKEY:64:128}

          # Function to convert hex to base64url
          hex_to_base64url() {
            # Use xxd for hex to binary, then base64 for encoding
            # The tr commands make it URL-safe
            ${pkgs.coreutils}/bin/echo -n "$1" | ${pkgs.xxd-standalone}/bin/xxd -r -p | ${pkgs.coreutils}/bin/base64 | ${pkgs.coreutils}/bin/tr -d '=' | ${pkgs.coreutils}/bin/tr '/+' '_-'
          }

          B64_X=$(hex_to_base64url "$HEX_X")
          B64_Y=$(hex_to_base64url "$HEX_Y")

          ${pkgs.jq}/bin/jq -n \
            --arg kty "EC" \
            --arg crv "secp256k1" \
            --arg x "$B64_X" \
            --arg y "$B64_Y" \
            '{kty: $kty, crv: $crv, x: $x, y: $y}' > "${cfg.jwkPath}"

          ${pkgs.coreutils}/bin/chown "${cfg.user}:${cfg.group}" "${cfg.jwkPath}"
          ${pkgs.coreutils}/bin/chmod 644 "${cfg.jwkPath}"
        fi
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/cocoon run";
        Restart = "on-failure";
        RestartSec = "10s";
        EnvironmentFile = cfg.environmentFile;

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
    };
  };
}