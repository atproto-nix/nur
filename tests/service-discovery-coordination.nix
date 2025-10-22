# Tests for service discovery and coordination system
{ pkgs, lib, ... }:

let
  serviceDiscovery = import ../lib/service-discovery.nix { inherit lib pkgs; };
  dependencyManagement = import ../lib/dependency-management.nix { inherit lib pkgs; };
  configTemplating = import ../lib/config-templating.nix { inherit lib pkgs; };
in

{
  # Test service discovery configuration
  testServiceDiscovery = pkgs.runCommand "test-service-discovery" {} ''
    # Test consul backend configuration
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        serviceDiscovery = import ${../lib/service-discovery.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        discovery = serviceDiscovery.mkServiceDiscovery {
          backend = "consul";
          services = {
            pds = { port = 3000; tags = [ "atproto" "pds" ]; };
            appview = { port = 3002; tags = [ "atproto" "appview" ]; };
          };
        };
      in
      discovery.backend == "consul" && 
      discovery.services.pds.port == 3000
    ' > /dev/null
    
    # Test deployment profile validation
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        serviceDiscovery = import ${../lib/service-discovery.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        profile = serviceDiscovery.deploymentProfiles.simplePDS;
      in
      profile.name == "simple-pds" &&
      profile.validate.valid
    ' > /dev/null
    
    echo "Service discovery tests passed" > $out
  '';

  # Test dependency management
  testDependencyManagement = pkgs.runCommand "test-dependency-management" {} ''
    # Test dependency graph creation
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        dependencyManagement = import ${../lib/dependency-management.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        services = {
          pds = {
            dependencies = [
              { name = "database"; type = "required"; }
              { name = "redis"; type = "optional"; }
            ];
          };
          appview = {
            dependencies = [
              { name = "pds"; type = "required"; }
            ];
          };
          database = {};
          redis = {};
        };
        
        graph = dependencyManagement.mkDependencyGraph services;
      in
      builtins.length graph.nodes == 4 &&
      builtins.elem "database" graph.topologicalSort &&
      builtins.elem "pds" graph.topologicalSort &&
      builtins.elem "appview" graph.topologicalSort
    ' > /dev/null
    
    echo "Dependency management tests passed" > $out
  '';

  # Test configuration templating
  testConfigTemplating = pkgs.runCommand "test-config-templating" {} ''
    # Test template processing
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        configTemplating = import ${../lib/config-templating.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        template = configTemplating.mkConfigTemplate {
          name = "test-template";
          template = "PORT=$${port}\nHOST=$${hostname}";
          outputFormat = "env";
          variables = {
            port = { type = "number"; required = true; };
            hostname = { type = "string"; required = true; };
          };
        };
        
        result = template.processTemplate {
          port = 3000;
          hostname = "localhost";
        };
      in
      builtins.match ".*PORT=3000.*" result != null &&
      builtins.match ".*HOST=localhost.*" result != null
    ' > /dev/null
    
    echo "Configuration templating tests passed" > $out
  '';

  # Integration test with NixOS module
  testIntegration = pkgs.nixosTest {
    name = "atproto-service-coordination";
    
    nodes.server = { config, pkgs, ... }: {
      imports = [
        ../profiles/atproto-stacks.nix
      ];
      
      services.atproto-stacks = {
        profile = "simple-pds";
        domain = "test.local";
        
        discovery = {
          backend = "file";
        };
        
        coordination = {
          strategy = "hub-spoke";
          enableHealthChecks = true;
        };
      };
      
      # Mock services for testing
      systemd.services.atproto-pds = {
        description = "Mock PDS service";
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.python3}/bin/python3 -m http.server 3000";
          Restart = "always";
        };
      };
      
      systemd.services.atproto-database = {
        description = "Mock database service";
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.python3}/bin/python3 -m http.server 5432";
          Restart = "always";
        };
      };
    };
    
    testScript = ''
      server.start()
      server.wait_for_unit("multi-user.target")
      
      # Check that coordination services are created
      server.succeed("systemctl list-units | grep atproto-pds-coordinator")
      
      # Check that discovery configuration files are created
      server.succeed("test -f /etc/atproto/discovery/pds.json")
      
      # Verify services can start with coordination
      server.wait_for_unit("atproto-pds.service")
      server.wait_for_open_port(3000)
      
      # Test health check functionality
      server.succeed("curl -f http://localhost:3000/")
    '';
  };

  # Performance test for large service graphs
  testPerformance = pkgs.runCommand "test-performance" {} ''
    # Test with large number of services
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        dependencyManagement = import ${../lib/dependency-management.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        # Generate 100 services with random dependencies
        services = builtins.listToAttrs (map (i: {
          name = "service-${toString i}";
          value = {
            dependencies = if i > 0 then [
              { name = "service-${toString (i - 1)}"; type = "required"; }
            ] else [];
          };
        }) (builtins.genList (x: x) 100));
        
        graph = dependencyManagement.mkDependencyGraph services;
      in
      builtins.length graph.nodes == 100 &&
      builtins.length graph.topologicalSort == 100
    ' > /dev/null
    
    echo "Performance tests passed" > $out
  '';

  # Test error handling
  testErrorHandling = pkgs.runCommand "test-error-handling" {} ''
    # Test circular dependency detection
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        dependencyManagement = import ${../lib/dependency-management.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        # Create circular dependency
        services = {
          serviceA = {
            dependencies = [ { name = "serviceB"; type = "required"; } ];
          };
          serviceB = {
            dependencies = [ { name = "serviceA"; type = "required"; } ];
          };
        };
        
        # This should throw an error
        result = builtins.tryEval (dependencyManagement.mkDependencyGraph services);
      in
      !result.success
    ' > /dev/null
    
    # Test invalid discovery backend
    ${pkgs.nix}/bin/nix-instantiate --eval --strict --expr '
      let
        serviceDiscovery = import ${../lib/service-discovery.nix} { 
          lib = (import <nixpkgs> {}).lib; 
          pkgs = (import <nixpkgs> {}); 
        };
        
        # This should throw an error
        result = builtins.tryEval (serviceDiscovery.mkServiceDiscovery {
          backend = "invalid-backend";
        });
      in
      !result.success
    ' > /dev/null
    
    echo "Error handling tests passed" > $out
  '';

  # All tests
  allTests = pkgs.runCommand "all-service-coordination-tests" {
    buildInputs = [ 
      testServiceDiscovery 
      testDependencyManagement 
      testConfigTemplating 
      testPerformance 
      testErrorHandling 
    ];
  } ''
    echo "All service discovery and coordination tests completed successfully"
    touch $out
  '';
}