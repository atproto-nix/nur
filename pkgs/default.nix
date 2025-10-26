{ pkgs, lib, craneLib, fetchgit, buildGoModule ? pkgs.buildGoModule, buildNpmPackage ? pkgs.buildNpmPackage, atprotoLib, ... }:

let
  organizationalPackages = {
    # Educational and collaborative platforms
    hyperlink-academy = pkgs.callPackage ./hyperlink-academy { inherit lib; };
    
    # Custom AppView and social platforms
    slices-network = pkgs.callPackage ./slices-network { inherit lib craneLib; fetchFromTangled = pkgs.fetchFromTangled; };
    teal-fm = pkgs.callPackage ./teal-fm { inherit lib; };
    parakeet-social = pkgs.callPackage ./parakeet-social { inherit lib craneLib fetchgit; };
    
    # Media and streaming platforms
    stream-place = pkgs.callPackage ./stream-place { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };
    
    # Language learning and specialized apps
    yoten-app = pkgs.callPackage ./yoten-app { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };
    
    # Client applications
    
    # Development tools and infrastructure
    tangled = pkgs.callPackage ./tangled { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };
    
    # Identity and infrastructure services
    smokesignal-events = pkgs.callPackage ./smokesignal-events { inherit lib craneLib; };
    

    
    # System administration and monitoring
    witchcraft-systems = pkgs.callPackage ./witchcraft-systems {
      inherit lib atprotoLib;
      packageLockJson = builtins.path { path = ./witchcraft-systems/package-lock-pds-dash.json; };
    };
    
    # Bluesky client applications
    whey-party = pkgs.callPackage ./whey-party { inherit lib buildNpmPackage; fetchFromTangled = pkgs.fetchFromTangled; };

    # Official Bluesky packages
    bluesky = pkgs.callPackage ./bluesky { inherit lib; };

    # Photo-sharing platforms
    grain-social = pkgs.callPackage ./grain-social { inherit lib craneLib; };

    # Individual developer packages
    baileytownsend = pkgs.callPackage ./baileytownsend { inherit lib craneLib; };
    mackuba = pkgs.callPackage ./mackuba { inherit lib; };
    whyrusleeping = pkgs.callPackage ./whyrusleeping { inherit lib; };

    # New organizational framework packages
    likeandscribe = pkgs.callPackage ./likeandscribe { inherit lib craneLib buildNpmPackage; };

    # Legacy package collections (for backward compatibility)
    microcosm = pkgs.callPackage ./microcosm { inherit craneLib; };
    blacksky = pkgs.callPackage ./blacksky { inherit lib craneLib; };
  };

  # Helper function to check if something is a derivation
  isDerivation = pkg: 
    (pkg.type or "") == "derivation" ||
    (builtins.isAttrs pkg && pkg ? outPath) ||
    (builtins.isAttrs pkg && pkg ? drvPath);

  # Flatten organizational packages into a single namespace with prefixes
  flattenedPackages = 
    let
      # Helper function to add organizational prefix to package names
      addOrgPrefix = orgName: packages:
        lib.mapAttrs' (pkgName: pkg: 
          lib.nameValuePair "${orgName}-${pkgName}" pkg
        ) (lib.filterAttrs (n: v: n != "_organizationMeta" && isDerivation v) packages);
      
      # Process each organizational collection
      orgCollections = lib.mapAttrsToList (orgName: packages:
        if orgName == "microcosm" || orgName == "blacksky" || orgName == "bluesky"
        then 
          # Legacy collections keep their existing prefixes
          lib.mapAttrs' (pkgName: pkg: 
            lib.nameValuePair "${orgName}-${pkgName}" pkg
          ) (lib.filterAttrs (n: v: n != "_organizationMeta" && isDerivation v) packages)
        else
          # New organizational collections use org-package naming
          addOrgPrefix orgName packages
      ) organizationalPackages;
      
    in
    lib.foldl' (acc: collection: acc // collection) {} orgCollections;

in

flattenedPackages // {
  # Export organizational collections for direct access (not in flake packages)
  organizations = organizationalPackages;
  
  # Export organizational metadata for tooling (not in flake packages)
  _organizationalMetadata = lib.mapAttrs (orgName: packages: 
    packages._organizationMeta or null
  ) (lib.filterAttrs (n: v: n != "microcosm" && n != "blacksky" && n != "bluesky") organizationalPackages);
}
