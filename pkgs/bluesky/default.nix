{ pkgs, lib, ... }:

# Official Bluesky ATProto packages
# Organization: bluesky (formerly bluesky-social)
# Website: https://bsky.social

let
  # Organizational metadata
  organizationMeta = {
    name = "bluesky";
    displayName = "Official Bluesky";
    website = "https://bsky.social";
    contact = null;
    maintainer = "Bluesky Social";
    description = "Official Bluesky ATProto implementations and tools";
    atprotoFocus = [ "infrastructure" "servers" "libraries" ];
    packageCount = 18;
  };

  # Package naming pattern: use simple names within organization
  packages =
    let
      # Load all Indigo services once
      indigo = pkgs.callPackage ./indigo.nix { inherit (pkgs) buildGoModule fetchFromGitHub; };
    in
    {
      # Go implementation (Indigo) - all services
      indigo = indigo;

      # Core relay services
      indigo-relay = indigo.relay;
      indigo-bigsky = indigo.bigsky;
      indigo-rainbow = indigo.rainbow;

      # Search & discovery services
      indigo-palomar = indigo.palomar;
      indigo-bluepages = indigo.bluepages;
      indigo-collectiondir = indigo.collectiondir;

      # Moderation & monitoring services
      indigo-hepa = indigo.hepa;
      indigo-beemo = indigo.beemo;
      indigo-sonar = indigo.sonar;

      # Operational tools
      indigo-netsync = indigo.netsync;
      indigo-gosky = indigo.gosky;

      # TypeScript libraries from @atproto/* packages
      atproto-api = pkgs.callPackage ./atproto-api.nix { };
      atproto-lexicon = pkgs.callPackage ./atproto-lexicon.nix { };
      atproto-xrpc = pkgs.callPackage ./atproto-xrpc.nix { };
      atproto-did = pkgs.callPackage ./atproto-did.nix { };
      atproto-identity = pkgs.callPackage ./atproto-identity.nix { };
      atproto-repo = pkgs.callPackage ./atproto-repo.nix { };
      atproto-syntax = pkgs.callPackage ./atproto-syntax.nix { };
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
          displayName = organizationMeta.displayName;
        };
      };
    })
  ) packages;

  # Create an "all" derivation to build all packages at once
  allPackages = pkgs.symlinkJoin {
    name = "bluesky-all";
    paths = lib.attrValues enhancedPackages;
    meta = {
      description = "All Bluesky packages";
      homepage = "https://bsky.social";
    };
  };

in
enhancedPackages // {
  # Export "all" package to build everything at once
  all = allPackages;

  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}
