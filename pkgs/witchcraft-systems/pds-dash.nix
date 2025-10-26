{ pkgs, ... }:
let
  src = pkgs.fetchFromGitea {
    domain = "git.witchcraft.systems";
    owner = "witchcraft-systems";
    repo = "pds-dash";
    rev = "main";
    sha256 = "sha256-9Geh8X5523tcZYyS7yONBjUW20ovej/5uGojyBBcMFI=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "pds-dash";
  version = "0.1.0";
  
  src = src;
  
  nativeBuildInputs = [ pkgs.deno ];
  
  buildPhase = ''
    export DENO_DIR="$TMPDIR/deno"
    export DENO_NO_UPDATE_CHECK=1

    cp config.ts.example config.ts
    
    # Cache dependencies
    deno cache --reload src/main.ts
    
    # Build the project
    deno task build
  '';
  
  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';
  
  meta = with pkgs.lib; {
    description = "A frontend dashboard with stats for your ATProto PDS";
    homepage = "https://github.com/witchcraft-systems/pds-dash/";
    license = licenses.mit;
  };
}
