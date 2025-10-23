{ lib
, pkgs
, buildNpmPackage
, fetchFromTangled
, nodejs
, ...
}:

# Red Dwarf - Bluesky client using Constellation (by whey.party)
# A React SPA that connects directly to PDSs and uses Constellation for backlinks
buildNpmPackage rec {
  pname = "red-dwarf";
  version = "unstable-2025-01-15";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@whey.party";
    repo = "red-dwarf";
    rev = "5ed2c581f947abad6e87b29bc072990522ca1c6d";
    hash = "sha256-11a639sg78jlpaqrgck18hpy9fmkfalvzzkyxqha1d1sfcq5gdqz";
  };

  npmDepsHash = "sha256-Im7RGPWyPQLT0O2ssPm3gHnTk4k1t4nV4ohhPmTxXL8=";

  nativeBuildInputs = [
    nodejs
  ];

  # Set production mode for vite build
  NODE_ENV = "production";

  # Build the React application with Vite
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  # Install the built dist directory and create a serve script
  installPhase = ''
    runHook preInstall

    # Install static files
    mkdir -p $out/share/red-dwarf
    cp -r dist/* $out/share/red-dwarf/

    # Create serve wrapper script
    mkdir -p $out/bin
    cat > $out/bin/red-dwarf-serve << 'EOF'
#!/bin/sh
# Simple static file server for Red Dwarf SPA
cd "$out/share/red-dwarf"
exec ${pkgs.python3}/bin/python -m http.server "''${PORT:-3768}"
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
      description = "Bluesky client using Constellation instead of AppView";
      dependencies = [ "constellation" ]; # Requires Microcosm Constellation
    };

    organization = {
      name = "whey-party";
      displayName = "Whey Party";
      website = "https://whey.party";
      contact = null;
      maintainer = "whey.party";
      repository = "https://tangled.org/@whey.party/red-dwarf";
      packageCount = 1;
      atprotoFocus = [ "applications" "clients" ];
    };
  };

  meta = with lib; {
    description = "Bluesky client that uses Constellation instead of AppView servers";
    longDescription = ''
      Red Dwarf is a Bluesky client that doesn't use any AppView servers.
      Instead, it gathers data from Constellation (Microcosm's backlink index)
      and each user's PDS directly.

      Built with React 19, TanStack Query, TanStack Router, and Tailwind CSS v4.
      Uses Microcosm's Constellation for backlinks and Slingshot for efficient
      PDS queries.

      Features:
      - OAuth and password authentication
      - Custom feeds support
      - Direct PDS integration
      - No AppView dependency
      - React Query for caching
      - Route keepalive for performance

      Maintained by whey.party
    '';
    homepage = "https://tangled.org/@whey.party/red-dwarf";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
