# Parameterized pds-dash builder with theme and configuration support
# Allows building pds-dash with custom themes and configuration at build time
#
# Example usage:
#
# pkgs.callPackage ./pds-dash-themed.nix {
#   theme = "sunset";
#   pdsUrl = "http://pds.example.com";
#   frontendUrl = "https://bsky.app";
#   maxPosts = 20;
# }

{ pkgs, lib
, theme ? "default"
, pdsUrl ? "http://127.0.0.1:3000"
, frontendUrl ? "https://deer.social"
, maxPosts ? 20
, footerText ? "<a href='https://git.witchcraft.systems/scientific-witchery/pds-dash' target='_blank'>Source</a> (<a href='https://github.com/witchcraft-systems/pds-dash/' target='_blank'>github mirror</a>)"
, showFuturePosts ? false
, ...
}:

let
  src = pkgs.fetchFromGitea {
    domain = "git.witchcraft.systems";
    owner = "scientific-witchery";
    repo = "pds-dash";
    rev = "c348ed5d46a0d95422ea6f4925420be8ff3ce8f0";
    sha256 = "sha256-9Geh8X5523tcZYyS7yONBjUW20ovej/5uGojyBBcMFI=";
  };

  # Available themes in pds-dash
  availableThemes = [ "default" "express" "sunset" "witchcraft" ];

  # Validate theme
  validTheme = if lib.elem theme availableThemes then theme else
    throw "Invalid theme '${theme}'. Must be one of: ${lib.concatStringsSep ", " availableThemes}";

  # Platform-specific hashes for node_modules
  nodeModulesHashes = {
    x86_64-linux = "sha256-nArr6RtfzSLKY6bjT+UngD8G43ZjhR+Ev3KAlOahp50=";
    x86_64-darwin = "sha256-yUeEN7Q6YdocvzALRBpKtJpZXMSgTmf6RMS5nmLh7kE=";
    aarch64-darwin = "sha256-yUeEN7Q6YdocvzALRBpKtJpZXMSgTmf6RMS5nmLh7kE=";
    aarch64-linux = "sha256-nArr6RtfzSLKY6bjT+UngD8G43ZjhR+Ev3KAlOahp50=";
  };

  # Fixed-output derivation to create node_modules
  nodeModules = pkgs.stdenv.mkDerivation {
    name = "pds-dash-node-modules";
    inherit src;

    nativeBuildInputs = [ pkgs.deno ];

    buildPhase = ''
      export HOME=$TMPDIR
      export DENO_NO_UPDATE_CHECK=1

      # Create config.ts (needed for dependency resolution)
      cp config.ts.example config.ts

      # Install dependencies to create node_modules
      deno install --frozen
    '';

    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = nodeModulesHashes.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}");
  };

  # Generate config.ts with custom settings
  configTs = pkgs.writeText "config.ts" ''
    /**
     * Generated Configuration for pds-dash
     * Theme: ${validTheme}
     */
    export class Config {
      /**
       * The base URL of the PDS (Personal Data Server).
       */
      static readonly PDS_URL: string = "${pdsUrl}";

      /**
       * Theme to be used
       */
      static readonly THEME: string = "${validTheme}";

      /**
       * The base URL of the frontend service for linking to replies/quotes/accounts etc.
       */
      static readonly FRONTEND_URL: string = "${frontendUrl}";

      /**
       * Maximum number of posts to fetch from the PDS per request
       */
      static readonly MAX_POSTS: number = ${toString maxPosts};

      /**
       * Footer text for the dashboard. Supports HTML.
       */
      static readonly FOOTER_TEXT: string = ${lib.strings.escapeNixString footerText};

      /**
       * Whether to show posts with timestamps that are in the future.
       */
      static readonly SHOW_FUTURE_POSTS: boolean = ${if showFuturePosts then "true" else "false"};
    }
  '';

in

pkgs.stdenv.mkDerivation {
  pname = "pds-dash-themed";
  version = "0.1.0-${validTheme}";

  inherit src;

  nativeBuildInputs = [ pkgs.deno ];

  buildPhase = ''
    runHook preBuild

    export DENO_NO_UPDATE_CHECK=1
    export HOME="$TMPDIR"

    # Copy cached node_modules
    cp -r ${nodeModules}/node_modules .
    chmod -R u+w node_modules

    # Use generated config.ts with theme and custom settings
    cp ${configTs} config.ts

    # Create deno.json to override the build task with --sloppy-imports
    cat > deno.json << 'EOF'
{
  "tasks": {
    "build": "deno run --allow-all --sloppy-imports npm:vite build"
  }
}
EOF

    # Build with the selected theme
    deno task build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/* $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "pds-dash - ATProto PDS dashboard (theme: ${validTheme})";
    longDescription = ''
      A frontend dashboard with statistics and monitoring for your ATProto PDS.
      This is a themed variant built with custom configuration.

      Theme: ${validTheme}
      PDS URL: ${pdsUrl}
      Frontend URL: ${frontendUrl}
      Max Posts: ${toString maxPosts}
    '';
    homepage = "https://git.witchcraft.systems/scientific-witchery/pds-dash";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
