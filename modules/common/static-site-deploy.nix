# NixOS module for deploying static sites to a web root
# This module provides a simple way to deploy static files from Nix store to a web directory
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.static-site-deploy;

  # Define the submodule type for each site
  siteOptions = { name, config, ... }: {
    options = {
      enable = mkEnableOption "this static site deployment";

      package = mkOption {
        type = types.package;
        description = "The package containing static files to deploy";
      };

      sourceDir = mkOption {
        type = types.str;
        default = "share/${name}";
        description = "Subdirectory within the package containing the static files";
        example = "share/my-app";
      };

      targetDir = mkOption {
        type = types.str;
        description = "Target directory where files will be deployed";
        example = "/var/www/example.com/app";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User that should own the deployed files";
      };

      group = mkOption {
        type = types.str;
        default = "root";
        description = "Group that should own the deployed files";
      };

      restartServices = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of systemd services to restart after deployment";
        example = [ "caddy.service" "nginx.service" ];
      };

      reloadServices = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of systemd services to reload after deployment";
        example = [ "caddy.service" "nginx.service" ];
      };

      wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ "multi-user.target" ];
        description = "Systemd targets that should want this service";
      };

      before = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Systemd services this deployment should run before";
      };

      after = mkOption {
        type = types.listOf types.str;
        default = [ "network.target" ];
        description = "Systemd services this deployment should run after";
      };
    };
  };

  # Generate a systemd service for each enabled site
  mkDeploymentService = name: site: nameValuePair "deploy-${name}" {
    description = "Deploy ${name} static files";
    wantedBy = site.wantedBy;
    before = site.before ++ (map (s: "${s}") site.restartServices);
    after = site.after;

    script = ''
      # Ensure target directory exists
      mkdir -p ${site.targetDir}

      # Deploy files using rsync
      ${pkgs.rsync}/bin/rsync -a --delete \
        ${site.package}/${site.sourceDir}/ \
        ${site.targetDir}/

      # Set ownership
      chown -R ${site.user}:${site.group} ${site.targetDir}
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    # Reload or restart services after deployment
    postStop = optionalString ((length site.reloadServices) > 0 || (length site.restartServices) > 0) ''
      ${concatMapStringsSep "\n" (s: "${pkgs.systemd}/bin/systemctl reload ${s} || true") site.reloadServices}
      ${concatMapStringsSep "\n" (s: "${pkgs.systemd}/bin/systemctl restart ${s} || true") site.restartServices}
    '';
  };

in
{
  options.services.static-site-deploy = {
    sites = mkOption {
      type = types.attrsOf (types.submodule siteOptions);
      default = {};
      description = "Attribute set of static sites to deploy";
      example = literalExpression ''
        {
          my-app = {
            enable = true;
            package = pkgs.my-static-app;
            sourceDir = "share/my-app";
            targetDir = "/var/www/example.com/my-app";
            user = "caddy";
            group = "caddy";
            reloadServices = [ "caddy.service" ];
          };
        }
      '';
    };
  };

  config = mkIf (any (site: site.enable) (attrValues cfg.sites)) {
    # Create systemd services for all enabled sites
    systemd.services = listToAttrs (
      mapAttrsToList mkDeploymentService (
        filterAttrs (n: v: v.enable) cfg.sites
      )
    );
  };
}
