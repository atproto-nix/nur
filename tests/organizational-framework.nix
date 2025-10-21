{ lib, pkgs }:

let
  # Import the organizational framework
  organizationalFramework = import ../lib/organizational-framework.nix { inherit lib; };
  
  # Test data
  testPackageName = "allegedly";
  testCurrentPath = "pkgs/atproto/allegedly";
  testExpectedPath = "pkgs/microcosm-blue/allegedly";
  
  # Run tests
  runTests = {
    # Test 1: Validate organizational mapping exists
    testMappingExists = 
      let
        mapping = organizationalFramework.mapping.organizationalMapping.${testPackageName} or null;
      in
      {
        name = "Organizational mapping exists for ${testPackageName}";
        result = mapping != null;
        expected = true;
        details = if mapping != null then "Found mapping: ${mapping.organization}" else "No mapping found";
      };
    
    # Test 2: Validate package location validation
    testLocationValidation =
      let
        validation = organizationalFramework.validation.validatePackageLocation testPackageName testCurrentPath;
      in
      {
        name = "Package location validation for ${testPackageName}";
        result = validation.valid == false && validation.migration != null;
        expected = true;
        details = "Migration needed: ${validation.migration.from or "unknown"} -> ${validation.migration.to or "unknown"}";
      };
    
    # Test 3: Validate organizational structure
    testStructureValidation =
      let
        validation = organizationalFramework.validation.validateOrganizationalStructure;
      in
      {
        name = "Overall organizational structure validation";
        result = validation.valid;
        expected = true;
        details = "Total packages: ${toString validation.summary.totalPackages}, Valid: ${toString validation.summary.validPackages}";
      };
    
    # Test 4: Test migration plan generation
    testMigrationPlan =
      let
        plan = organizationalFramework.getMigrationPlan;
      in
      {
        name = "Migration plan generation";
        result = plan.packagesToMove != {} && plan.organizationsToCreate != [];
        expected = true;
        details = "Packages to move: ${toString (lib.length (lib.attrNames plan.packagesToMove))}, Organizations: ${toString (lib.length plan.organizationsToCreate)}";
      };
    
    # Test 5: Test metadata generation
    testMetadataGeneration =
      let
        metadata = organizationalFramework.metadata.generatePackageMetadata testPackageName 
          (organizationalFramework.mapping.organizationalMapping.${testPackageName});
      in
      {
        name = "Package metadata generation for ${testPackageName}";
        result = metadata.organization.name != null && metadata.placement.needsMigration;
        expected = true;
        details = "Organization: ${metadata.organization.name}, Needs migration: ${lib.boolToString metadata.placement.needsMigration}";
      };
    
    # Test 6: Test validation report generation
    testValidationReport =
      let
        report = organizationalFramework.generateValidationReport;
      in
      {
        name = "Validation report generation";
        result = report.summary != null && report.migrationPlan != null;
        expected = true;
        details = "Report generated with ${toString (lib.length report.issues)} issues";
      };
    
    # Test 7: Test organizational directory structure generation
    testDirectoryStructure =
      let
        structure = organizationalFramework.generateDirectoryStructure;
      in
      {
        name = "Directory structure generation";
        result = structure.organizations != {} && structure.totalOrganizations > 0;
        expected = true;
        details = "Organizations: ${toString structure.totalOrganizations}, Packages: ${toString structure.totalPackages}";
      };
    
    # Test 8: Test utility functions
    testUtilityFunctions =
      let
        needsMigration = organizationalFramework.utils.needsMigration testPackageName;
        organization = organizationalFramework.utils.getPackageOrganization testPackageName;
        migrationInfo = organizationalFramework.utils.getMigrationInfo testPackageName;
      in
      {
        name = "Utility functions";
        result = needsMigration && organization != null && migrationInfo != null;
        expected = true;
        details = "Package ${testPackageName} needs migration: ${lib.boolToString needsMigration}, org: ${organization}";
      };
  };
  
  # Test runner
  testResults = lib.mapAttrs (_: test: 
    test // { 
      passed = test.result == test.expected;
      status = if test.result == test.expected then "PASS" else "FAIL";
    }
  ) runTests;
  
  # Summary
  totalTests = lib.length (lib.attrNames testResults);
  passedTests = lib.length (lib.filter (test: test.passed) (lib.attrValues testResults));
  failedTests = totalTests - passedTests;
  
  testSummary = {
    total = totalTests;
    passed = passedTests;
    failed = failedTests;
    success = failedTests == 0;
    results = testResults;
  };

in
pkgs.runCommand "organizational-framework-test" {} ''
  echo "=== Organizational Framework Tests ==="
  echo "Total tests: ${toString testSummary.total}"
  echo "Passed: ${toString testSummary.passed}"
  echo "Failed: ${toString testSummary.failed}"
  echo ""
  
  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: test: ''
    echo "[${test.status}] ${test.name}"
    echo "  Expected: ${lib.boolToString test.expected}, Got: ${lib.boolToString test.result}"
    echo "  Details: ${test.details}"
    echo ""
  '') testResults)}
  
  ${if testSummary.success then ''
    echo "✅ All tests passed!"
    touch $out
  '' else ''
    echo "❌ Some tests failed!"
    exit 1
  ''}
''