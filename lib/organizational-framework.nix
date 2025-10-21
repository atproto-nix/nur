{ lib }:

let
  # Import organizational components
  organizationalMapping = import ./organizational-mapping.nix { inherit lib; };
  organizationalValidation = import ./organizational-validation.nix { 
    inherit lib; 
    inherit organizationalMapping;
  };
  organizationalMetadata = import ./organizational-metadata.nix { inherit lib; };

  # Main organizational framework that provides a unified interface
  
  # Core framework functions
  framework = {
    # Mapping and configuration
    mapping = organizationalMapping;
    
    # Validation functions
    validation = organizationalValidation;
    
    # Metadata schemas and functions
    metadata = organizationalMetadata;
    
    # Unified validation function
    validatePackage = packageName: actualPath:
      let
        locationValidation = organizationalValidation.validatePackageLocation packageName actualPath;
        mappingValidation = organizationalMapping.validateOrganizationalPlacement packageName;
        
        packageInfo = organizationalMapping.organizationalMapping.${packageName} or null;
        metadataValidation = if packageInfo != null 
                           then organizationalMetadata.validateOrganizationalMetadata 
                                  (organizationalMetadata.generatePackageMetadata packageName packageInfo)
                           else { valid = false; errors = [ "Package not found in mapping" ]; };
      in
      {
        package = packageName;
        path = actualPath;
        
        # Individual validation results
        location = locationValidation;
        mapping = mappingValidation;
        metadata = metadataValidation;
        
        # Overall validation
        valid = locationValidation.valid && mappingValidation.valid && metadataValidation.valid;
        
        # Consolidated errors and suggestions
        errors = (locationValidation.error or []) ++ 
                (mappingValidation.errors or []) ++ 
                (metadataValidation.errors or []);
        
        suggestions = lib.filter (s: s != null) [
          (locationValidation.suggestion or null)
          (if mappingValidation.valid then null else "Check organizational mapping configuration")
          (if metadataValidation.valid then null else "Fix metadata schema compliance")
        ];
        
        # Migration information if needed
        migration = locationValidation.migration or null;
      };
    
    # Enhanced package creation function
    createOrganizationalPackage = packageName: packageDef:
      let
        packageInfo = organizationalMapping.organizationalMapping.${packageName} or null;
      in
      if packageInfo == null then
        # Return package as-is if not in organizational mapping
        packageDef // {
          passthru = (packageDef.passthru or {}) // {
            organizational = {
              error = "Package '${packageName}' not found in organizational mapping";
              suggestion = "Add package to organizational mapping configuration";
            };
          };
        }
      else
        let
          metadata = organizationalMetadata.generatePackageMetadata packageName packageInfo;
          enhancedPackage = organizationalMetadata.enhancePackageWithMetadata packageDef metadata;
        in
        enhancedPackage;
    
    # Generate organizational directory structure
    generateDirectoryStructure = 
      organizationalMetadata.generateOrganizationalStructure organizationalMapping.organizationalMapping;
    
    # Get migration plan for all packages
    getMigrationPlan = organizationalMapping.getMigrationPlan;
    
    # Comprehensive validation report
    generateValidationReport = organizationalValidation.generateValidationReport;
    
    # Utility functions for common operations
    utils = {
      # Check if package needs migration
      needsMigration = packageName:
        let
          packageInfo = organizationalMapping.organizationalMapping.${packageName} or null;
        in
        if packageInfo == null then false
        else packageInfo.currentPath != packageInfo.newPath;
      
      # Get organization for package
      getPackageOrganization = packageName:
        let
          packageInfo = organizationalMapping.organizationalMapping.${packageName} or null;
        in
        if packageInfo == null then null
        else packageInfo.organization;
      
      # Get all packages for organization
      getOrganizationPackages = organization:
        lib.filterAttrs (_: pkg: pkg.organization == organization) organizationalMapping.organizationalMapping;
      
      # Get migration info for package
      getMigrationInfo = packageName:
        organizationalValidation.getPackageMigrationInfo packageName;
      
      # Check if organization exists
      organizationExists = organization:
        lib.elem organization organizationalMapping.organizations;
      
      # Get organization metadata
      getOrganizationMetadata = organization:
        organizationalMapping.getOrganizationInfo organization;
      
      # List all organizations
      listOrganizations = organizationalMapping.organizations;
      
      # Get packages by status
      getPackagesByStatus = status:
        organizationalMapping.getPackagesByStatus status;
      
      # Validate organizational structure
      validateStructure = organizationalValidation.validateOrganizationalStructure;
    };
    
    # Configuration and setup helpers
    setup = {
      # Generate default.nix for organization
      generateOrganizationDefaultNix = organization:
        let
          orgPackages = framework.utils.getOrganizationPackages organization;
          packageNames = lib.attrNames orgPackages;
          orgInfo = organizationalMapping.getOrganizationInfo organization;
        in
        ''
          { pkgs, ... }:
          
          # ${orgInfo.displayName or organization} ATProto packages
          # Organization: ${organization}
          ${lib.optionalString (orgInfo.website != null) "# Website: ${orgInfo.website}"}
          ${lib.optionalString (orgInfo.contact != null) "# Contact: ${orgInfo.contact}"}
          
          {
          ${lib.concatStringsSep "\n" (lib.map (packageName:
            let
              pkg = orgPackages.${packageName};
              nixName = lib.last (lib.splitString "/" pkg.newPath);
            in
            "  ${nixName} = pkgs.callPackage ./${nixName}.nix { };"
          ) packageNames)}
          }
        '';
      
      # Generate migration script
      generateMigrationScript = 
        let
          packagesToMove = organizationalMapping.getPackagesToMove;
          migrationCommands = lib.mapAttrsToList (packageName: packageInfo: 
            "# Migrate ${packageName}\n" +
            "mkdir -p $(dirname ${packageInfo.newPath})\n" +
            "mv ${packageInfo.currentPath} ${packageInfo.newPath}\n"
          ) packagesToMove;
        in
        ''
          #!/bin/bash
          # Organizational migration script
          # Generated by ATProto NUR organizational framework
          
          set -e
          
          echo "Starting organizational migration..."
          echo "Packages to migrate: ${toString (lib.length (lib.attrNames packagesToMove))}"
          
          ${lib.concatStringsSep "\n" migrationCommands}
          
          echo "Migration completed successfully!"
          echo "Don't forget to update import statements and references."
        '';
      
      # Generate organizational documentation
      generateOrganizationDocs = organization:
        let
          orgInfo = organizationalMapping.getOrganizationInfo organization;
          orgPackages = framework.utils.getOrganizationPackages organization;
        in
        ''
          # ${orgInfo.displayName or organization}
          
          **Organization:** ${organization}  
          **Maintainer:** ${orgInfo.maintainer or "Unknown"}  
          ${lib.optionalString (orgInfo.website != null) "**Website:** ${orgInfo.website}  "}
          ${lib.optionalString (orgInfo.contact != null) "**Contact:** ${orgInfo.contact}  "}
          
          ## Packages
          
          This organization maintains ${toString orgInfo.packageCount} ATProto package(s):
          
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (packageName: packageInfo: 
            "- **${packageName}**: ${packageInfo.repository}"
          ) orgPackages)}
          
          ## Installation
          
          To use packages from this organization:
          
          ```nix
          # In your flake.nix or configuration
          inputs.atproto-nur.url = "github:your-org/atproto-nur";
          
          # Then reference packages like:
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (packageName: _: 
            "# inputs.atproto-nur.packages.\${system}.${organization}-${packageName}"
          ) orgPackages)}
          ```
          
          ## Development
          
          ${lib.optionalString (orgInfo.repository != null) 
            "Source code: ${orgInfo.repository}"}
          
          For development and contribution guidelines, please refer to the main repository documentation.
        '';
    };
  };

in
{
  inherit framework;
  
  # Export main components for direct access
  inherit organizationalMapping organizationalValidation organizationalMetadata;
  
  # Convenience exports
  mapping = organizationalMapping;
  validation = organizationalValidation;
  metadata = organizationalMetadata;
  utils = framework.utils;
  setup = framework.setup;
  
  # Main functions
  validatePackage = framework.validatePackage;
  createOrganizationalPackage = framework.createOrganizationalPackage;
  generateDirectoryStructure = framework.generateDirectoryStructure;
  getMigrationPlan = framework.getMigrationPlan;
  generateValidationReport = framework.generateValidationReport;
}