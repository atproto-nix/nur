{ lib, pkgs, craneLib, ... }:

let
  # Import organizational framework
  organizationalFramework = import ./organizational-framework.nix { inherit lib; };
  # ATProto package metadata schema validation
  validateAtprotoMetadata = metadata: 
    let
      requiredFields = [ "type" "services" "protocols" ];
      validTypes = [ "application" "library" "tool" ];
      hasRequiredFields = builtins.all (field: builtins.hasAttr field metadata) requiredFields;
      validType = builtins.elem metadata.type validTypes;
      validServices = builtins.isList metadata.services;
      validProtocols = builtins.isList metadata.protocols;
    in
    if !hasRequiredFields then
      throw "ATProto metadata missing required fields: ${builtins.toString (builtins.filter (field: !builtins.hasAttr field metadata) requiredFields)}"
    else if !validType then
      throw "ATProto metadata type must be one of: ${builtins.toString validTypes}, got: ${metadata.type}"
    else if !validServices then
      throw "ATProto metadata services must be a list"
    else if !validProtocols then
      throw "ATProto metadata protocols must be a list"
    else
      true;

  # Standard ATProto environment for Rust builds
  defaultRustEnv = {
    LIBCLANG_PATH = lib.makeLibraryPath [ pkgs.llvmPackages.libclang.lib ];
    OPENSSL_NO_VENDOR = "1";
    OPENSSL_LIB_DIR = "${lib.getLib pkgs.openssl}/lib";
    OPENSSL_INCLUDE_DIR = "${lib.getDev pkgs.openssl}/include";
    BINDGEN_EXTRA_CLANG_ARGS = lib.concatStringsSep " " ([
      "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/${lib.versions.major pkgs.llvmPackages.libclang.version}/include"
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      "-I${pkgs.glibc.dev}/include"
    ]);
    ZSTD_SYS_USE_PKG_CONFIG = "1";
    CC = "${pkgs.llvmPackages.clang}/bin/clang";
    CXX = "${pkgs.llvmPackages.clang}/bin/clang++";
    PKG_CONFIG_PATH = "${pkgs.zstd.dev}/lib/pkgconfig:${pkgs.lz4.dev}/lib/pkgconfig";
  };

  # Standard native build inputs for Rust ATProto services
  defaultRustNativeInputs = with pkgs; [
    pkg-config
    perl
  ];

  # Standard build inputs for Rust ATProto services
  defaultRustBuildInputs = with pkgs; [
    zstd
    lz4
    rocksdb
    openssl
    sqlite
    postgresql
  ];

in
{
  # Helper for creating ATProto package metadata
  mkAtprotoPackage = { type, services ? [], protocols ? ["com.atproto"], ... }@args:
    let
      atprotoMetadata = {
        inherit type services protocols;
        schemaVersion = "1.0";
      };
      validated = validateAtprotoMetadata atprotoMetadata;
    in
    args // {
      passthru = (args.passthru or {}) // {
        atproto = atprotoMetadata;
      };
      
      meta = (args.meta or {}) // {
        # Add ATProto-specific metadata to package meta
        atproto = atprotoMetadata;
      };
    };

  # Helper for Rust ATProto services with standard environment
  mkRustAtprotoService = args@{ pname, version, src, type ? "application", services ? [], protocols ? ["com.atproto"], ... }:
    let
      # Extract ATProto-specific arguments
      atprotoArgs = { inherit type services protocols; };
      
      # Remove ATProto-specific arguments from crane arguments
      craneArgs = builtins.removeAttrs args [ "type" "services" "protocols" ];
      
      # Standard Rust environment and dependencies
      standardArgs = {
        env = defaultRustEnv // (args.env or {});
        nativeBuildInputs = defaultRustNativeInputs ++ (args.nativeBuildInputs or []);
        buildInputs = defaultRustBuildInputs ++ (args.buildInputs or []);
        tarFlags = "--no-same-owner";
      };
      
      # Merge all arguments
      finalArgs = standardArgs // craneArgs;
      
      # Build the package first, then add ATProto metadata
      package = craneLib.buildPackage finalArgs;
    in
    package // {
      passthru = (package.passthru or {}) // {
        atproto = atprotoArgs // { schemaVersion = "1.0"; };
      };
      meta = (package.meta or {}) // {
        atproto = atprotoArgs // { schemaVersion = "1.0"; };
      };
    };

  # Helper for Node.js ATProto applications
  mkNodeAtprotoApp = { buildNpmPackage, pname, version, src, type ? "application", services ? [], protocols ? ["com.atproto"], ... }@args:
    let
      # Extract ATProto-specific arguments
      atprotoArgs = { inherit type services protocols; };
      
      # Remove ATProto-specific arguments from buildNpmPackage arguments
      npmArgs = builtins.removeAttrs args [ "type" "services" "protocols" "buildNpmPackage" ];
      
      # Standard Node.js build configuration
      standardArgs = {
        inherit pname version src;
        # Add any standard Node.js environment or build configuration here
      };
      
      # Merge all arguments
      finalArgs = standardArgs // npmArgs;
      
      # Build the package first, then add ATProto metadata
      package = buildNpmPackage finalArgs;
    in
    package // {
      passthru = (package.passthru or {}) // {
        atproto = atprotoArgs // { schemaVersion = "1.0"; };
      };
      meta = (package.meta or {}) // {
        atproto = atprotoArgs // { schemaVersion = "1.0"; };
      };
    };

  # Helper for Go ATProto applications
  mkGoAtprotoApp = { buildGoModule, pname, version, src, type ? "application", services ? [], protocols ? ["com.atproto"], ... }@args:
    let
      # Extract ATProto-specific arguments
      atprotoArgs = { inherit type services protocols; };
      
      # Remove ATProto-specific arguments from buildGoModule arguments
      goArgs = builtins.removeAttrs args [ "type" "services" "protocols" "buildGoModule" ];
      
      # Standard Go build configuration
      standardArgs = {
        inherit pname version src;
        # Add any standard Go environment or build configuration here
      };
      
      # Merge all arguments
      finalArgs = standardArgs // goArgs;
      
      # Build the package first, then add ATProto metadata
      package = buildGoModule finalArgs;
    in
    package // {
      passthru = (package.passthru or {}) // {
        atproto = atprotoArgs // { schemaVersion = "1.0"; };
      };
      meta = (package.meta or {}) // {
        atproto = atprotoArgs // { schemaVersion = "1.0"; };
      };
    };

  # Helper for building Rust workspace packages with shared dependencies
  mkRustWorkspace = { src, members, commonEnv ? {}, commonNativeInputs ? [], commonBuildInputs ? [], ... }@args:
    let
      # Build shared dependencies once
      cargoArtifacts = craneLib.buildDepsOnly {
        inherit src;
        pname = "${args.pname or "workspace"}-deps";
        version = args.version or "0.1.0";
        env = defaultRustEnv // commonEnv;
        nativeBuildInputs = defaultRustNativeInputs ++ commonNativeInputs;
        buildInputs = defaultRustBuildInputs ++ commonBuildInputs;
        tarFlags = "--no-same-owner";
      };
      
      # Function to build individual packages
      buildMember = member:
        let
          packageName = if lib.hasSuffix "/fuzz" member then 
            lib.replaceStrings ["/"] ["-"] member 
          else 
            member;
        in
        craneLib.buildPackage {
          inherit src cargoArtifacts;
          pname = packageName;
          version = args.version or "0.1.0";
          cargoExtraArgs = "--package ${packageName}";
          env = defaultRustEnv // commonEnv;
          nativeBuildInputs = defaultRustNativeInputs ++ commonNativeInputs;
          buildInputs = defaultRustBuildInputs ++ commonBuildInputs;
          tarFlags = "--no-same-owner";
        };
    in
    lib.genAttrs members buildMember;

  # Dependency resolution utilities
  resolveDependencies = atprotoPackages: packageName:
    let
      package = atprotoPackages.${packageName} or (throw "Package ${packageName} not found");
      atprotoDeps = package.passthru.atproto.atprotoDependencies or {};
      
      # Recursively resolve dependencies
      resolveDep = depName: depVersion:
        let
          depPackage = atprotoPackages.${depName} or (throw "Dependency ${depName} not found");
          depAtprotoDeps = depPackage.passthru.atproto.atprotoDependencies or {};
        in
        [ depPackage ] ++ (lib.flatten (lib.mapAttrsToList resolveDep depAtprotoDeps));
    in
    lib.unique (lib.flatten (lib.mapAttrsToList resolveDep atprotoDeps));

  # Validation utilities
  validatePackageMetadata = package:
    let
      atproto = package.passthru.atproto or (throw "Package missing ATProto metadata");
    in
    validateAtprotoMetadata atproto;

  # Service configuration helpers
  mkServiceConfig = { serviceName, package, user ? serviceName, group ? serviceName, dataDir ? "/var/lib/${serviceName}", ... }@args:
    {
      inherit serviceName package user group dataDir;
      
      # Standard systemd service configuration
      systemdConfig = {
        description = "ATProto ${serviceName} service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        
        serviceConfig = {
          Type = "exec";
          User = user;
          Group = group;
          WorkingDirectory = dataDir;
          
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
          ReadWritePaths = [ dataDir ];
          ReadOnlyPaths = [ "/nix/store" ];
        } // (args.serviceConfig or {});
      };
      
      # User and group configuration
      userConfig = {
        ${user} = {
          isSystemUser = true;
          group = group;
          home = dataDir;
        };
      };
      
      groupConfig = {
        ${group} = {};
      };
      
      # Directory management
      tmpfilesRules = [
        "d '${dataDir}' 0750 ${user} ${group} - -"
      ];
    };

  # Cross-language compatibility utilities
  mkCrossLanguageBindings = { lexiconSrc, languages ? [ "typescript" "rust" "go" ], outputDir ? "generated" }:
    let
      generateForLanguage = lang:
        pkgs.stdenv.mkDerivation {
          name = "atproto-bindings-${lang}";
          src = lexiconSrc;
          
          buildPhase = ''
            mkdir -p $out/${outputDir}/${lang}
            
            # This would use the appropriate code generation tools
            case "${lang}" in
              typescript)
                echo "// Generated TypeScript bindings" > $out/${outputDir}/${lang}/index.ts
                ;;
              rust)
                echo "// Generated Rust bindings" > $out/${outputDir}/${lang}/lib.rs
                ;;
              go)
                echo "// Generated Go bindings" > $out/${outputDir}/${lang}/bindings.go
                ;;
            esac
          '';
          
          installPhase = "true"; # Output is already in $out
        };
    in
    lib.genAttrs languages generateForLanguage;

  # Lexicon validation and processing utilities
  validateLexicon = lexiconFile:
    pkgs.runCommand "validate-lexicon" {} ''
      # Basic lexicon validation
      if [ -f "${lexiconFile}" ]; then
        echo "Lexicon file exists: ${lexiconFile}"
        touch $out
      else
        echo "Lexicon file not found: ${lexiconFile}"
        exit 1
      fi
    '';

  # Package compatibility matrix utilities
  checkCompatibility = package1: package2:
    let
      p1Protocols = package1.passthru.atproto.protocols or [];
      p2Protocols = package2.passthru.atproto.protocols or [];
      commonProtocols = lib.intersectLists p1Protocols p2Protocols;
    in
    {
      compatible = (lib.length commonProtocols) > 0;
      sharedProtocols = commonProtocols;
      package1Protocols = p1Protocols;
      package2Protocols = p2Protocols;
    };

  # Export standard environments and inputs for reuse
  inherit defaultRustEnv defaultRustNativeInputs defaultRustBuildInputs;
  
  # Export organizational framework
  organizational = organizationalFramework;
  
  # Enhanced package creation with organizational metadata
  mkOrganizationalAtprotoPackage = packageName: packageDef:
    organizationalFramework.createOrganizationalPackage packageName packageDef;
  
  # Organizational validation utilities
  validateOrganizationalPlacement = packageName: actualPath:
    organizationalFramework.validatePackage packageName actualPath;
  
  # Get organizational metadata for package
  getOrganizationalMetadata = packageName:
    organizationalFramework.mapping.generateOrganizationalMetadata packageName;
  
  # Check if package needs organizational migration
  needsOrganizationalMigration = packageName:
    organizationalFramework.utils.needsMigration packageName;
}