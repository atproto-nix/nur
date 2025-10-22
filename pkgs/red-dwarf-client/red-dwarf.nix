{ pkgs, buildNpmPackage, fetchFromTangled, ... }:

# Red Dwarf - Bluesky client using Constellation
buildNpmPackage rec {
  pname = "red-dwarf";
  version = "0.1.0";
  
  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@whey.party";
    repo = "red-dwarf";
    rev = "5ed2c581f947abad6e87b29bc072990522ca1c6d";
    sha256 = "11a639sg78jlpaqrgck18hpy9fmkfalvzzkyxqha1d1sfcq5gdqz";
  };
  
  npmDepsHash = "sha256-Im7RGPWyPQLT0O2ssPm3gHnTk4k1t4nV4ohhPmTxXL8=";
  
  # Build the React application
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';
  
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/red-dwarf
    cp -r dist/* $out/share/red-dwarf/
    
    # Create a simple wrapper script for serving
    mkdir -p $out/bin
    cat > $out/bin/red-dwarf-serve << 'EOF'
    #!/bin/sh
    cd $out/share/red-dwarf
    ${pkgs.python3}/bin/python -m http.server 8080
    EOF
    chmod +x $out/bin/red-dwarf-serve
    runHook postInstall
  '';
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "red-dwarf" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      dependencies = [ "constellation" ]; # Requires Microcosm Constellation
    };
    
    organization = {
      name = "red-dwarf-client";
      displayName = "Red Dwarf Client";
      website = null;
      contact = null;
      maintainer = "Red Dwarf Client";
      repository = "https://tangled.org/@whey.party/red-dwarf";
      packageCount = 1;
      atprotoFocus = [ "applications" "clients" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "Bluesky client that uses Constellation instead of AppView servers";
    longDescription = ''
      Bluesky client that uses Constellation instead of AppView servers.
      Provides an alternative client interface for ATProto/Bluesky networks.
      
      Maintained by Red Dwarf Client
    '';
    homepage = "https://tangled.org/@whey.party/red-dwarf";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
    
    organizationalContext = {
      organization = "red-dwarf-client";
      displayName = "Red Dwarf Client";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}