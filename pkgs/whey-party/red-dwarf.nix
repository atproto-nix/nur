{ lib
, buildNpmPackage
, fetchFromTangled
}:

buildNpmPackage rec {
  pname = "red-dwarf";
  version = "0.1.0";

  src = fetchFromTangled {
    owner = "@whey.party";
    repo = "red-dwarf";
    rev = "78b41734545fd9fadd048c0dfcddc848a8b4e68a";
    hash = "sha256-QDuRXTKZyth8U57PCWOjro6YYO4aCEOProMPYSZt3Nw=";
    forceFetchGit = true;
  };

  npmDepsHash = "sha256-29EFrJASkRlvDOR9ZmjsBqOnoBA6hjl3TA/4qap+SnY=";
  
  # Skip npm's build script and run vite directly to avoid type checking
  dontNpmBuild = true;
  
  buildPhase = ''
    runHook preBuild
    
    # Run vite build directly, skip tsc type checking
    npx vite build
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/red-dwarf
    cp -r dist/* $out/share/red-dwarf/

    runHook postInstall
  '';

  meta = with lib; {
    description = "A Bluesky client built with TanStack and Vite";
    homepage = "https://github.com/whey-party/red-dwarf";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
