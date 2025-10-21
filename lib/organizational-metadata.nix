{ lib }:

let
  # Organizational metadata schema for ATProto packages
  
  # Base organizational metadata schema
  organizationalMetadataSchema = lib.types.submodule {
    options = {
      # Organization identification
      name = lib.mkOption {
        type = lib.types.str;
        description = "Kebab-case organization identifier (e.g., 'hyperlink-academy')";
        example = "hyperlink-academy";
      };
      
      displayName = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable organization name";
        example = "Hyperlink Academy";
      };
      
      # Contact and web presence
      website = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Organization website URL";
        example = "https://hyperlink.academy";
      };
      
      contact = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Contact information (email, social media, etc.)";
        example = "contact@leaflet.pub";
      };
      
      # Maintainer information
      maintainer = lib.mkOption {
        type = lib.types.str;
        description = "Primary maintainer name or organization";
        example = "Learning Futures Inc.";
      };
      
      # Repository information
      repository = lib.mkOption {
        type = lib.types.str;
        description = "Primary source repository URL";
        example = "https://github.com/hyperlink-academy/leaflet";
      };
      
      # Additional metadata
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Brief description of the organization's ATProto involvement";
        example = "Educational technology company building collaborative learning tools on ATProto";
      };
      
      # Package-specific metadata
      packageCount = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of packages maintained by this organization";
      };
      
      # ATProto-specific metadata
      atprotoFocus = lib.mkOption {
        type = lib.types.listOf (lib.types.enum [ 
          "applications" "infrastructure" "tools" "libraries" 
          "clients" "servers" "identity" "federation" 
        ]);
        default = [ "applications" ];
        description = "Areas of ATProto ecosystem focus";
        example = [ "applications" "tools" ];
      };
    };
  };

  # Package organizational metadata schema
  packageOrganizationalSchema = lib.types.submodule {
    options = {
      # Core organizational info (embedded from organization)
      organization = organizationalMetadataSchema;
      
      # Package placement information
      placement = lib.mkOption {
        type = lib.types.submodule {
          options = {
            currentPath = lib.mkOption {
              type = lib.types.str;
              description = "Current package path in repository";
              example = "pkgs/atproto/leaflet";
            };
            
            correctPath = lib.mkOption {
              type = lib.types.str;
              description = "Correct organizational path for package";
              example = "pkgs/hyperlink-academy/leaflet";
            };
            
            needsMigration = lib.mkOption {
              type = lib.types.bool;
              description = "Whether package needs to be moved to correct location";
            };
            
            migrationPriority = lib.mkOption {
              type = lib.types.enum [ "high" "medium" "low" ];
              default = "medium";
              description = "Priority level for migration";
            };
          };
        };
        description = "Package placement and migration information";
      };
      
      # Implementation status
      status = lib.mkOption {
        type = lib.types.enum [ "implemented" "planned" "placeholder" ];
        description = "Current implementation status of the package";
      };
      
      # Dependencies and relationships
      relationships = lib.mkOption {
        type = lib.types.submodule {
          options = {
            dependsOn = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Other ATProto packages this package depends on";
              example = [ "constellation" "microcosm-spacedust" ];
            };
            
            relatedPackages = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Related packages from the same organization";
              example = [ "tangled-knot" "tangled-spindle" ];
            };
            
            compatibleWith = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Other ATProto implementations this is compatible with";
              example = [ "bluesky-pds" "rsky-pds" ];
            };
          };
        };
        default = {};
        description = "Package relationships and dependencies";
      };
    };
  };

  # Helper functions for generating organizational metadata
  
  # Generate organization metadata from mapping
  generateOrganizationMetadata = orgName: packages:
    let
      firstPackage = lib.head packages;
      packageNames = lib.map (pkg: lib.last (lib.splitString "/" pkg.newPath)) packages;
      
      # Determine ATProto focus areas based on package types
      focusAreas = lib.unique (lib.flatten (lib.map (pkg:
        if lib.hasInfix "pds" (lib.toLower pkg.repository) then [ "infrastructure" "servers" ]
        else if lib.hasInfix "client" (lib.toLower pkg.repository) then [ "applications" "clients" ]
        else if lib.hasInfix "tool" (lib.toLower pkg.repository) then [ "tools" ]
        else if lib.hasInfix "lib" (lib.toLower pkg.repository) then [ "libraries" ]
        else [ "applications" ]
      ) packages));
    in
    {
      name = orgName;
      displayName = firstPackage.displayName;
      website = firstPackage.website;
      contact = firstPackage.contact;
      maintainer = firstPackage.maintainer;
      repository = firstPackage.repository;
      packageCount = lib.length packages;
      atprotoFocus = focusAreas;
      description = null; # To be filled in manually
    };

  # Generate package metadata with organizational context
  generatePackageMetadata = packageName: packageInfo:
    let
      needsMigration = packageInfo.currentPath != packageInfo.newPath;
      
      # Determine migration priority based on package status and type
      migrationPriority = 
        if packageInfo.status == "implemented" then "high"
        else if packageInfo.status == "placeholder" then "medium"
        else "low";
    in
    {
      organization = {
        name = packageInfo.organization;
        displayName = packageInfo.displayName;
        website = packageInfo.website;
        contact = packageInfo.contact;
        maintainer = packageInfo.maintainer;
        repository = packageInfo.repository;
        packageCount = 1; # Will be updated when grouping by organization
        atprotoFocus = [ "applications" ]; # Default, to be refined
      };
      
      placement = {
        currentPath = packageInfo.currentPath;
        correctPath = packageInfo.newPath;
        inherit needsMigration migrationPriority;
      };
      
      status = packageInfo.status;
      
      relationships = {
        dependsOn = [];
        relatedPackages = [];
        compatibleWith = [];
      };
    };

  # Enhance package definition with organizational metadata
  enhancePackageWithMetadata = packageDef: organizationalMetadata:
    packageDef // {
      passthru = (packageDef.passthru or {}) // {
        organizational = organizationalMetadata;
        
        # Enhanced ATProto metadata
        atproto = (packageDef.passthru.atproto or {}) // {
          organization = organizationalMetadata.organization;
          placement = organizationalMetadata.placement;
          relationships = organizationalMetadata.relationships;
        };
      };
      
      # Enhanced meta information
      meta = (packageDef.meta or {}) // {
        # Add organizational context to description
        longDescription = (packageDef.meta.longDescription or packageDef.meta.description or "") + 
          "\n\nMaintained by ${organizationalMetadata.organization.displayName}" +
          lib.optionalString (organizationalMetadata.organization.website != null) 
            " (${organizationalMetadata.organization.website})";
        
        # Add organizational homepage if package doesn't have one
        homepage = packageDef.meta.homepage or organizationalMetadata.organization.website;
        
        # Add organizational context
        organizationalContext = {
          organization = organizationalMetadata.organization.name;
          displayName = organizationalMetadata.organization.displayName;
          needsMigration = organizationalMetadata.placement.needsMigration;
          migrationPriority = organizationalMetadata.placement.migrationPriority;
        };
      };
    };

  # Validate organizational metadata against schema
  validateOrganizationalMetadata = metadata:
    let
      # Basic validation - check required fields
      requiredOrgFields = [ "name" "displayName" "maintainer" "repository" ];
      missingOrgFields = lib.filter (field: !(lib.hasAttr field metadata.organization)) requiredOrgFields;
      
      requiredPlacementFields = [ "currentPath" "correctPath" "needsMigration" ];
      missingPlacementFields = lib.filter (field: !(lib.hasAttr field metadata.placement)) requiredPlacementFields;
      
      # Validate organization name format
      validOrgName = lib.match "^[a-z0-9]+(-[a-z0-9]+)*$" metadata.organization.name != null;
      
      # Validate paths
      validCurrentPath = lib.hasPrefix "pkgs/" metadata.placement.currentPath;
      validCorrectPath = lib.hasPrefix "pkgs/" metadata.placement.correctPath &&
                        lib.hasInfix ("/" + metadata.organization.name + "/") metadata.placement.correctPath;
      
      # Validate status
      validStatus = lib.elem metadata.status [ "implemented" "planned" "placeholder" ];
      
      errors = []
        ++ lib.map (field: "Missing organization field: ${field}") missingOrgFields
        ++ lib.map (field: "Missing placement field: ${field}") missingPlacementFields
        ++ lib.optional (!validOrgName) "Invalid organization name format: ${metadata.organization.name}"
        ++ lib.optional (!validCurrentPath) "Invalid current path: ${metadata.placement.currentPath}"
        ++ lib.optional (!validCorrectPath) "Invalid correct path: ${metadata.placement.correctPath}"
        ++ lib.optional (!validStatus) "Invalid status: ${metadata.status}";
    in
    {
      valid = errors == [];
      errors = errors;
      metadata = metadata;
    };

  # Generate organizational directory structure
  generateOrganizationalStructure = organizationalMapping:
    let
      organizations = lib.unique (lib.mapAttrsToList (_: pkg: pkg.organization) organizationalMapping);
      packagesByOrg = lib.groupBy (pkg: pkg.organization) (lib.attrValues organizationalMapping);
      
      orgStructure = lib.listToAttrs (lib.map (orgName:
        let
          orgPackages = packagesByOrg.${orgName};
          orgMetadata = generateOrganizationMetadata orgName orgPackages;
        in
        {
          name = orgName;
          value = {
            metadata = orgMetadata;
            packages = lib.map (pkg: {
              name = lib.last (lib.splitString "/" pkg.newPath);
              path = pkg.newPath;
              status = pkg.status;
              needsMigration = pkg.currentPath != pkg.newPath;
            }) orgPackages;
            directoryPath = "pkgs/${orgName}";
            defaultNixPath = "pkgs/${orgName}/default.nix";
          };
        }
      ) organizations);
    in
    {
      organizations = orgStructure;
      totalOrganizations = lib.length organizations;
      totalPackages = lib.length (lib.attrNames organizationalMapping);
      
      # Summary statistics
      packagesToMigrate = lib.length (lib.filter (pkg: pkg.currentPath != pkg.newPath) (lib.attrValues organizationalMapping));
      implementedPackages = lib.length (lib.filter (pkg: pkg.status == "implemented") (lib.attrValues organizationalMapping));
      plannedPackages = lib.length (lib.filter (pkg: pkg.status == "planned") (lib.attrValues organizationalMapping));
      placeholderPackages = lib.length (lib.filter (pkg: pkg.status == "placeholder") (lib.attrValues organizationalMapping));
    };

in
{
  inherit organizationalMetadataSchema packageOrganizationalSchema;
  inherit generateOrganizationMetadata generatePackageMetadata enhancePackageWithMetadata;
  inherit validateOrganizationalMetadata generateOrganizationalStructure;
  
  # Schema types for external use
  schemas = {
    organizational = organizationalMetadataSchema;
    package = packageOrganizationalSchema;
  };
  
  # Utility functions
  createOrganizationalMetadata = orgName: packages: generateOrganizationMetadata orgName packages;
  createPackageMetadata = packageName: packageInfo: generatePackageMetadata packageName packageInfo;
  enhancePackage = packageDef: metadata: enhancePackageWithMetadata packageDef metadata;
  validateMetadata = metadata: validateOrganizationalMetadata metadata;
}