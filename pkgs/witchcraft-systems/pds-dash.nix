{ lib
, stdenv
, fetchFromGitHub
, buildNpmPackage
, nodejs
, deno
, writeShellScriptBin
}:

let
  # Create a wrapper script that handles configuration
  pds-dash-wrapper = writeShellScriptBin "pds-dash" ''
    #!/bin/sh
    
    # Default configuration directory
    CONFIG_DIR=''${PDS_DASH_CONFIG_DIR:-/etc/pds-dash}
    
    # Check if config.ts exists, if not create from template
    if [ ! -f "$CONFIG_DIR/config.ts" ]; then
      echo "Creating default configuration at $CONFIG_DIR/config.ts"
      mkdir -p "$CONFIG_DIR"
      cp ${placeholder "out"}/share/pds-dash/config.ts.example "$CONFIG_DIR/config.ts"
      echo "Please edit $CONFIG_DIR/config.ts with your PDS configuration"
      exit 1
    fi
    
    # Copy config to working directory and start the application
    WORK_DIR=$(mktemp -d)
    trap "rm -rf $WORK_DIR" EXIT
    
    cp -r ${placeholder "out"}/share/pds-dash/* "$WORK_DIR/"
    cp "$CONFIG_DIR/config.ts" "$WORK_DIR/"
    
    cd "$WORK_DIR"
    exec ${deno}/bin/deno task preview "$@"
  '';
in

buildNpmPackage rec {
  pname = "pds-dash";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "witchcraft-systems";
    repo = "pds-dash";
    rev = "c348ed5d46a0d95422ea6f4925420be8ff3ce8f0";
    hash = "sha256-9Geh8X5523tcZYyS7yONBjUW20ovej/5uGojyBBcMFI=";
  };

  npmDepsHash = lib.fakeHash; # Will be calculated from build

  nativeBuildInputs = [ nodejs deno ];

  # Override build phase to use Deno instead of npm
  buildPhase = ''
    runHook preBuild
    
    # Install Deno dependencies
    ${deno}/bin/deno install
    
    # Build the application
    ${deno}/bin/deno task build
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out/share/pds-dash
    mkdir -p $out/bin
    
    # Copy built application
    cp -r dist/* $out/share/pds-dash/
    
    # Copy configuration template and other assets
    cp config.ts.example $out/share/pds-dash/
    cp -r themes $out/share/pds-dash/
    cp -r public $out/share/pds-dash/
    cp package.json $out/share/pds-dash/
    cp deno.lock $out/share/pds-dash/
    
    # Install wrapper script
    cp ${pds-dash-wrapper}/bin/pds-dash $out/bin/
    
    runHook postInstall
  '';

  # ATProto metadata
  passthru = {
    atproto = {
      type = "application";
      services = [ "pds-dashboard" ];
      protocols = [ "com.atproto" ];
      schemaVersion = "1.0";
      
      # Configuration requirements
      configuration = {
        required = [ "PDS_URL" ];
        optional = [ "THEME" "FRONTEND_URL" "MAX_POSTS" "FOOTER_TEXT" "SHOW_FUTURE_POSTS" ];
      };
    };
    
    organization = {
      name = "witchcraft-systems";
      displayName = "Witchcraft Systems";
      website = null;
      contact = null;
      maintainer = "Witchcraft Systems";
      repository = "https://github.com/witchcraft-systems/pds-dash";
      packageCount = 1;
      atprotoFocus = [ "applications" "tools" ];
    };
  };

  meta = with lib; {
    description = "Frontend dashboard with stats for ATProto PDS";
    longDescription = ''
      Frontend dashboard with statistics and management interface for ATProto PDS.
      Built with Deno and provides a web interface for PDS monitoring.
      
      Maintained by Witchcraft Systems
    '';
    homepage = "https://github.com/witchcraft-systems/pds-dash";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
    mainProgram = "pds-dash";
    
    organizationalContext = {
      organization = "witchcraft-systems";
      displayName = "Witchcraft Systems";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}
