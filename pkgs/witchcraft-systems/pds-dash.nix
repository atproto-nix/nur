{ pkgs, lib, ... }:
let
  src = pkgs.fetchFromGitea {
    domain = "git.witchcraft.systems";
    owner = "scientific-witchery";
    repo = "pds-dash";
    rev = "main";
    sha256 = "sha256-9Geh8X5523tcZYyS7yONBjUW20ovej/5uGojyBBcMFI=";
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
    outputHash = "sha256-yUeEN7Q6YdocvzALRBpKtJpZXMSgTmf6RMS5nmLh7kE=";
  };
in

pkgs.stdenv.mkDerivation {
  pname = "pds-dash";
  version = "0.1.0";
  
  inherit src;
  
  nativeBuildInputs = [ pkgs.deno ];
  
  buildPhase = ''
    runHook preBuild
    
    export DENO_NO_UPDATE_CHECK=1
    export HOME="$TMPDIR"
    
    # Copy cached node_modules
    cp -r ${nodeModules}/node_modules .
    chmod -R u+w node_modules
    
    # Create config
    cp config.ts.example config.ts
    
    # Create deno.json to override the build task with --sloppy-imports
    cat > deno.json << 'EOF'
{
  "tasks": {
    "build": "deno run --allow-all --sloppy-imports npm:vite build"
  }
}
EOF
    
    # Now deno task build will use our patched command
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
  };
}
