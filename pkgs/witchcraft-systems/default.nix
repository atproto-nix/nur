{ pkgs, lib, callPackage, atprotoLib, packageLockJson, ... }:

let
  # Organizational metadata
  organizationMeta = {
    name = "witchcraft-systems";
    displayName = "Witchcraft Systems";
    website = "https://witchcraft.systems";
    contact = null;
    maintainer = "Witchcraft Systems";
    description = "Packages from Witchcraft Systems for the ATProto ecosystem";
    atprotoFocus = [ "tools" "applications" ];
    packageCount = 1; # Will be updated as more packages are added
  };

  packages = {
    pds-dash = callPackage ./pds-dash.nix {
      inherit atprotoLib packageLockJson;
    };
  };

  # Enhanced packages with organizational metadata
  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
        atproto = (oldAttrs.passthru.atproto or {}) // {
          organization = organizationMeta;
        };
      };
      meta = (oldAttrs.meta or {}) // {
        organizationalContext = {
          organization = organizationMeta.name;
          displayName = organizationMeta.name;
        };
      };
    })
  ) packages;

in
enhancedPackages // {
  _organizationMeta = organizationMeta;
}
