{ pkgs, lib, craneLib, buildGoModule ? pkgs.buildGoModule, buildNpmPackage ? pkgs.buildNpmPackage, ... }:

let
  # Import all organizational package collections
  organizationalPackages = {
    # Educational and collaborative platforms
    hyperlink-academy = pkgs.callPackage ./hyperlink-academy { inherit lib; };
    
    # Custom AppView and social platforms
    slices-network = pkgs.callPackage ./slices-network { inherit lib; };
    teal-fm = pkgs.callPackage ./teal-fm { inherit lib; };
    parakeet-social = pkgs.callPackage ./parakeet-social { inherit lib; };
    
    # Media and streaming platforms
    stream-place = pkgs.callPackage ./stream-place { inherit lib buildGoModule; };
    
    # Language learning and specialized apps
    yoten-app = pkgs.callPackage ./yoten-app { inherit lib; };
    
    # Client applications
    red-dwarf-client = pkgs.callPackage ./red-dwarf-client { inherit lib buildNpmPackage; };
    
    # Development tools and infrastructure
    tangled-dev = pkgs.callPackage ./tangled-dev { inherit lib; };
    
    # Identity and infrastructure services
    smokesignal-events = pkgs.callPackage ./smokesignal-events { inherit lib craneLib; };
    
    # Microcosm ecosystem tools
    microcosm-blue = pkgs.callPackage ./microcosm-blue { inherit lib craneLib; };
    
    # System administration and monitoring
    witchcraft-systems = pkgs.callPackage ./witchcraft-systems { inherit lib; };
    
    # Backup and archival tools
    atbackup-pages-dev = pkgs.callPackage ./atbackup-pages-dev { inherit lib; };
    
    # Official Bluesky packages
    bluesky-social = pkgs.callPackage ./bluesky-social { inherit lib; };
    
    # Individual developer packages
    individual = pkgs.callPackage ./individual { inherit lib craneLib; };
    
    # New organizational framework packages
    atproto = pkgs.callPackage ./atproto { inherit lib craneLib buildGoModule buildNpmPackage; };
    
    # Legacy package collections (for backward compatibility)
    microcosm = pkgs.callPackage ./microcosm { inherit craneLib; };
    blacksky = pkgs.callPackage ./blacksky { inherit craneLib; };
    bluesky = pkgs.callPackage ./bluesky { inherit craneLib; };
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

  # Create aliases for backward compatibility
  backwardCompatibilityAliases = {
    # Individual package aliases (old names -> new organizational names)
    leaflet = flattenedPackages.hyperlink-academy-leaflet or null;
    slices = flattenedPackages.slices-network-slices or null;
    teal = flattenedPackages.teal-fm-teal or null;
    parakeet = flattenedPackages.parakeet-social-parakeet or null;
    streamplace = flattenedPackages.stream-place-streamplace or null;
    yoten = flattenedPackages.yoten-app-yoten or null;
    red-dwarf = flattenedPackages.red-dwarf-client-red-dwarf or null;
    quickdid = flattenedPackages.smokesignal-events-quickdid or null;
    allegedly = flattenedPackages.microcosm-blue-allegedly or null;
    pds-dash = flattenedPackages.witchcraft-systems-pds-dash or null;
    atbackup = flattenedPackages.atbackup-pages-dev-atbackup or null;
    indigo = flattenedPackages.bluesky-social-indigo or null;
    grain = flattenedPackages.bluesky-social-grain or null;
    pds-gatekeeper = flattenedPackages.individual-pds-gatekeeper or null;
    
    # Tangled-dev packages
    appview = flattenedPackages.tangled-dev-appview or null;
    knot = flattenedPackages.tangled-dev-knot or null;
    spindle = flattenedPackages.tangled-dev-spindle or null;
    genjwks = flattenedPackages.tangled-dev-genjwks or null;
    lexgen = flattenedPackages.tangled-dev-lexgen or null;
  };

  # Filter out null aliases
  validAliases = lib.filterAttrs (n: v: v != null) backwardCompatibilityAliases;

in
flattenedPackages // validAliases // {
  # Export organizational collections for direct access (not in flake packages)
  organizations = organizationalPackages;
  
  # Export organizational metadata for tooling (not in flake packages)
  _organizationalMetadata = lib.mapAttrs (orgName: packages: 
    packages._organizationMeta or null
  ) (lib.filterAttrs (n: v: n != "microcosm" && n != "blacksky" && n != "bluesky") organizationalPackages);
}