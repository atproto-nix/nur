{ pkgs, lib, ... }:
let
  src = pkgs.fetchFromGitea {
    domain = "git.witchcraft.systems";
    owner = "scientific-witchery";
    repo = "pds-dash";
    rev = "main";
    sha256 = "sha256-9Geh8X5523tcZYyS7yONBjUW20ovej/5uGojyBBcMFI=";
  };
  
  # Fixed-output derivation to fetch Deno dependencies
  denoDeps = pkgs.stdenv.mkDerivation {
    name = "pds-dash-deno-deps";
    inherit src;
    
    nativeBuildInputs = [ pkgs.deno ];
    
    buildPhase = ''
      export DENO_DIR=$out
      export HOME=$TMPDIR
      export DENO_NO_UPDATE_CHECK=1
      
      # Install dependencies - this fetches from network
      deno install --frozen
    '';
    
    installPhase = "true";
    
    # This makes it a fixed-output derivation - network access allowed
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-CY/LJw82zBlNTmLALohhPHD9oQ/zWNRx9gkem8QPtV4=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "pds-dash";
  version = "0.1.0";
  
  inherit src;
  
  nativeBuildInputs = [ pkgs.deno ];
  
  buildPhase = ''
    runHook preBuild
    
    # Copy the cached deps to a writable location
    export DENO_DIR="$TMPDIR/deno_dir"
    cp -r ${denoDeps} $DENO_DIR
    chmod -R +w $DENO_DIR
    
    export DENO_NO_UPDATE_CHECK=1
    export HOME="$TMPDIR"
    
    # Create config from example
    cp config.ts.example config.ts
    
    # Install will now use the writable cache and set up node_modules
    deno install --frozen
    
    # Build using cached dependencies
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
