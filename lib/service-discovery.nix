# Service Discovery and Coordination for ATproto Services
# Provides mechanisms for multi-service deployments with automatic coordination
{ lib, pkgs, ... }:

with lib;

rec {
  # Service discovery backends
  discoveryBackends = {
    consul = "consul";
    etcd = "etcd";
    dns = "dns";
    file = "file";
    env = "env";
  };

  # Service coordination strategies
  coordinationStrategies = {
    leader-follower = "leader-follower";
    peer-to-peer = "peer-to-peer";
    hub-spoke = "hub-spoke";
    mesh = "mesh";
  };

  # Create service discovery configuration
  mkServiceDiscovery = { 
    backend ? "consul", 
    services ? {}, 
    healthCheckInterval ? 30,
    registrationTtl ? 60,
    ... 
  }@args:
    let
      validBackend = builtins.elem backend (builtins.attrValues discoveryBackends);
    in
    if !validBackend then
      throw "Invalid discovery backend: ${backend}. Valid backends: ${builtins.toString (builtins.attrValues discoveryBackends)}"
    else
    {
      inherit backend services healthCheckInterval registrationTtl;
      
      # Backend-specific configuration
      config = if backend == "consul" then {
        consul = {
          address = args.consulAddress or "127.0.0.1:8500";
          datacenter = args.consulDatacenter or "dc1";
          token = args.consulToken or null;
          enableTLS = args.consulEnableTLS or false;
        };
      } else if backend == "etcd" then {
        etcd = {
          endpoints = args.etcdEndpoints or [ "127.0.0.1:2379" ];
          keyPrefix = args.etcdKeyPrefix or "/atproto/services";
          enableTLS = args.etcdEnableTLS or false;
        };
      } else if backend == "dns" then {
        dns = {
          domain = args.dnsDomain or "atproto.local";
          resolver = args.dnsResolver or "127.0.0.1:53";
          ttl = args.dnsTtl or 300;
        };
      } else if backend == "file" then {
        file = {
          path = args.filePath or "/etc/atproto/services.json";
          watchInterval = args.fileWatchInterval or 10;
        };
      } else {
        env = {
          prefix = args.envPrefix or "ATPROTO_SERVICE_";
        };
      };
      
      # Service registration helpers
      registerService = serviceName: serviceConfig: {
        name = serviceName;
        id = "${serviceName}-${serviceConfig.instanceId or "default"}";
        address = serviceConfig.address or "127.0.0.1";
        port = serviceConfig.port;
        tags = serviceConfig.tags or [];
        meta = serviceConfig.meta or {};
        
        # Health check configuration
        check = {
          http = serviceConfig.healthEndpoint or "http://${serviceConfig.address or "127.0.0.1"}:${toString serviceConfig.port}/health";
          interval = "${toString healthCheckInterval}s";
          timeout = "${toString (serviceConfig.healthTimeout or 10)}s";
          deregister_critical_service_after = "${toString (registrationTtl * 2)}s";
        };
      };
    };

  # Service coordination configuration
  mkServiceCoordination = {
    strategy ? "hub-spoke",
    services ? {},
    dependencies ? {},
    loadBalancing ? {},
    ...
  }@args:
    let
      validStrategy = builtins.elem strategy (builtins.attrValues coordinationStrategies);
    in
    if !validStrategy then
      throw "Invalid coordination strategy: ${strategy}. Valid strategies: ${builtins.toString (builtins.attrValues coordinationStrategies)}"
    else
    {
      inherit strategy services dependencies loadBalancing;
      
      # Strategy-specific configuration
      config = if strategy == "leader-follower" then {
        leaderElection = {
          enabled = true;
          lockKey = args.lockKey or "/atproto/leader";
          sessionTtl = args.sessionTtl or 15;
          renewInterval = args.renewInterval or 5;
        };
      } else if strategy == "peer-to-peer" then {
        gossip = {
          enabled = true;
          port = args.gossipPort or 7946;
          seedNodes = args.seedNodes or [];
          encryptionKey = args.encryptionKey or null;
        };
      } else if strategy == "hub-spoke" then {
        hub = {
          service = args.hubService or "coordinator";
          failover = args.hubFailover or [];
          heartbeatInterval = args.heartbeatInterval or 10;
        };
      } else {
        mesh = {
          fullMesh = args.fullMesh or false;
          routingTable = args.routingTable or {};
          convergenceTimeout = args.convergenceTimeout or 30;
        };
      };
      
      # Dependency resolution
      resolveDependencies = serviceName: 
        let
          serviceDeps = dependencies.${serviceName} or [];
          resolvedDeps = map (dep: {
            name = dep;
            required = dependencies.${serviceName}.${dep}.required or true;
            healthCheck = dependencies.${serviceName}.${dep}.healthCheck or "/health";
            timeout = dependencies.${serviceName}.${dep}.timeout or 30;
          }) serviceDeps;
        in
        resolvedDeps;
    };

  # Configuration templating system
  mkConfigurationTemplating = {
    templates ? {},
    variables ? {},
    outputFormat ? "json",
    ...
  }@args:
    let
      supportedFormats = [ "json" "yaml" "toml" "env" ];
      validFormat = builtins.elem outputFormat supportedFormats;
    in
    if !validFormat then
      throw "Invalid output format: ${outputFormat}. Supported formats: ${builtins.toString supportedFormats}"
    else
    {
      inherit templates variables outputFormat;
      
      # Template processing functions
      processTemplate = templateName: templateContent:
        let
          # Simple variable substitution
          substituteVars = content: vars:
            builtins.foldl' (acc: varName:
              let
                varValue = vars.${varName} or "";
                placeholder = "\${${varName}}";
              in
              builtins.replaceStrings [placeholder] [toString varValue] acc
            ) content (builtins.attrNames vars);
        in
        substituteVars templateContent variables;
      
      # Format-specific output generation
      generateOutput = templateName: processedContent:
        if outputFormat == "json" then
          builtins.toJSON (builtins.fromJSON processedContent)
        else if outputFormat == "env" then
          # Convert to environment variable format
          let
            lines = lib.splitString "\n" processedContent;
            envLines = map (line: 
              if builtins.match "^[A-Za-z_][A-Za-z0-9_]*=.*" line != null
              then line
              else ""
            ) lines;
          in
          lib.concatStringsSep "\n" (builtins.filter (x: x != "") envLines)
        else
          processedContent; # Pass through for yaml/toml
      
      # Template registry
      registerTemplate = name: content: variables // { ${name} = content; };
    };

  # Automatic service dependency management
  mkDependencyManagement = {
    services ? {},
    dependencyGraph ? {},
    startupOrder ? "dependency-first",
    healthChecks ? {},
    ...
  }@args:
    let
      validStartupOrders = [ "dependency-first" "parallel" "manual" ];
      validOrder = builtins.elem startupOrder validStartupOrders;
    in
    if !validOrder then
      throw "Invalid startup order: ${startupOrder}. Valid orders: ${builtins.toString validStartupOrders}"
    else
    {
      inherit services dependencyGraph startupOrder healthChecks;
      
      # Dependency resolution
      resolveDependencies = serviceName:
        let
          directDeps = dependencyGraph.${serviceName} or [];
          
          # Recursive dependency resolution
          resolveDep = dep:
            let
              transitiveDeps = resolveDependencies dep;
            in
            [ dep ] ++ transitiveDeps;
          
          allDeps = lib.unique (lib.flatten (map resolveDep directDeps));
        in
        allDeps;
      
      # Startup order calculation
      calculateStartupOrder = 
        let
          allServices = builtins.attrNames services;
          
          # Topological sort for dependency-first startup
          topologicalSort = nodes: edges:
            let
              # Find nodes with no incoming edges
              noIncoming = builtins.filter (node:
                !builtins.any (edge: edge.to == node) edges
              ) nodes;
              
              # Remove nodes and their edges
              removeNode = node: {
                nodes = builtins.filter (n: n != node) nodes;
                edges = builtins.filter (edge: edge.from != node && edge.to != node) edges;
              };
              
              # Recursive sort
              sortRec = remainingNodes: remainingEdges: result:
                if remainingNodes == [] then
                  result
                else
                  let
                    nextNodes = builtins.filter (node:
                      !builtins.any (edge: edge.to == node) remainingEdges
                    ) remainingNodes;
                  in
                  if nextNodes == [] then
                    throw "Circular dependency detected in service graph"
                  else
                    let
                      nextNode = builtins.head nextNodes;
                      updated = removeNode nextNode;
                    in
                    sortRec updated.nodes updated.edges (result ++ [ nextNode ]);
            in
            sortRec nodes edges [];
          
          # Convert dependency graph to edges
          edges = lib.flatten (lib.mapAttrsToList (service: deps:
            map (dep: { from = dep; to = service; }) deps
          ) dependencyGraph);
        in
        if startupOrder == "dependency-first" then
          topologicalSort allServices edges
        else if startupOrder == "parallel" then
          allServices
        else
          []; # Manual order
      
      # Health check coordination
      coordinateHealthChecks = serviceName:
        let
          serviceHealth = healthChecks.${serviceName} or {};
          dependencies = resolveDependencies serviceName;
          
          # Check if all dependencies are healthy
          checkDependencyHealth = deps:
            builtins.all (dep:
              let
                depHealth = healthChecks.${dep} or {};
                endpoint = depHealth.endpoint or "/health";
                timeout = depHealth.timeout or 10;
              in
              true # Placeholder for actual health check logic
            ) deps;
        in
        {
          endpoint = serviceHealth.endpoint or "/health";
          timeout = serviceHealth.timeout or 10;
          interval = serviceHealth.interval or 30;
          dependenciesHealthy = checkDependencyHealth dependencies;
        };
    };

  # Unified deployment profiles for common ATproto stacks
  mkDeploymentProfile = {
    name,
    description ? "",
    services ? {},
    coordination ? {},
    discovery ? {},
    networking ? {},
    security ? {},
    ...
  }@args:
    {
      inherit name description services coordination discovery networking security;
      
      # Profile validation
      validate = 
        let
          requiredServices = builtins.attrNames services;
          missingServices = builtins.filter (service:
            !(services.${service}.enable or false)
          ) requiredServices;
        in
        {
          valid = missingServices == [];
          errors = if missingServices != [] then
            [ "Missing required services: ${builtins.toString missingServices}" ]
          else
            [];
        };
      
      # Generate NixOS configuration
      toNixOSConfig = {
        # Service configurations
        services = lib.mapAttrs (serviceName: serviceConfig:
          serviceConfig // {
            # Inject discovery and coordination configuration
            discovery = discovery;
            coordination = coordination;
          }
        ) services;
        
        # Networking configuration
        networking = networking // {
          # Automatic firewall rules for service ports
          firewall.allowedTCPPorts = lib.unique (lib.flatten (
            lib.mapAttrsToList (serviceName: serviceConfig:
              if serviceConfig.openFirewall or false then
                [ serviceConfig.port ]
              else
                []
            ) services
          ));
        };
        
        # Security configuration
        security = security;
        
        # System packages for coordination tools
        environment.systemPackages = 
          (if discovery.backend or "" == "consul" then [ pkgs.consul ] else []) ++
          (if discovery.backend or "" == "etcd" then [ pkgs.etcd ] else []) ++
          (if coordination.strategy or "" == "peer-to-peer" then [ pkgs.serf ] else []);
      };
    };

  # Pre-defined deployment profiles
  deploymentProfiles = {
    # Simple PDS deployment
    simplePDS = mkDeploymentProfile {
      name = "simple-pds";
      description = "Single-node PDS deployment with basic services";
      
      services = {
        pds = {
          enable = true;
          port = 3000;
          openFirewall = true;
        };
        
        database = {
          enable = true;
          type = "postgresql";
          port = 5432;
        };
      };
      
      coordination = mkServiceCoordination {
        strategy = "hub-spoke";
        dependencies = {
          pds = [ "database" ];
        };
      };
      
      discovery = mkServiceDiscovery {
        backend = "file";
        services = {
          pds = { port = 3000; };
          database = { port = 5432; };
        };
      };
    };
    
    # Full ATproto network node
    fullNode = mkDeploymentProfile {
      name = "full-node";
      description = "Complete ATproto network node with all services";
      
      services = {
        pds = {
          enable = true;
          port = 3000;
          openFirewall = true;
        };
        
        relay = {
          enable = true;
          port = 3001;
          openFirewall = true;
        };
        
        appview = {
          enable = true;
          port = 3002;
          openFirewall = true;
        };
        
        feedgen = {
          enable = true;
          port = 3003;
          openFirewall = false;
        };
        
        labeler = {
          enable = true;
          port = 3004;
          openFirewall = false;
        };
        
        database = {
          enable = true;
          type = "postgresql";
          port = 5432;
        };
        
        redis = {
          enable = true;
          port = 6379;
        };
      };
      
      coordination = mkServiceCoordination {
        strategy = "hub-spoke";
        dependencies = {
          pds = [ "database" "redis" ];
          relay = [ "database" "pds" ];
          appview = [ "database" "relay" ];
          feedgen = [ "appview" ];
          labeler = [ "appview" ];
        };
      };
      
      discovery = mkServiceDiscovery {
        backend = "consul";
        services = {
          pds = { port = 3000; tags = [ "atproto" "pds" ]; };
          relay = { port = 3001; tags = [ "atproto" "relay" ]; };
          appview = { port = 3002; tags = [ "atproto" "appview" ]; };
          feedgen = { port = 3003; tags = [ "atproto" "feedgen" ]; };
          labeler = { port = 3004; tags = [ "atproto" "labeler" ]; };
        };
      };
    };
    
    # Development cluster
    devCluster = mkDeploymentProfile {
      name = "dev-cluster";
      description = "Development cluster with relaxed security";
      
      services = {
        pds = {
          enable = true;
          port = 3000;
          openFirewall = true;
          logLevel = "debug";
        };
        
        appview = {
          enable = true;
          port = 3002;
          openFirewall = true;
          logLevel = "debug";
        };
        
        database = {
          enable = true;
          type = "sqlite";
        };
      };
      
      coordination = mkServiceCoordination {
        strategy = "peer-to-peer";
        dependencies = {
          pds = [ "database" ];
          appview = [ "pds" ];
        };
      };
      
      discovery = mkServiceDiscovery {
        backend = "env";
        services = {
          pds = { port = 3000; };
          appview = { port = 3002; };
        };
      };
      
      security = {
        # Relaxed security for development
        allowInsecureConnections = true;
        disableAuthentication = true;
      };
    };
    
    # Production cluster
    prodCluster = mkDeploymentProfile {
      name = "prod-cluster";
      description = "Production cluster with enhanced security and monitoring";
      
      services = {
        pds = {
          enable = true;
          port = 443;
          openFirewall = true;
          logLevel = "info";
          enableTLS = true;
        };
        
        relay = {
          enable = true;
          port = 443;
          openFirewall = true;
          enableTLS = true;
        };
        
        appview = {
          enable = true;
          port = 443;
          openFirewall = true;
          enableTLS = true;
        };
        
        database = {
          enable = true;
          type = "postgresql";
          port = 5432;
          enableSSL = true;
        };
        
        redis = {
          enable = true;
          port = 6379;
          enableAuth = true;
        };
        
        monitoring = {
          enable = true;
          port = 9090;
          openFirewall = false;
        };
      };
      
      coordination = mkServiceCoordination {
        strategy = "leader-follower";
        dependencies = {
          pds = [ "database" "redis" ];
          relay = [ "database" "pds" ];
          appview = [ "database" "relay" ];
        };
      };
      
      discovery = mkServiceDiscovery {
        backend = "consul";
        healthCheckInterval = 15;
        services = {
          pds = { port = 443; tags = [ "atproto" "pds" "production" ]; };
          relay = { port = 443; tags = [ "atproto" "relay" "production" ]; };
          appview = { port = 443; tags = [ "atproto" "appview" "production" ]; };
        };
      };
      
      security = {
        enableTLS = true;
        enableAuthentication = true;
        enableAuthorization = true;
        enableAuditLogging = true;
        firewallRules = "strict";
      };
    };
  };

  # Helper functions for service coordination
  
  # Generate service discovery configuration files
  generateDiscoveryConfig = discovery: serviceName: serviceConfig:
    let
      config = if discovery.backend == "consul" then {
        service = {
          name = serviceName;
          port = serviceConfig.port;
          tags = serviceConfig.tags or [];
          check = {
            http = serviceConfig.healthEndpoint or "http://localhost:${toString serviceConfig.port}/health";
            interval = "${toString discovery.healthCheckInterval}s";
          };
        };
      } else if discovery.backend == "etcd" then {
        key = "${discovery.config.etcd.keyPrefix}/${serviceName}";
        value = builtins.toJSON {
          address = serviceConfig.address or "127.0.0.1";
          port = serviceConfig.port;
          tags = serviceConfig.tags or [];
        };
      } else if discovery.backend == "dns" then {
        record = {
          name = "${serviceName}.${discovery.config.dns.domain}";
          type = "A";
          value = serviceConfig.address or "127.0.0.1";
          ttl = discovery.config.dns.ttl;
        };
      } else {
        # File or env backend
        "${serviceName}" = {
          address = serviceConfig.address or "127.0.0.1";
          port = serviceConfig.port;
          tags = serviceConfig.tags or [];
        };
      };
    in
    config;
  
  # Generate coordination scripts
  generateCoordinationScript = coordination: serviceName:
    let
      dependencies = coordination.resolveDependencies serviceName;
      
      waitForDependencies = lib.concatStringsSep "\n" (map (dep:
        ''
          echo "Waiting for dependency: ${dep}"
          while ! curl -f -s http://localhost:$${dep}_PORT/health > /dev/null 2>&1; do
            echo "Dependency ${dep} not ready, waiting..."
            sleep 5
          done
          echo "Dependency ${dep} is ready"
        ''
      ) dependencies);
    in
    ''
      #!/bin/bash
      set -euo pipefail
      
      echo "Starting coordination for service: ${serviceName}"
      
      # Wait for dependencies
      ${waitForDependencies}
      
      echo "All dependencies ready, starting ${serviceName}"
    '';
  
  # Generate load balancer configuration
  generateLoadBalancerConfig = coordination: services:
    let
      lbConfig = coordination.loadBalancing or {};
      strategy = lbConfig.strategy or "round-robin";
      
      upstreams = lib.mapAttrsToList (serviceName: serviceConfig: {
        name = serviceName;
        servers = [
          {
            address = "${serviceConfig.address or "127.0.0.1"}:${toString serviceConfig.port}";
            weight = serviceConfig.weight or 1;
            max_fails = serviceConfig.maxFails or 3;
            fail_timeout = serviceConfig.failTimeout or "30s";
          }
        ];
      }) services;
    in
    {
      upstream = upstreams;
      strategy = strategy;
      healthCheck = {
        enabled = true;
        interval = lbConfig.healthCheckInterval or 30;
        timeout = lbConfig.healthCheckTimeout or 10;
      };
    };
}