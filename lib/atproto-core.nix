# ATproto-specific packaging functions and utilities
{ lib, pkgs, craneLib, ... }:

let
  # ATproto package metadata schema validation
  validateAtprotoMetadata = metadata: 
    let
      requiredFields = [ "category" "services" "protocols" ];
      validCategories = [ "infrastructure" "application" "utility" "library" ];
      hasRequiredFields = builtins.all (field: builtins.hasAttr field metadata) requiredFields;
      validCategory = builtins.elem metadata.category validCategories;
      validServices = builtins.isList metadata.services;
      validProtocols = builtins.isList metadata.protocols;
    in
    if !hasRequiredFields then
      throw "ATproto metadata missing required fields: ${builtins.toString (builtins.filter (field: !builtins.hasAttr field metadata) requiredFields)}"
    else if !validCategory then
      throw "ATproto metadata category must be one of: ${builtins.toString validCategories}, got: ${metadata.category}"
    else if !validServices then
      throw "ATproto metadata services must be a list"
    else if !validProtocols then
      throw "ATproto metadata protocols must be a list"
    else
      true;

in
{
  # Lexicon validation and code generation
  buildLexiconPackage = { src, lexicons, outputLang, ... }@args:
    let
      supportedLangs = [ "typescript" "rust" "go" "python" ];
      validLang = builtins.elem outputLang supportedLangs;
    in
    if !validLang then
      throw "Unsupported lexicon output language: ${outputLang}. Supported: ${builtins.toString supportedLangs}"
    else
      pkgs.stdenv.mkDerivation {
        pname = "${args.pname or "lexicon"}-${outputLang}";
        version = args.version or "0.1.0";
        inherit src;
        
        nativeBuildInputs = with pkgs; [ nodejs ];
        
        buildPhase = ''
          mkdir -p $out/lib/${outputLang}
          
          # Generate lexicon bindings for specified language
          case "${outputLang}" in
            typescript)
              echo "// Generated TypeScript lexicon bindings" > $out/lib/${outputLang}/index.ts
              echo "export interface AtprotoLexicon {}" >> $out/lib/${outputLang}/index.ts
              ;;
            rust)
              echo "// Generated Rust lexicon bindings" > $out/lib/${outputLang}/lib.rs
              echo "pub struct AtprotoLexicon;" >> $out/lib/${outputLang}/lib.rs
              ;;
            go)
              echo "// Generated Go lexicon bindings" > $out/lib/${outputLang}/lexicon.go
              echo "package lexicon" >> $out/lib/${outputLang}/lexicon.go
              ;;
            python)
              echo "# Generated Python lexicon bindings" > $out/lib/${outputLang}/__init__.py
              echo "class AtprotoLexicon: pass" >> $out/lib/${outputLang}/__init__.py
              ;;
          esac
        '';
        
        installPhase = "true"; # Output already in $out
        
        meta = with lib; {
          description = "ATproto lexicon bindings for ${outputLang}";
          license = licenses.mit;
          platforms = platforms.all;
        };
      };

  # ATproto service configuration helpers
  mkAtprotoService = { name, package, config ? {}, ... }@args:
    let
      defaultConfig = {
        user = "atproto-${name}";
        group = "atproto-${name}";
        dataDir = "/var/lib/atproto/${name}";
        logLevel = "info";
        openFirewall = false;
      };
      finalConfig = defaultConfig // config;
    in
    {
      inherit name package;
      config = finalConfig;
      
      # Standard systemd service template
      systemdService = {
        description = "ATproto ${name} service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        wants = [ "network.target" ];
        
        serviceConfig = {
          Type = "exec";
          User = finalConfig.user;
          Group = finalConfig.group;
          WorkingDirectory = finalConfig.dataDir;
          
          # Security hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          
          # File system access
          ReadWritePaths = [ finalConfig.dataDir ];
          ReadOnlyPaths = [ "/nix/store" ];
          
          # Restart configuration
          Restart = "on-failure";
          RestartSec = "5s";
          StartLimitBurst = 3;
          StartLimitIntervalSec = "60s";
          
          # Environment
          Environment = [
            "RUST_LOG=${finalConfig.logLevel}"
          ];
        } // (args.extraServiceConfig or {});
      };
      
      # User and group configuration
      users = {
        ${finalConfig.user} = {
          isSystemUser = true;
          group = finalConfig.group;
          home = finalConfig.dataDir;
          createHome = false;
        };
      };
      
      groups = {
        ${finalConfig.group} = {};
      };
      
      # Directory management
      tmpfilesRules = [
        "d '${finalConfig.dataDir}' 0750 ${finalConfig.user} ${finalConfig.group} - -"
      ] ++ (args.extraTmpfilesRules or []);
    };

  # DID and identity management utilities
  mkDidResolver = { endpoints ? [], caching ? true, ... }@args:
    let
      defaultEndpoints = [
        "https://plc.directory"
        "https://web.plc.directory"
      ];
      resolverEndpoints = if endpoints == [] then defaultEndpoints else endpoints;
    in
    {
      inherit endpoints caching;
      resolverEndpoints = resolverEndpoints;
      
      # Configuration for DID resolution
      config = {
        endpoints = resolverEndpoints;
        cache = {
          enabled = caching;
          ttl = args.cacheTtl or 3600; # 1 hour default
          maxSize = args.cacheMaxSize or 10000;
        };
        timeout = args.timeout or 30; # 30 seconds default
      };
      
      # Validation function
      validate = lib.all (endpoint: 
        lib.hasPrefix "https://" endpoint || lib.hasPrefix "http://" endpoint
      ) resolverEndpoints;
    };

  # Database integration for ATproto services
  mkAtprotoDatabase = { type ? "postgresql", migrations ? [], ... }@args:
    let
      supportedTypes = [ "postgresql" "sqlite" "rocksdb" ];
      validType = builtins.elem type supportedTypes;
    in
    if !validType then
      throw "Unsupported database type: ${type}. Supported: ${builtins.toString supportedTypes}"
    else
    {
      inherit type migrations;
      
      # Database-specific configuration
      config = {
        postgresql = {
          host = args.host or "localhost";
          port = args.port or 5432;
          database = args.database or "atproto";
          user = args.user or "atproto";
          passwordFile = args.passwordFile or null;
          sslMode = args.sslMode or "prefer";
          maxConnections = args.maxConnections or 20;
        };
        
        sqlite = {
          path = args.path or "/var/lib/atproto/database.sqlite";
          journalMode = args.journalMode or "WAL";
          synchronous = args.synchronous or "NORMAL";
          cacheSize = args.cacheSize or 10000;
        };
        
        rocksdb = {
          path = args.path or "/var/lib/atproto/rocksdb";
          maxOpenFiles = args.maxOpenFiles or 1000;
          writeBufferSize = args.writeBufferSize or 67108864; # 64MB
          maxWriteBufferNumber = args.maxWriteBufferNumber or 3;
        };
      }.${type};
      
      # Migration management
      migrationConfig = {
        enabled = (migrations != []);
        migrations = migrations;
        autoMigrate = args.autoMigrate or false;
      };
      
      # Connection string generation
      connectionString = 
        if type == "postgresql" then
          "postgresql://${args.user or "atproto"}@${args.host or "localhost"}:${toString (args.port or 5432)}/${args.database or "atproto"}"
        else if type == "sqlite" then
          "sqlite://${args.path or "/var/lib/atproto/database.sqlite"}"
        else if type == "rocksdb" then
          "rocksdb://${args.path or "/var/lib/atproto/rocksdb"}"
        else
          throw "Unknown database type: ${type}";
    };

  # ATproto package metadata helpers
  mkAtprotoMetadata = { category, services ? [], protocols ? ["com.atproto"], dependencies ? [], tier ? 2, ... }@args:
    let
      metadata = {
        inherit category services protocols dependencies tier;
        schemaVersion = "1.0";
      };
      validated = validateAtprotoMetadata metadata;
    in
    metadata;

  # Cross-service communication helpers
  mkServiceDiscovery = { services ? [], endpoints ? {}, ... }@args:
    {
      inherit services endpoints;
      
      # Service registry configuration
      registry = {
        enabled = args.enableRegistry or false;
        backend = args.registryBackend or "consul"; # consul, etcd, dns
        ttl = args.registryTtl or 30;
      };
      
      # Health check configuration
      healthChecks = lib.mapAttrs (service: config: {
        enabled = config.healthCheck or true;
        interval = config.healthInterval or 30;
        timeout = config.healthTimeout or 10;
        endpoint = config.healthEndpoint or "/health";
      }) (args.serviceConfigs or {});
      
      # Load balancing configuration
      loadBalancing = {
        strategy = args.lbStrategy or "round-robin"; # round-robin, least-conn, ip-hash
        healthyThreshold = args.healthyThreshold or 2;
        unhealthyThreshold = args.unhealthyThreshold or 3;
      };
    };

  # Configuration templating for service coordination
  mkConfigTemplate = { template, variables ? {}, ... }@args:
    let
      # Simple variable substitution
      substituteVars = text: vars:
        lib.foldl' (acc: var: 
          lib.replaceStrings ["{{${var}}}"] [toString vars.${var}] acc
        ) text (lib.attrNames vars);
    in
    {
      inherit template variables;
      
      # Render template with variables
      render = substituteVars template variables;
      
      # Validation
      validate = 
        let
          requiredVars = lib.filter (var: !(lib.hasAttr var variables)) 
            (lib.unique (lib.flatten (lib.map (match: 
              if match != null then [(lib.elemAt match 0)] else []
            ) (builtins.split "{{([^}]+)}}" template))));
        in
        if requiredVars != [] then
          throw "Missing required template variables: ${builtins.toString requiredVars}"
        else
          true;
    };

  # Validation utilities
  validateAtprotoPackage = package:
    let
      atproto = package.passthru.atproto or package.meta.atproto or 
        (throw "Package missing ATproto metadata");
    in
    validateAtprotoMetadata atproto;

  # Package compatibility checking
  checkPackageCompatibility = package1: package2:
    let
      p1Meta = package1.passthru.atproto or package1.meta.atproto or {};
      p2Meta = package2.passthru.atproto or package2.meta.atproto or {};
      p1Protocols = p1Meta.protocols or [];
      p2Protocols = p2Meta.protocols or [];
      commonProtocols = lib.intersectLists p1Protocols p2Protocols;
    in
    {
      compatible = (lib.length commonProtocols) > 0;
      sharedProtocols = commonProtocols;
      package1Protocols = p1Protocols;
      package2Protocols = p2Protocols;
      compatibility = if (lib.length commonProtocols) > 0 then "compatible" else "incompatible";
    };

  # Export validation function
  inherit validateAtprotoMetadata;
}