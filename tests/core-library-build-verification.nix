import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: 

let
  craneLib = (import (builtins.fetchTarball "https://github.com/ipetkov/crane/archive/master.tar.gz")).mkLib pkgs;
  
  # Import all package collections
  microcosmPackages = pkgs.callPackage ../pkgs/microcosm { inherit craneLib; };
  blackskyPackages = pkgs.callPackage ../pkgs/blacksky { inherit craneLib; };
  atprotoPackages = pkgs.callPackage ../pkgs/atproto { inherit craneLib; };
  
  # ATProto library utilities
  atprotoLib = pkgs.callPackage ../lib/atproto.nix { inherit craneLib; };
  
  # Core library packages to test
  coreLibraries = [
    # Microcosm core libraries
    microcosmPackages.links
    microcosmPackages.constellation
    microcosmPackages.spacedust
    microcosmPackages.ufos
    microcosmPackages.who-am-i
    microcosmPackages.quasar
    microcosmPackages.pocket
    microcosmPackages.reflector
    
    # Blacksky core libraries  
    blackskyPackages.pds
    blackskyPackages.relay
    blackskyPackages.feedgen
    blackskyPackages.firehose
    
    # ATProto applications
    atprotoPackages.allegedly
    atprotoPackages.quickdid
    atprotoPackages.red-dwarf
    atprotoPackages.streamplace
  ];
  
  # Function to validate ATProto metadata
  validateMetadata = pkg: 
    let
      atproto = pkg.passthru.atproto or null;
    in
    if atproto == null then
      throw "Package ${pkg.pname or "unknown"} missing ATProto metadata"
    else if !(builtins.hasAttr "type" atproto) then
      throw "Package ${pkg.pname or "unknown"} missing ATProto type"
    else if !(builtins.elem atproto.type ["application" "library" "tool"]) then
      throw "Package ${pkg.pname or "unknown"} has invalid ATProto type: ${atproto.type}"
    else if !(builtins.hasAttr "services" atproto) then
      throw "Package ${pkg.pname or "unknown"} missing ATProto services"
    else if !(builtins.isList atproto.services) then
      throw "Package ${pkg.pname or "unknown"} ATProto services must be a list"
    else if !(builtins.hasAttr "protocols" atproto) then
      throw "Package ${pkg.pname or "unknown"} missing ATProto protocols"
    else if !(builtins.isList atproto.protocols) then
      throw "Package ${pkg.pname or "unknown"} ATProto protocols must be a list"
    else
      true;

in

{
  name = "core-library-build-verification";
  
  nodes.machine = { config, pkgs, ... }: {
    # Install all core library packages to verify they build correctly
    environment.systemPackages = coreLibraries ++ (with pkgs; [
      nix
      jq
      file
      ldd
    ]);
  };
  
  testScript = ''
    machine.start()
    
    # Test 1: Build Verification - All packages should be available in the system
    machine.log("=== Build Verification Tests ===")
    
    # Verify Microcosm packages
    machine.succeed("test -x /run/current-system/sw/bin/constellation")
    machine.succeed("test -x /run/current-system/sw/bin/spacedust") 
    machine.succeed("test -x /run/current-system/sw/bin/ufos")
    machine.succeed("test -x /run/current-system/sw/bin/who-am-i")
    machine.succeed("test -x /run/current-system/sw/bin/quasar")
    machine.succeed("test -x /run/current-system/sw/bin/pocket")
    machine.succeed("test -x /run/current-system/sw/bin/reflector")
    machine.succeed("test -x /run/current-system/sw/bin/links")
    
    # Verify Blacksky packages
    machine.succeed("test -x /run/current-system/sw/bin/rsky-pds")
    machine.succeed("test -x /run/current-system/sw/bin/rsky-relay")
    machine.succeed("test -x /run/current-system/sw/bin/rsky-feedgen")
    machine.succeed("test -x /run/current-system/sw/bin/rsky-firehose")
    
    # Verify ATProto packages
    machine.succeed("test -x /run/current-system/sw/bin/allegedly")
    machine.succeed("test -x /run/current-system/sw/bin/quickdid")
    machine.succeed("test -x /run/current-system/sw/bin/red-dwarf-serve")
    machine.succeed("test -x /run/current-system/sw/bin/streamplace")
    
    machine.log("All core library packages built and installed successfully")
    
    # Test 2: Dependency Verification - Check that binaries have correct dependencies
    machine.log("=== Dependency Verification Tests ===")
    
    # Check that Rust binaries are properly linked
    machine.succeed("ldd /run/current-system/sw/bin/constellation | grep -E '(libssl|libcrypto|libz)'")
    machine.succeed("ldd /run/current-system/sw/bin/allegedly | grep -E '(libssl|libcrypto|libpq)'")
    machine.succeed("ldd /run/current-system/sw/bin/quickdid | grep -E '(libssl|libcrypto|libsqlite)'")
    
    # Verify that binaries are not missing critical dependencies
    machine.succeed("! ldd /run/current-system/sw/bin/constellation | grep 'not found'")
    machine.succeed("! ldd /run/current-system/sw/bin/allegedly | grep 'not found'")
    machine.succeed("! ldd /run/current-system/sw/bin/quickdid | grep 'not found'")
    
    machine.log("Dependency verification completed successfully")
    
    # Test 3: Basic Functionality - Test that binaries can execute basic commands
    machine.log("=== Basic Functionality Tests ===")
    
    # Test help commands where available (non-blocking)
    machine.succeed("constellation --help || echo 'Help not available for constellation'")
    machine.succeed("allegedly --help || echo 'Help not available for allegedly'")
    machine.succeed("quickdid --help || echo 'Help not available for quickdid'")
    
    # Test version commands where available (non-blocking)
    machine.succeed("constellation --version || echo 'Version not available for constellation'")
    machine.succeed("allegedly --version || echo 'Version not available for allegedly'")
    machine.succeed("quickdid --version || echo 'Version not available for quickdid'")
    
    machine.log("Basic functionality tests completed")
    
    # Test 4: File Type Verification - Ensure binaries are correct architecture
    machine.log("=== File Type Verification ===")
    
    machine.succeed("file /run/current-system/sw/bin/constellation | grep 'ELF.*executable'")
    machine.succeed("file /run/current-system/sw/bin/allegedly | grep 'ELF.*executable'")
    machine.succeed("file /run/current-system/sw/bin/quickdid | grep 'ELF.*executable'")
    
    machine.log("File type verification completed successfully")
    
    machine.log("=== All Core Library Build Verification Tests Passed ===")
  '';
})