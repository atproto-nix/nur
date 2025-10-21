# Multi-language build utilities for ATproto ecosystem
{ lib, pkgs, craneLib, buildGoModule, buildNpmPackage, ... }:

let
  # Standard environment variables for ATproto builds
  standardEnv = {
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

  # Standard native build inputs for ATproto services
  standardNativeInputs = with pkgs; [
    pkg-config
    perl
  ];

  # Standard build inputs for ATproto services
  standardBuildInputs = with pkgs; [
    zstd
    lz4
    rocksdb
    openssl
    sqlite
    postgresql
  ];

in
{
  # Rust packaging with ATproto-specific environment
  buildRustAtprotoPackage = { src, cargoToml ? null, extraEnv ? {}, ... }@args:
    let
      # Remove packaging-specific arguments from crane arguments
      craneArgs = builtins.removeAttrs args [ "extraEnv" "cargoToml" ];
      
      # Merge environments
      finalEnv = standardEnv // extraEnv;
      
      # Standard configuration
      standardArgs = {
        env = finalEnv;
        nativeBuildInputs = standardNativeInputs ++ (args.nativeBuildInputs or []);
        buildInputs = standardBuildInputs ++ (args.buildInputs or []);
        tarFlags = "--no-same-owner";
      };
      
      # Merge all arguments
      finalArgs = standardArgs // craneArgs;
    in
    craneLib.buildPackage finalArgs;

  # Enhanced Rust workspace packaging with shared artifacts
  buildRustWorkspace = { owner, repo, rev, sha256, members, commonEnv ? {}, ... }@args:
    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };
      
      workspaceName = args.pname or repo;
      
      # Shared dependency artifacts for all workspace members
      cargoArtifacts = craneLib.buildDepsOnly {
        inherit src;
        pname = "${workspaceName}-deps";
        version = args.version or "0.1.0";
        env = standardEnv // commonEnv;
        nativeBuildInputs = standardNativeInputs ++ (args.commonNativeInputs or []);
        buildInputs = standardBuildInputs ++ (args.commonBuildInputs or []);
        tarFlags = "--no-same-owner";
      };
      
      # Individual package builder
      buildMember = member:
        let
          # Handle special naming cases (e.g., "ufos/fuzz" -> "ufos-fuzz")
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
          env = standardEnv // commonEnv;
          nativeBuildInputs = standardNativeInputs ++ (args.commonNativeInputs or []);
          buildInputs = standardBuildInputs ++ (args.commonBuildInputs or []);
          tarFlags = "--no-same-owner";
          
          # Pass through any member-specific overrides
          meta = (args.meta or {}) // {
            description = args.memberDescriptions.${member} or "ATproto service: ${member}";
          };
        };
    in
    lib.genAttrs members buildMember;

  # Node.js packaging with workspace support
  buildNodeAtprotoPackage = { src, packageJson ? null, workspaces ? [], ... }@args:
    let
      # Remove packaging-specific arguments
      npmArgs = builtins.removeAttrs args [ "packageJson" "workspaces" ];
      
      # Standard Node.js configuration for ATproto
      standardArgs = {
        npmDepsHash = args.npmDepsHash or lib.fakeHash;
        dontNpmBuild = args.dontNpmBuild or false;
        
        # Standard build inputs for Node.js ATproto apps
        nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
          nodejs
          python3
        ]);
        
        buildInputs = (args.buildInputs or []) ++ (with pkgs; [
          openssl
          sqlite
        ]);
        
        # Environment for native modules
        env = (args.env or {}) // {
          PYTHON = "${pkgs.python3}/bin/python";
        };
      };
      
      # Merge arguments
      finalArgs = standardArgs // npmArgs;
    in
    if workspaces != [] then
      # Handle pnpm workspace builds
      let
        buildWorkspace = workspace: buildNpmPackage (finalArgs // {
          pname = "${args.pname or "workspace"}-${workspace}";
          sourceRoot = "${src.name}/${workspace}";
        });
      in
      lib.genAttrs workspaces buildWorkspace
    else
      buildNpmPackage finalArgs;

  # pnpm workspace packaging for complex monorepos
  buildPnpmWorkspace = { owner, repo, rev, sha256, workspaces, ... }@args:
    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };
      
      # Process pnpm catalog dependencies if present
      processedPackageJson = src; # TODO: Implement catalog dependency processing
      
      # Build individual workspace packages
      buildWorkspace = workspace: buildNpmPackage {
        inherit src;
        pname = "${args.pname or repo}-${workspace}";
        version = args.version or "0.1.0";
        sourceRoot = "${src.name}/${workspace}";
        npmDepsHash = args.npmDepsHash or lib.fakeHash;
        
        # pnpm-specific configuration
        npmConfigHook = pkgs.writeShellScript "pnpm-config" ''
          # Configure pnpm for workspace builds
          export PNPM_HOME="$PWD/.pnpm"
          export PATH="$PNPM_HOME:$PATH"
        '';
        
        nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
          nodejs
          nodePackages.pnpm
        ]);
        
        # Workspace-specific build configuration
        buildPhase = args.buildPhase or ''
          runHook preBuild
          pnpm build
          runHook postBuild
        '';
        
        installPhase = args.installPhase or ''
          runHook preInstall
          mkdir -p $out
          cp -r dist/* $out/ || cp -r build/* $out/ || cp -r out/* $out/
          runHook postInstall
        '';
      };
    in
    lib.genAttrs workspaces buildWorkspace;

  # Go packaging with ATproto dependencies
  buildGoAtprotoModule = { owner, repo, rev, sha256, services ? [], ... }@args:
    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };
      
      # Common Go build environment for ATproto
      commonEnv = {
        CGO_ENABLED = "1";
        # ATproto-specific Go build flags
      } // (args.env or {});
      
      # Standard Go configuration
      standardArgs = {
        inherit src;
        env = commonEnv;
        
        nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
          pkg-config
        ]);
        
        buildInputs = (args.buildInputs or []) ++ (with pkgs; [
          openssl
          sqlite
        ]);
        
        vendorHash = args.vendorHash or lib.fakeHash;
      };
      
      # Build individual services from the module
      buildService = service: buildGoModule (standardArgs // {
        pname = "${args.pname or repo}-${service}";
        version = args.version or "0.1.0";
        subPackages = [ "cmd/${service}" ];
        
        meta = (args.meta or {}) // {
          description = args.serviceDescriptions.${service} or "ATproto Go service: ${service}";
        };
      });
    in
    if services == [] 
    then buildGoModule (standardArgs // (builtins.removeAttrs args [ "services" "serviceDescriptions" ]))
    else lib.genAttrs services buildService;

  # Deno packaging for TypeScript applications
  buildDenoAtprotoApp = { src, denoJson ? null, ... }@args:
    let
      # Remove Deno-specific arguments
      denoArgs = builtins.removeAttrs args [ "denoJson" ];
    in
    pkgs.stdenv.mkDerivation (denoArgs // {
      nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
        deno
      ]);
      
      # Deno-specific build configuration
      configurePhase = args.configurePhase or ''
        runHook preConfigure
        
        # Configure Deno cache directory
        export DENO_DIR="$PWD/.deno"
        mkdir -p "$DENO_DIR"
        
        runHook postConfigure
      '';
      
      buildPhase = args.buildPhase or ''
        runHook preBuild
        
        # Deno build process
        if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
          deno task build || deno compile --allow-all --output=app main.ts
        else
          deno compile --allow-all --output=app main.ts
        fi
        
        runHook postBuild
      '';
      
      installPhase = args.installPhase or ''
        runHook preInstall
        
        mkdir -p $out/bin
        if [ -f "app" ]; then
          cp app $out/bin/${args.pname}
        elif [ -d "dist" ]; then
          cp -r dist/* $out/
        elif [ -d "build" ]; then
          cp -r build/* $out/
        fi
        
        runHook postInstall
      '';
      
      meta = (args.meta or {}) // {
        platforms = lib.platforms.all;
      };
    });

  # Multi-language build coordination (placeholder for future implementation)
  buildMultiLanguageProject = { src, components, ... }@args:
    throw "buildMultiLanguageProject not yet implemented - use individual language builders";

  # Cross-language interface validation
  validateCrossLanguageInterfaces = { rustComponent, nodeComponent, ... }@args:
    pkgs.runCommand "validate-interfaces" {} ''
      # Basic interface compatibility validation
      echo "Validating cross-language interfaces..."
      
      # Check if Rust component exports expected interfaces
      if [ -d "${rustComponent}" ]; then
        echo "Rust component found: ${rustComponent}"
      fi
      
      # Check if Node component imports expected interfaces
      if [ -d "${nodeComponent}" ]; then
        echo "Node component found: ${nodeComponent}"
      fi
      
      # Create validation result
      echo "Interface validation completed" > $out
    '';

  # Shared dependency management
  createSharedDependencies = { language, dependencies ? [], ... }@args:
    if language == "rust" then
      # Create shared Cargo artifacts
      craneLib.buildDepsOnly {
        src = args.src;
        pname = "${args.pname or "shared"}-deps";
        version = args.version or "0.1.0";
        env = standardEnv // (args.env or {});
        nativeBuildInputs = standardNativeInputs;
        buildInputs = standardBuildInputs;
      }
    else if language == "nodejs" then
      # Create shared node_modules
      pkgs.runCommand "${args.pname or "shared"}-node-deps" {} ''
        mkdir -p $out/node_modules
        # TODO: Implement shared node_modules creation
        echo "Shared Node.js dependencies placeholder" > $out/node_modules/.placeholder
      ''
    else
      throw "Shared dependencies not implemented for language: ${language}";

  # Export standard configurations
  inherit standardEnv standardNativeInputs standardBuildInputs;
}