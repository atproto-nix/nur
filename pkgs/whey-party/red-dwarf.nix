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
    rev = "27ceeb9b32d304033aa46d24d0ec7622a884e240";
    hash = "sha256-UsOt84NsOYxLRlFwWkfFDphRNc4bO7OntcPp7S1jpNI=";
    forceFetchGit = true;
  };

  npmDepsHash = "sha256-jE/HtHGlZeqgLJZMmGg4X05k/nXaCYKZUILUrMAnB+0=";
  
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
