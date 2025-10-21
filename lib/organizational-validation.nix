{ lib, organizationalMapping }:

let
  # Import the organizational mapping
  orgMapping = organizationalMapping;

  # Validation functions for organizational placement
  
  # Check if a package is in the correct organizational directory
  validatePackageLocation = packageName: actualPath:
    let
      expectedMapping = orgMapping.organizationalMapping.${packageName} or null;
    in
    if expectedMapping == null then
      { 
        valid = false; 
        error = "Package '${packageName}' not found in organizational mapping";
        suggestion = "Add package to organizational mapping configuration";
      }
    else if actualPath == expectedMapping.newPath then
      { 
        valid = true; 
        message = "Package '${packageName}' is correctly placed in ${actualPath}";
      }
    else if actualPath == expectedMapping.currentPath then
      { 
        valid = false; 
        error = "Package '${packageName}' is in legacy location ${actualPath}";
        suggestion = "Move to organizational location: ${expectedMapping.newPath}";
        migration = {
          from = actualPath;
          to = expectedMapping.newPath;
          organization = expectedMapping.organization;
        };
      }
    else
      { 
        valid = false; 
        error = "Package '${packageName}' is in unexpected location ${actualPath}";
        suggestion = "Move to correct organizational location: ${expectedMapping.newPath}";
        migration = {
          from = actualPath;
          to = expectedMapping.newPath;
          organization = expectedMapping.organization;
        };
      };

  # Validate that all packages in a directory belong to the same organization
  validateDirectoryOrganization = directoryPath: packageList:
    let
      # Extract organization from directory path (e.g., "pkgs/hyperlink-academy/leaflet" -> "hyperlink-academy")
      pathParts = lib.splitString "/" directoryPath;
      expectedOrg = if lib.length pathParts >= 2 && lib.head pathParts == "pkgs" 
                   then lib.elemAt pathParts 1 
                   else null;
      
      # Check each package's organizational mapping
      packageValidations = lib.map (packageName:
        let
          mapping = orgMapping.organizationalMapping.${packageName} or null;
        in
        if mapping == null then
          { 
            package = packageName; 
            valid = false; 
            error = "Package not in organizational mapping"; 
          }
        else if mapping.organization == expectedOrg then
          { 
            package = packageName; 
            valid = true; 
            organization = mapping.organization;
          }
        else
          { 
            package = packageName; 
            valid = false; 
            error = "Package belongs to '${mapping.organization}' but is in '${expectedOrg}' directory";
            correctOrganization = mapping.organization;
          }
      ) packageList;
      
      invalidPackages = lib.filter (result: !result.valid) packageValidations;
    in
    {
      directoryPath = directoryPath;
      expectedOrganization = expectedOrg;
      totalPackages = lib.length packageList;
      validPackages = lib.length packageList - lib.length invalidPackages;
      valid = invalidPackages == [];
      invalidPackages = invalidPackages;
    };

  # Check for organizational naming consistency
  validateOrganizationalNaming = organization:
    let
      orgInfo = orgMapping.getOrganizationInfo organization;
      orgPackages = orgMapping.packagesByOrganization.${organization} or [];
      
      # Check naming conventions
      validOrgName = lib.match "^[a-z0-9]+(-[a-z0-9]+)*$" organization != null;
      
      # Check that all packages use consistent organization reference
      packageConsistency = lib.all (pkg: pkg.organization == organization) orgPackages;
      
      # Check for display name consistency
      displayNames = lib.unique (lib.map (pkg: pkg.displayName) orgPackages);
      consistentDisplayName = lib.length displayNames <= 1;
      
      errors = []
        ++ lib.optional (!validOrgName) "Organization name '${organization}' is not in kebab-case format"
        ++ lib.optional (!packageConsistency) "Packages in organization have inconsistent organization references"
        ++ lib.optional (!consistentDisplayName) "Packages in organization have inconsistent display names: ${lib.concatStringsSep ", " displayNames}";
    in
    {
      organization = organization;
      valid = errors == [];
      errors = errors;
      packageCount = lib.length orgPackages;
      displayName = if orgInfo != null then orgInfo.displayName else null;
    };

  # Validate package metadata schema compliance
  validatePackageMetadata = packageName: packageMetadata:
    let
      requiredFields = [ "organization" "displayName" "currentPath" "newPath" "repository" "maintainer" "status" ];
      optionalFields = [ "website" "contact" ];
      allValidFields = requiredFields ++ optionalFields;
      
      # Check for required fields
      missingRequired = lib.filter (field: !(lib.hasAttr field packageMetadata)) requiredFields;
      
      # Check for unknown fields
      unknownFields = lib.filter (field: !(lib.elem field allValidFields)) (lib.attrNames packageMetadata);
      
      # Validate field values
      fieldValidations = {
        organization = if lib.hasAttr "organization" packageMetadata 
                      then lib.match "^[a-z0-9]+(-[a-z0-9]+)*$" packageMetadata.organization != null
                      else false;
        
        status = if lib.hasAttr "status" packageMetadata
                then lib.elem packageMetadata.status [ "implemented" "planned" "placeholder" ]
                else false;
        
        currentPath = if lib.hasAttr "currentPath" packageMetadata
                     then lib.hasPrefix "pkgs/" packageMetadata.currentPath
                     else false;
        
        newPath = if lib.hasAttr "newPath" packageMetadata
                 then lib.hasPrefix "pkgs/" packageMetadata.newPath && 
                      lib.hasInfix ("/" + packageMetadata.organization + "/") packageMetadata.newPath
                 else false;
      };
      
      fieldErrors = lib.mapAttrsToList (field: valid: 
        if !valid then "Invalid ${field} field" else null
      ) fieldValidations;
      
      validFieldErrors = lib.filter (error: error != null) fieldErrors;
      
      allErrors = []
        ++ lib.map (field: "Missing required field: ${field}") missingRequired
        ++ lib.map (field: "Unknown field: ${field}") unknownFields
        ++ validFieldErrors;
    in
    {
      package = packageName;
      valid = allErrors == [];
      errors = allErrors;
      metadata = packageMetadata;
    };

  # Comprehensive validation of the entire organizational structure
  validateOrganizationalStructure = 
    let
      # Validate all package mappings
      mappingValidation = orgMapping.validateAllMappings;
      
      # Validate each organization
      organizationValidations = lib.map validateOrganizationalNaming orgMapping.organizations;
      invalidOrganizations = lib.filter (result: !result.valid) organizationValidations;
      
      # Check for duplicate package names across organizations
      allPackageNames = lib.attrNames orgMapping.organizationalMapping;
      duplicateCheck = lib.length allPackageNames == lib.length (lib.unique allPackageNames);
      
      # Validate metadata schema for all packages
      metadataValidations = lib.mapAttrs validatePackageMetadata orgMapping.organizationalMapping;
      invalidMetadata = lib.filterAttrs (_: result: !result.valid) metadataValidations;
      
      overallValid = mappingValidation.valid && 
                    invalidOrganizations == [] && 
                    duplicateCheck && 
                    invalidMetadata == {};
    in
    {
      valid = overallValid;
      summary = {
        totalPackages = mappingValidation.totalPackages;
        validPackages = mappingValidation.validPackages;
        totalOrganizations = lib.length orgMapping.organizations;
        validOrganizations = lib.length orgMapping.organizations - lib.length invalidOrganizations;
      };
      
      # Detailed validation results
      mappingValidation = mappingValidation;
      organizationValidations = organizationValidations;
      invalidOrganizations = invalidOrganizations;
      duplicatePackageNames = !duplicateCheck;
      metadataValidations = metadataValidations;
      invalidMetadata = invalidMetadata;
      
      # Migration information
      migrationPlan = orgMapping.getMigrationPlan;
    };

  # Generate validation report
  generateValidationReport = 
    let
      structureValidation = validateOrganizationalStructure;
    in
    {
      timestamp = "Generated by organizational validation framework";
      
      summary = structureValidation.summary // {
        overallValid = structureValidation.valid;
      };
      
      issues = []
        ++ lib.optional (!structureValidation.mappingValidation.valid) {
          type = "mapping";
          severity = "error";
          message = "Package mapping validation failed";
          details = structureValidation.mappingValidation.invalidPackages;
        }
        ++ lib.optional (structureValidation.invalidOrganizations != []) {
          type = "organization";
          severity = "error"; 
          message = "Organization validation failed";
          details = structureValidation.invalidOrganizations;
        }
        ++ lib.optional (structureValidation.duplicatePackageNames) {
          type = "naming";
          severity = "error";
          message = "Duplicate package names found across organizations";
        }
        ++ lib.optional (structureValidation.invalidMetadata != {}) {
          type = "metadata";
          severity = "error";
          message = "Package metadata validation failed";
          details = structureValidation.invalidMetadata;
        };
      
      migrationPlan = structureValidation.migrationPlan;
      
      recommendations = []
        ++ lib.optional (lib.length (lib.attrNames structureValidation.migrationPlan.packagesToMove) > 0) 
           "Move ${toString (lib.length (lib.attrNames structureValidation.migrationPlan.packagesToMove))} packages to their correct organizational directories"
        ++ lib.optional (lib.length (lib.attrNames structureValidation.migrationPlan.plannedPackages) > 0)
           "Implement ${toString (lib.length (lib.attrNames structureValidation.migrationPlan.plannedPackages))} planned packages"
        ++ lib.optional (lib.length (lib.attrNames structureValidation.migrationPlan.placeholderPackages) > 0)
           "Replace ${toString (lib.length (lib.attrNames structureValidation.migrationPlan.placeholderPackages))} placeholder packages with real implementations";
    };

in
{
  inherit validatePackageLocation validateDirectoryOrganization validateOrganizationalNaming;
  inherit validatePackageMetadata validateOrganizationalStructure generateValidationReport;
  
  # Utility functions
  checkPackagePlacement = packageName: validatePackageLocation packageName;
  validateDirectory = directoryPath: packageList: validateDirectoryOrganization directoryPath packageList;
  validateOrganization = organization: validateOrganizationalNaming organization;
  
  # Quick validation functions
  isPackageCorrectlyPlaced = packageName: actualPath: 
    (validatePackageLocation packageName actualPath).valid;
    
  getPackageMigrationInfo = packageName:
    let
      mapping = orgMapping.organizationalMapping.${packageName} or null;
    in
    if mapping == null then null
    else {
      package = packageName;
      from = mapping.currentPath;
      to = mapping.newPath;
      organization = mapping.organization;
      needsMigration = mapping.currentPath != mapping.newPath;
    };
}