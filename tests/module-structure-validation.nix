{ pkgs }:

let
  lib = pkgs.lib;
  
  # Get the root directory (parent of tests/)
  rootDir = ../.;
  
  # Test that modules can be imported and have correct structure
  testModuleImport = modulePath: moduleName:
    let
      module = import modulePath { config = {}; lib = lib; pkgs = pkgs; };
      hasOptions = module ? options;
      hasConfig = module ? config;
      hasImports = module ? imports;
    in
    {
      name = "Module import test for ${moduleName}";
      modulePath = modulePath;
      result = hasOptions || hasConfig || hasImports;
      expected = true;
      details = "Module structure: options=${lib.boolToString hasOptions}, config=${lib.boolToString hasConfig}, imports=${lib.boolToString hasImports}";
    };
  
  # Test that organizational modules exist and can be imported
  organizationalModules = [
    { path = "${rootDir}/modules/hyperlink-academy/leaflet.nix"; name = "hyperlink-academy-leaflet"; }
    { path = "${rootDir}/modules/slices-network/slices.nix"; name = "slices-network-slices"; }
    { path = "${rootDir}/modules/teal-fm/teal.nix"; name = "teal-fm-teal"; }
    { path = "${rootDir}/modules/parakeet-social/parakeet.nix"; name = "parakeet-social-parakeet"; }
    { path = "${rootDir}/modules/smokesignal-events/quickdid.nix"; name = "smokesignal-events-quickdid"; }
    { path = "${rootDir}/modules/tangled-dev/tangled-appview.nix"; name = "tangled-dev-appview"; }
    { path = "${rootDir}/modules/tangled-dev/tangled-knot.nix"; name = "tangled-dev-knot"; }
    { path = "${rootDir}/modules/tangled-dev/tangled-spindle.nix"; name = "tangled-dev-spindle"; }
    { path = "${rootDir}/modules/atbackup-pages-dev/atbackup.nix"; name = "atbackup-pages-dev-atbackup"; }
    { path = "${rootDir}/modules/individual/pds-gatekeeper.nix"; name = "individual-pds-gatekeeper"; }
    { path = "${rootDir}/modules/witchcraft-systems/pds-dash.nix"; name = "witchcraft-systems-pds-dash"; }
    { path = "${rootDir}/modules/bluesky-social/frontpage.nix"; name = "bluesky-social-frontpage"; }
  ];
  
  # Test that compatibility module can be imported
  compatibilityModuleTest = testModuleImport "${rootDir}/modules/compatibility.nix" "compatibility";
  
  # Test all organizational modules
  moduleTests = map (mod: testModuleImport mod.path mod.name) organizationalModules;
  
  # Test that package references work in modules
  testPackageReference = modulePath: packageName:
    let
      # Try to evaluate the module with a mock configuration
      mockConfig = {
        services = {};
      };
      
      # Import the module and check if it references the expected package
      module = import modulePath { config = mockConfig; lib = lib; pkgs = pkgs; };
      
      # Check if the module has options that reference packages
      # This is a recursive function to check nested service options
      hasPackageInServices = services:
        if lib.isAttrs services then
          lib.any (serviceName:
            let 
              service = services.${serviceName};
            in
            if lib.isAttrs service then
              (service ? package) || (hasPackageInServices service)
            else false
          ) (lib.attrNames services)
        else false;
      
      hasPackageOption = module.options or {} ? services && 
        hasPackageInServices (module.options.services or {});
    in
    {
      name = "Package reference test for ${packageName}";
      result = hasPackageOption;
      expected = true;
      details = "Module has package option: ${lib.boolToString hasPackageOption}";
    };
  
  # Test package references for key modules
  packageReferenceTests = [
    (testPackageReference "${rootDir}/modules/hyperlink-academy/leaflet.nix" "hyperlink-academy-leaflet")
    (testPackageReference "${rootDir}/modules/smokesignal-events/quickdid.nix" "smokesignal-events-quickdid")
    (testPackageReference "${rootDir}/modules/individual/pds-gatekeeper.nix" "individual-pds-gatekeeper")
  ];
  
  # Test that organizational default.nix files exist and work
  testOrganizationalDefault = orgPath: orgName:
    let
      defaultFile = "${orgPath}/default.nix";
      # Try to import the default file
      orgModule = import defaultFile { };
      hasImports = orgModule ? imports;
    in
    {
      name = "Organizational default.nix test for ${orgName}";
      result = hasImports;
      expected = true;
      details = "Organization module has imports: ${lib.boolToString hasImports}";
    };
  
  # Test organizational default files
  organizationalDefaultTests = [
    (testOrganizationalDefault "${rootDir}/modules/hyperlink-academy" "hyperlink-academy")
    (testOrganizationalDefault "${rootDir}/modules/slices-network" "slices-network")
    (testOrganizationalDefault "${rootDir}/modules/teal-fm" "teal-fm")
    (testOrganizationalDefault "${rootDir}/modules/tangled-dev" "tangled-dev")
  ];
  
  # Combine all tests
  allTests = moduleTests ++ packageReferenceTests ++ organizationalDefaultTests ++ [ compatibilityModuleTest ];
  
  # Test runner
  testResults = map (test: 
    test // { 
      passed = test.result == test.expected;
      status = if test.result == test.expected then "PASS" else "FAIL";
    }
  ) allTests;
  
  # Summary
  totalTests = lib.length testResults;
  passedTests = lib.length (lib.filter (test: test.passed) testResults);
  failedTests = totalTests - passedTests;
  
  testSummary = {
    total = totalTests;
    passed = passedTests;
    failed = failedTests;
    success = failedTests == 0;
    results = testResults;
  };

in
pkgs.runCommand "module-structure-validation-test" {} ''
  echo "=== Module Structure Validation Tests ==="
  echo "Total tests: ${toString testSummary.total}"
  echo "Passed: ${toString testSummary.passed}"
  echo "Failed: ${toString testSummary.failed}"
  echo ""
  
  ${lib.concatStringsSep "\n" (map (test: ''
    echo "[${test.status}] ${test.name}"
    echo "  Expected: ${lib.boolToString test.expected}, Got: ${lib.boolToString test.result}"
    echo "  Details: ${test.details}"
    echo ""
  '') testResults)}
  
  ${if testSummary.success then ''
    echo "✅ All module structure tests passed!"
    touch $out
  '' else ''
    echo "❌ Some module structure tests failed!"
    exit 1
  ''}
''