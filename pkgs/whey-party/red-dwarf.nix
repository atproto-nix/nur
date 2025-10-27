{ stdenv, lib, fetchFromTangled, nodejs, pnpm, pkgs, ... }:

let
  pname = "red-dwarf";
  version = "0.1.0";

  src = fetchFromTangled {
    owner = "@whey.party";
    repo = "red-dwarf";
    rev = "78b41734545fd9fadd048c0dfcddc848a8b4e68a";
    hash = "sha256-QDuRXTKZyth8U57PCWOjro6YYO4aCEOProMPYSZt3Nw=";
    forceFetchGit = true;
  };

  # FOD to cache pnpm dependencies
  pnpmDeps = stdenv.mkDerivation {
    name = "${pname}-pnpm-deps-${version}";
    inherit src;

    nativeBuildInputs = [ nodejs pnpm pkgs.cacert ];

    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    # Patch in our generated lockfile
    postUnpack = ''
      cp ${./red-dwarf-pnpm-lock.yaml} $sourceRoot/pnpm-lock.yaml
    '';

    configurePhase = ''
      runHook preConfigure

      export HOME=$TMPDIR
      pnpm config set store-dir $TMPDIR/pnpm-store
      # Now we can use frozen-lockfile since we patched it in!
      pnpm install --frozen-lockfile

      runHook postConfigure
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R node_modules $out/

      runHook postInstall
    '';

    dontBuild = true;
    dontFixup = true;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-iipEGO0MB2G6+4jZj3ZTqReZwQiWnlXzc0fKsl7IlNo=";  # Get the hash first, then update
  };

in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    nodejs
    pnpm
  ];

  configurePhase = ''
    runHook preConfigure

    # Use cached node_modules from FOD
    cp -R ${pnpmDeps}/node_modules .
    chmod -R +w node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    # Only run vite build, skip tsc type checking
    pnpm exec vite build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R dist/* $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "A Bluesky client built with TanStack and Vite.";
    homepage = "https://github.com/whey-party/red-dwarf";
    license = licenses.mit;
    maintainers = with maintainers; [ jack ];
    platforms = platforms.all;
  };
}
