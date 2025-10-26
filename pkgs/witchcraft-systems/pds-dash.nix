{ pkgs, lib, ... }:
let
  src = pkgs.fetchFromGitea {
    domain = "git.witchcraft.systems";
    owner = "scientific-witchery";
    repo = "pds-dash";
    rev = "main";
    sha256 = "sha256-9Geh8X5523tcZYyS7yONBjUW20ovej/5uGojyBBcMFI=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "pds-dash";
  version = "0.1.0";
  
  inherit src;
  
  nativeBuildInputs = [ pkgs.deno ];
  
  configurePhase = ''
    runHook preConfigure
    
    # Set up Deno environment
    export DENO_DIR="$TMPDIR/deno"
    export DENO_NO_UPDATE_CHECK=1
    export HOME="$TMPDIR"
    
    # Copy the lockfile to ensure reproducible builds
    cp ${src}/deno.lock ./deno.lock
    
    # Create config.ts from example (required for build)
    cp ${src}/config.ts.example ./config.ts
    
    runHook postConfigure
  '';
  
  buildPhase = ''
    runHook preBuild
    
    # Install dependencies (uses deno.lock for reproducibility)
    deno install --frozen
    
    # Build the Vite project
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
    description = "A frontend dashboard with stats for your ATProto PDS";
    homepage = "https://git.witchcraft.systems/scientific-witchery/pds-dash";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
