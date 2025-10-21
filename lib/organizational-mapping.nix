{ lib }:

let
  # Organizational mapping configuration that defines correct ownership for each package
  organizationalMapping = {
    # Hyperlink Academy (Learning Futures Inc.)
    "leaflet" = {
      organization = "hyperlink-academy";
      displayName = "Hyperlink Academy";
      currentPath = "pkgs/atproto/leaflet";
      newPath = "pkgs/hyperlink-academy/leaflet";
      repository = "https://github.com/hyperlink-academy/leaflet";
      maintainer = "Learning Futures Inc.";
      website = "https://hyperlink.academy";
      contact = "contact@leaflet.pub";
      status = "planned"; # Not yet implemented
    };

    # Slices Network
    "slices" = {
      organization = "slices-network";
      displayName = "Slices Network";
      currentPath = "pkgs/atproto/slices";
      newPath = "pkgs/slices-network/slices";
      repository = "https://tangled.sh/slices.network/slices";
      maintainer = "Slices Network";
      website = "https://slices.network";
      contact = null;
      status = "planned"; # Not yet implemented
    };

    # Teal.fm
    "teal" = {
      organization = "teal-fm";
      displayName = "Teal.fm";
      currentPath = "pkgs/atproto/teal";
      newPath = "pkgs/teal-fm/teal";
      repository = "https://github.com/teal-fm/teal";
      maintainer = "Teal.fm";
      website = "https://teal.fm";
      contact = null;
      status = "planned"; # Not yet implemented
    };

    # Parakeet Social
    "parakeet" = {
      organization = "parakeet-social";
      displayName = "Parakeet Social";
      currentPath = "pkgs/atproto/parakeet";
      newPath = "pkgs/parakeet-social/parakeet";
      repository = "https://github.com/parakeet-social/parakeet";
      maintainer = "Parakeet Social";
      website = null;
      contact = null;
      status = "planned"; # Not yet implemented
    };

    # Stream.place
    "streamplace" = {
      organization = "stream-place";
      displayName = "Stream.place";
      currentPath = "pkgs/atproto/streamplace";
      newPath = "pkgs/stream-place/streamplace";
      repository = "https://tangled.org/@stream.place/streamplace";
      maintainer = "Stream.place";
      website = "https://stream.place";
      contact = null;
      status = "implemented"; # Currently in atproto
    };

    # Yoten App
    "yoten" = {
      organization = "yoten-app";
      displayName = "Yoten App";
      currentPath = "pkgs/atproto/yoten";
      newPath = "pkgs/yoten-app/yoten";
      repository = "https://tangled.org/@yoten.app/yoten";
      maintainer = "Yoten App";
      website = "https://yoten.app";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    # Red Dwarf Client
    "red-dwarf" = {
      organization = "red-dwarf-client";
      displayName = "Red Dwarf Client";
      currentPath = "pkgs/atproto/red-dwarf";
      newPath = "pkgs/red-dwarf-client/red-dwarf";
      repository = "https://tangled.org/@whey.party/red-dwarf";
      maintainer = "Red Dwarf Client";
      website = null;
      contact = null;
      status = "implemented"; # Currently in atproto
    };

    # Tangled Development - Multiple packages
    "appview" = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      currentPath = "pkgs/atproto/appview";
      newPath = "pkgs/tangled-dev/appview";
      repository = "https://github.com/tangled-dev/tangled-core";
      maintainer = "Tangled Development";
      website = "https://tangled.dev";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    "knot" = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      currentPath = "pkgs/atproto/knot";
      newPath = "pkgs/tangled-dev/knot";
      repository = "https://github.com/tangled-dev/tangled-core";
      maintainer = "Tangled Development";
      website = "https://tangled.dev";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    "spindle" = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      currentPath = "pkgs/atproto/spindle";
      newPath = "pkgs/tangled-dev/spindle";
      repository = "https://github.com/tangled-dev/tangled-core";
      maintainer = "Tangled Development";
      website = "https://tangled.dev";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    "genjwks" = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      currentPath = "pkgs/atproto/genjwks";
      newPath = "pkgs/tangled-dev/genjwks";
      repository = "https://github.com/tangled-dev/tangled-core";
      maintainer = "Tangled Development";
      website = "https://tangled.dev";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    "lexgen" = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      currentPath = "pkgs/atproto/lexgen";
      newPath = "pkgs/tangled-dev/lexgen";
      repository = "https://github.com/tangled-dev/tangled-core";
      maintainer = "Tangled Development";
      website = "https://tangled.dev";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    # Smokesignal Events
    "quickdid" = {
      organization = "smokesignal-events";
      displayName = "Smokesignal Events";
      currentPath = "pkgs/atproto/quickdid";
      newPath = "pkgs/smokesignal-events/quickdid";
      repository = "https://tangled.org/@smokesignal.events/quickdid";
      maintainer = "Smokesignal Events";
      website = null;
      contact = null;
      status = "implemented"; # Currently in atproto
    };

    # Microcosm Blue - Move allegedly from atproto
    "allegedly" = {
      organization = "microcosm-blue";
      displayName = "Microcosm";
      currentPath = "pkgs/atproto/allegedly";
      newPath = "pkgs/microcosm-blue/allegedly";
      repository = "https://tangled.org/@microcosm.blue/Allegedly";
      maintainer = "Microcosm";
      website = null;
      contact = null;
      status = "implemented"; # Currently in atproto, should move to microcosm
    };

    # Witchcraft Systems - Move pds-dash from bluesky
    "pds-dash" = {
      organization = "witchcraft-systems";
      displayName = "Witchcraft Systems";
      currentPath = "pkgs/bluesky/pds-dash";
      newPath = "pkgs/witchcraft-systems/pds-dash";
      repository = "https://github.com/witchcraft-systems/pds-dash";
      maintainer = "Witchcraft Systems";
      website = null;
      contact = null;
      status = "implemented"; # Currently in bluesky
    };

    # ATBackup
    "atbackup" = {
      organization = "atbackup-pages-dev";
      displayName = "ATBackup";
      currentPath = "pkgs/atproto/atbackup";
      newPath = "pkgs/atbackup-pages-dev/atbackup";
      repository = "https://tangled.org/@atbackup.pages.dev/atbackup";
      maintainer = "ATBackup";
      website = "https://atbackup.pages.dev";
      contact = null;
      status = "implemented"; # Currently in atproto (placeholder)
    };

    # Official Bluesky packages - Move indigo and grain from atproto
    "indigo" = {
      organization = "bluesky-social";
      displayName = "Official Bluesky";
      currentPath = "pkgs/atproto/indigo";
      newPath = "pkgs/bluesky-social/indigo";
      repository = "https://github.com/bluesky-social/indigo";
      maintainer = "Bluesky Social";
      website = "https://bsky.social";
      contact = null;
      status = "planned"; # Not yet implemented
    };

    "grain" = {
      organization = "bluesky-social";
      displayName = "Official Bluesky";
      currentPath = "pkgs/atproto/grain";
      newPath = "pkgs/bluesky-social/grain";
      repository = "https://github.com/bluesky-social/grain";
      maintainer = "Bluesky Social";
      website = "https://bsky.social";
      contact = null;
      status = "planned"; # Not yet implemented
    };

    # Individual developers - Fallback category
    "pds-gatekeeper" = {
      organization = "individual";
      displayName = "Individual Developers";
      currentPath = "pkgs/bluesky/pds-gatekeeper";
      newPath = "pkgs/individual/pds-gatekeeper";
      repository = "https://github.com/fatfingers23/pds_gatekeeper";
      maintainer = "fatfingers23";
      website = null;
      contact = null;
      status = "implemented"; # Currently in bluesky
    };
  };

  # Organizational metadata schema
  organizationSchema = {
    # Required fields
    organization = lib.types.str; # kebab-case organization identifier
    displayName = lib.types.str; # Human-readable organization name
    currentPath = lib.types.str; # Current package path
    newPath = lib.types.str; # Target organizational path
    repository = lib.types.str; # Source repository URL
    maintainer = lib.types.str; # Organization or individual maintainer
    status = lib.types.enum [ "implemented" "planned" "placeholder" ];
    
    # Optional fields
    website = lib.types.nullOr lib.types.str; # Organization website
    contact = lib.types.nullOr lib.types.str; # Contact information
  };

  # Get all unique organizations
  organizations = lib.unique (lib.mapAttrsToList (_: pkg: pkg.organization) organizationalMapping);

  # Group packages by organization
  packagesByOrganization = lib.groupBy (pkg: pkg.organization) (lib.attrValues organizationalMapping);

  # Validation functions
  validatePackageMapping = packageName: packageInfo:
    let
      requiredFields = [ "organization" "displayName" "currentPath" "newPath" "repository" "maintainer" "status" ];
      missingFields = lib.filter (field: !(lib.hasAttr field packageInfo)) requiredFields;
      
      # Validate organization naming (kebab-case)
      validOrgName = lib.match "^[a-z0-9]+(-[a-z0-9]+)*$" packageInfo.organization != null;
      
      # Validate paths
      validCurrentPath = lib.hasPrefix "pkgs/" packageInfo.currentPath;
      validNewPath = lib.hasPrefix "pkgs/" packageInfo.newPath && 
                     lib.hasInfix ("/" + packageInfo.organization + "/") packageInfo.newPath;
      
      # Validate status
      validStatus = lib.elem packageInfo.status [ "implemented" "planned" "placeholder" ];
      
      errors = []
        ++ lib.optional (missingFields != []) "Missing required fields: ${lib.concatStringsSep ", " missingFields}"
        ++ lib.optional (!validOrgName) "Invalid organization name format (must be kebab-case): ${packageInfo.organization}"
        ++ lib.optional (!validCurrentPath) "Invalid current path (must start with pkgs/): ${packageInfo.currentPath}"
        ++ lib.optional (!validNewPath) "Invalid new path (must be under organization directory): ${packageInfo.newPath}"
        ++ lib.optional (!validStatus) "Invalid status: ${packageInfo.status}";
    in
    if errors == [] then { valid = true; errors = []; }
    else { valid = false; errors = errors; };

  # Validate organizational placement
  validateOrganizationalPlacement = packageName:
    let
      packageInfo = organizationalMapping.${packageName} or null;
    in
    if packageInfo == null then
      { valid = false; errors = [ "Package ${packageName} not found in organizational mapping" ]; }
    else
      validatePackageMapping packageName packageInfo;

  # Get packages that need to be moved
  getPackagesToMove = lib.filterAttrs (_: pkg: pkg.currentPath != pkg.newPath) organizationalMapping;

  # Get packages by status
  getPackagesByStatus = status: lib.filterAttrs (_: pkg: pkg.status == status) organizationalMapping;

  # Generate organizational metadata for a package
  generateOrganizationalMetadata = packageName:
    let
      packageInfo = organizationalMapping.${packageName} or null;
    in
    if packageInfo == null then null
    else {
      organization = {
        name = packageInfo.organization;
        displayName = packageInfo.displayName;
        website = packageInfo.website;
        contact = packageInfo.contact;
        maintainer = packageInfo.maintainer;
        repository = packageInfo.repository;
      };
    };

  # Validate all mappings
  validateAllMappings = 
    let
      validationResults = lib.mapAttrs validatePackageMapping organizationalMapping;
      invalidPackages = lib.filterAttrs (_: result: !result.valid) validationResults;
    in
    {
      valid = invalidPackages == {};
      invalidPackages = invalidPackages;
      totalPackages = lib.length (lib.attrNames organizationalMapping);
      validPackages = lib.length (lib.attrNames organizationalMapping) - lib.length (lib.attrNames invalidPackages);
    };

in
{
  inherit organizationalMapping organizationSchema organizations packagesByOrganization;
  inherit validatePackageMapping validateOrganizationalPlacement validateAllMappings;
  inherit getPackagesToMove getPackagesByStatus generateOrganizationalMetadata;
  
  # Utility functions for organizational structure
  getOrganizationInfo = orgName: 
    let
      orgPackages = packagesByOrganization.${orgName} or [];
      firstPackage = lib.head orgPackages;
    in
    if orgPackages == [] then null
    else {
      name = orgName;
      displayName = firstPackage.displayName;
      website = firstPackage.website;
      contact = firstPackage.contact;
      maintainer = firstPackage.maintainer;
      packageCount = lib.length orgPackages;
      packages = lib.map (pkg: pkg.newPath) orgPackages;
    };
    
  # Get migration plan
  getMigrationPlan = {
    packagesToMove = getPackagesToMove;
    implementedPackages = getPackagesByStatus "implemented";
    plannedPackages = getPackagesByStatus "planned";
    placeholderPackages = getPackagesByStatus "placeholder";
    organizationsToCreate = organizations;
  };
}