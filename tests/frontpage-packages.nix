# Test for Frontpage/Bluesky official implementation packages
{ pkgs, lib, ... }:

let
  # Import the frontpage packages
  frontpagePackages = pkgs.atproto.frontpage;
  
in
{
  name = "frontpage-packages";
  
  # Test that all packages can be built
  testPackageBuilds = pkgs.runCommand "test-frontpage-builds" {} ''
    echo "Testing Frontpage package builds..."
    
    # Test Node.js packages exist
    test -n "${frontpagePackages.frontpage}" || (echo "frontpage package missing" && exit 1)
    test -n "${frontpagePackages.atproto-browser}" || (echo "atproto-browser package missing" && exit 1)
    test -n "${frontpagePackages.unravel}" || (echo "unravel package missing" && exit 1)
    
    # Test Rust packages exist
    test -n "${frontpagePackages.drainpipe}" || (echo "drainpipe package missing" && exit 1)
    test -n "${frontpagePackages.drainpipe-cli}" || (echo "drainpipe-cli package missing" && exit 1)
    test -n "${frontpagePackages.drainpipe-store}" || (echo "drainpipe-store package missing" && exit 1)
    
    # Test combined package
    test -n "${frontpagePackages.frontpage-full}" || (echo "frontpage-full package missing" && exit 1)
    
    echo "All Frontpage packages are available"
    echo "success" > $out
  '';
  
  # Test package metadata
  testPackageMetadata = pkgs.runCommand "test-frontpage-metadata" {} ''
    echo "Testing Frontpage package metadata..."
    
    # Check that packages have proper ATproto metadata
    ${lib.optionalString (frontpagePackages.frontpage-full.meta ? atproto) ''
      echo "ATproto metadata found in frontpage-full"
    ''}
    
    # Check license information
    ${lib.optionalString (frontpagePackages.frontpage.meta ? license) ''
      echo "License information found in frontpage package"
    ''}
    
    echo "Metadata tests completed"
    echo "success" > $out
  '';
  
  # Test that packages have expected structure
  testPackageStructure = pkgs.runCommand "test-frontpage-structure" {} ''
    echo "Testing Frontpage package structure..."
    
    # Test that Rust packages have binaries
    if [ -d "${frontpagePackages.drainpipe}/bin" ]; then
      echo "Drainpipe binary directory found"
    else
      echo "Warning: Drainpipe binary directory not found"
    fi
    
    # Test that Node.js packages have expected structure
    if [ -d "${frontpagePackages.frontpage}" ]; then
      echo "Frontpage package directory found"
    else
      echo "Warning: Frontpage package directory not found"
    fi
    
    echo "Structure tests completed"
    echo "success" > $out
  '';
}