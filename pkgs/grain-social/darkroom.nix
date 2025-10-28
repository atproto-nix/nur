{ lib
, stdenv
, fetchFromTangled
, craneLib
, pkg-config
, openssl
, chromium
, chromedriver
, makeFontsConf
, corefonts
, dejavu_fonts
, liberation_ttf
, noto-fonts
, noto-fonts-color-emoji
, darwin
}:

let
  version = "unstable-2025-01-23";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@grain.social";
    repo = "grain";
    rev = "643445cfbfca683b3f17f8990f444405cff2165a";
    hash = "sha256-4gWb3WcWRcIRLTpU/W54NytGhXY6MdVB4hKWrTNdCqM=";
    forceFetchGit = true;
  };

  # Project source with templates and static directories included
  # (needed for include_str! macros in Rust)
  darkroomSrc = lib.cleanSourceWith {
    src = "${src}/darkroom";
    filter = path: type:
      (craneLib.filterCargoSources path type) ||
      # Include templates and static directories for include_str! macros
      (lib.hasInfix "/templates/" path) ||
      (lib.hasInfix "/static/" path) ||
      (lib.hasSuffix "/templates" path) ||
      (lib.hasSuffix "/static" path);
  };

  commonArgs = {
    pname = "darkroom";
    inherit version;
    src = darkroomSrc;

    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
      openssl.dev
    ] ++ lib.optionals stdenv.isDarwin [
      # macOS-specific frameworks (though Darkroom is primarily for Linux due to Chromium)
    ];

    # Environment variables for OpenSSL
    OPENSSL_NO_VENDOR = 1;
    PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig";
  };

  # Build only dependencies (for caching)
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

in
craneLib.buildPackage (commonArgs // {
  inherit cargoArtifacts;

  # Don't run tests (may require browser environment)
  doCheck = false;

  CARGO_PROFILE = "release";

  # Runtime dependencies for the service
  # Note: These are not included in the package itself,
  # but should be available in the environment when running
  passthru = {
    runtimeDeps = {
      chromium = chromium;
      chromedriver = chromedriver;
      fonts = [
        corefonts
        dejavu_fonts
        liberation_ttf
        noto-fonts
        noto-fonts-color-emoji
      ];
    };

    # Font configuration helper
    makeFontConfig = makeFontsConf {
      fontDirectories = [
        "${corefonts}/share/fonts"
        "${dejavu_fonts}/share/fonts"
        "${liberation_ttf}/share/fonts"
        "${noto-fonts}/share/fonts"
        "${noto-fonts-color-emoji}/share/fonts"
      ];
    };

    atproto = {
      type = "service";
      services = [ "darkroom" ];
      protocols = [ "com.atproto" ];
      schemaVersion = "1.0";
      description = "Grain Social image processing and screenshot service";

      configuration = {
        required = [ "GRAIN_BASE_URL" "PORT" ];
        optional = [ "BASE_URL" "CHROME_PATH" "CHROMEDRIVER_PATH" "RUST_LOG" ];
      };
    };

    organization = {
      name = "grain-social";
      displayName = "Grain Social";
      website = "https://grain.social";
      contact = null;
      maintainer = "Chad Miller";
      repository = "https://tangled.org/@grain.social/grain";
      packageCount = 1; # Will increase as we add more services
      atprotoFocus = [ "applications" "media" "social" ];
    };
  };

  meta = with lib; {
    description = "Grain Social Darkroom - Image processing and screenshot generation service";
    longDescription = ''
      Darkroom is the image processing service for Grain Social, a photo-sharing
      platform built on the AT Protocol. It provides:

      - Composite image generation from HTML templates
      - Gallery preview screenshot capture
      - Image optimization and processing

      Built with Rust, Axum, and Fantoccini (WebDriver client).

      Runtime Requirements:
      - Chromium browser for screenshot capture
      - ChromeDriver for WebDriver protocol
      - Fonts for proper text rendering

      Part of the Grain Social ecosystem by Chad Miller.
    '';
    homepage = "https://grain.social";
    license = licenses.mit;
    # Chromium/ChromeDriver limit cross-platform support
    # Primarily designed for Linux servers, but can build on macOS
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [ ];
    mainProgram = "darkroom";

    organizationalContext = {
      organization = "grain-social";
      displayName = "Grain Social";
      component = "darkroom";
      needsMigration = false;
      migrationPriority = "low";
    };
  };
})
