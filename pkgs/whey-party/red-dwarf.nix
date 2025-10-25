{ stdenv, lib, fetchFromTangled, nodejs, pnpm, pkgs, ... }:

let
  pname = "red-dwarf";
  version = "0.1.0";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromTangled {
    owner = "@whey.party";
    repo = "red-dwarf";
    rev = "78b41734545fd9fadd048c0dfcddc848a8b4e68a";
    hash = "sha256-QDuRXTKZyth8U57PCWOjro6YYO4aCEOProMPYSZt3Nw=";
    forceFetchGit = true;
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pkgs.cacert
  ];

  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  configurePhase = ''
    runHook preConfigure

    export HOME=$TMPDIR
    pnpm config set store-dir $TMPDIR/pnpm-store
    pnpm install --shamefully-hoist --frozen-lockfile=false

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
