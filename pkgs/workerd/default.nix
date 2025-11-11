{ pkgs, lib, ... }:

let
  organizationMeta = {
    name = "workerd";
    displayName = "Cloudflare workerd";
    website = "https://github.com/cloudflare/workerd";
    contact = null;
    maintainer = "Cloudflare";
    description = "JavaScript/Wasm runtime for self-hosting Cloudflare Workers";
    atprotoFocus = [ "infrastructure" "utilities" ];
    packageCount = 1;
  };

  packages = {
    workerd = pkgs.callPackage ./workerd.nix { };
  };

  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
      };
      meta = (oldAttrs.meta or {}) // {
        organizationalContext = {
          organization = organizationMeta.name;
          displayName = organizationMeta.displayName;
        };
      };
    })
  ) packages;

  allPackages = pkgs.symlinkJoin {
    name = "workerd-all";
    paths = lib.attrValues packages;
    meta = {
      description = "All workerd packages";
      homepage = "https://github.com/cloudflare/workerd";
    };
  };

in
enhancedPackages // {
  all = allPackages;
  _organizationMeta = organizationMeta;
}
