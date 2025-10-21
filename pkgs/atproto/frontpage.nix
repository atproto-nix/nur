# Frontpage/Bluesky official implementation
{ lib, pkgs, craneLib, buildNpmPackage, fetchFromGitHub, atprotoCore, packaging, ... }:

let
  # Source from official GitHub repository
  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "frontpage";
    rev = "main"; # TODO: Pin to specific commit
    sha256 = lib.fakeHash; # TODO: Replace with actual hash
  };
  
  # pnpm workspace configuration
  workspaces = [
    "packages/frontpage"
    "packages/atproto-browser" 
    "packages/unravel"
    "packages/frontpage-atproto-client"
    "packages/frontpage-oauth"
    "packages/frontpage-oauth-preview-client"
  ];
  
  # Rust workspace members
  rustMembers = [
    "drainpipe"
    "drainpipe-cli" 
    "drainpipe-store"
  ];

  # Build individual Node.js packages
  nodePackages = let
    # Common configuration for all workspace packages
    commonConfig = {
      npmDepsHash = lib.fakeHash; # TODO: Generate actual hash
      
      nativeBuildInputs = with pkgs; [
        nodejs_20
        nodePackages.pnpm
        python3
      ];
      
      buildInputs = with pkgs; [
        openssl
        sqlite
      ];
      
      # Handle pnpm catalog dependencies
      preBuild = ''
        # Configure pnpm for workspace builds
        export PNPM_HOME="$PWD/.pnpm"
        export PATH="$PNPM_HOME:$PATH"
        
        # Install dependencies using pnpm
        pnpm install --frozen-lockfile
      '';
      
      buildPhase = ''
        runHook preBuild
        
        # Build the package
        if [ -f "package.json" ] && grep -q '"build"' package.json; then
          pnpm build
        fi
        
        runHook postBuild
      '';
      
      installPhase = ''
        runHook preInstall
        
        mkdir -p $out
        
        # Install built assets
        if [ -d ".next" ]; then
          cp -r .next $out/
          cp -r public $out/ 2>/dev/null || true
          cp package.json $out/
        elif [ -d "dist" ]; then
          cp -r dist/* $out/
        elif [ -d "build" ]; then
          cp -r build/* $out/
        else
          # Install source if no build output
          cp -r . $out/
        fi
        
        runHook postInstall
      '';
    };
  in
  {
    # Main frontpage application
    frontpage = buildNpmPackage (commonConfig // {
      inherit src;
      pname = "frontpage";
      version = "0.1.0";
      sourceRoot = "${src.name}/packages/frontpage";
      
      meta = with lib; {
        description = "Frontpage web application";
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    });
    
    # ATproto browser interface
    atproto-browser = buildNpmPackage (commonConfig // {
      inherit src;
      pname = "atproto-browser";
      version = "0.1.0";
      sourceRoot = "${src.name}/packages/atproto-browser";
      
      meta = with lib; {
        description = "ATproto browser interface";
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    });
    
    # Unravel utility
    unravel = buildNpmPackage (commonConfig // {
      inherit src;
      pname = "unravel";
      version = "0.1.0";
      sourceRoot = "${src.name}/packages/unravel";
      
      meta = with lib; {
        description = "Unravel utility for ATproto";
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    });
    
    # OAuth components
    frontpage-atproto-client = buildNpmPackage (commonConfig // {
      inherit src;
      pname = "frontpage-atproto-client";
      version = "0.1.0";
      sourceRoot = "${src.name}/packages/frontpage-atproto-client";
      
      meta = with lib; {
        description = "Frontpage ATproto client library";
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    });
    
    frontpage-oauth = buildNpmPackage (commonConfig // {
      inherit src;
      pname = "frontpage-oauth";
      version = "0.1.0";
      sourceRoot = "${src.name}/packages/frontpage-oauth";
      
      meta = with lib; {
        description = "Frontpage OAuth implementation";
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    });
    
    frontpage-oauth-preview-client = buildNpmPackage (commonConfig // {
      inherit src;
      pname = "frontpage-oauth-preview-client";
      version = "0.1.0";
      sourceRoot = "${src.name}/packages/frontpage-oauth-preview-client";
      
      meta = with lib; {
        description = "Frontpage OAuth preview client";
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    });
  };
  # Build Rust services individually since they're in a separate workspace
  rustPackages = let
    # Rust source with proper workspace structure
    rustSrc = src;
    
    # Common Rust configuration
    commonRustConfig = {
      inherit rustSrc;
      version = "0.2.0";
      
      # Standard ATproto Rust environment
      env = packaging.standardEnv // {
        RUST_LOG = "info";
      };
      
      nativeBuildInputs = packaging.standardNativeInputs;
      buildInputs = packaging.standardBuildInputs;
      
      meta = with lib; {
        homepage = "https://github.com/bluesky-social/frontpage";
        license = licenses.mit;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    };
    
    # Build shared dependencies for Rust workspace
    cargoArtifacts = craneLib.buildDepsOnly {
      src = rustSrc;
      pname = "frontpage-rust-deps";
      version = "0.2.0";
      env = commonRustConfig.env;
      nativeBuildInputs = commonRustConfig.nativeBuildInputs;
      buildInputs = commonRustConfig.buildInputs;
    };
  in
  {
    # Drainpipe main service
    drainpipe = craneLib.buildPackage (commonRustConfig // {
      inherit cargoArtifacts;
      src = rustSrc;
      pname = "drainpipe";
      cargoExtraArgs = "--package drainpipe";
      
      meta = commonRustConfig.meta // {
        description = "ATproto firehose consumer and data pipeline";
      };
    });
    
    # Drainpipe CLI
    drainpipe-cli = craneLib.buildPackage (commonRustConfig // {
      inherit cargoArtifacts;
      src = rustSrc;
      pname = "drainpipe-cli";
      cargoExtraArgs = "--package drainpipe-cli";
      
      meta = commonRustConfig.meta // {
        description = "Command-line interface for drainpipe";
      };
    });
    
    # Drainpipe store library
    drainpipe-store = craneLib.buildPackage (commonRustConfig // {
      inherit cargoArtifacts;
      src = rustSrc;
      pname = "drainpipe-store";
      cargoExtraArgs = "--package drainpipe-store";
      
      meta = commonRustConfig.meta // {
        description = "Storage backend for drainpipe";
      };
    });
  };

in
{
  # Export individual packages
  inherit (nodePackages) frontpage atproto-browser unravel;
  inherit (nodePackages) frontpage-atproto-client frontpage-oauth;
  inherit (nodePackages) frontpage-oauth-preview-client;
  
  inherit (rustPackages) drainpipe drainpipe-cli drainpipe-store;
  
  # Combined package for easy deployment
  frontpage-full = pkgs.symlinkJoin {
    name = "frontpage-full";
    paths = [
      nodePackages.frontpage
      rustPackages.drainpipe
    ];
    
    meta = with lib; {
      description = "Complete Frontpage/Bluesky implementation";
      longDescription = ''
        Official Bluesky Frontpage implementation including:
        - Frontpage web application (Next.js)
        - ATproto browser interface
        - Unravel utility
        - Drainpipe firehose consumer (Rust)
        - OAuth components
        
        This is the official reference implementation from Bluesky Social.
      '';
      homepage = "https://github.com/bluesky-social/frontpage";
      license = licenses.mit;
      maintainers = [ ];
      platforms = platforms.linux;
      
      # ATproto-specific metadata
      atproto = {
        category = "infrastructure";
        services = [ "frontpage" "drainpipe" "oauth" ];
        protocols = [ "xrpc" "jetstream" "firehose" ];
        dependencies = [ "postgresql" "sqlite" ];
        tier = 1;
      };
    };
  };
}