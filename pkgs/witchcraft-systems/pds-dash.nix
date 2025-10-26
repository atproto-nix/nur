{ pkgs, lib, atprotoLib, deno, nodejs, buildNpmPackage, packageLockJson, ... }:

buildNpmPackage rec {
  pname = "pds-dash";
  version = "1.0";

  src = pkgs.fetchFromGitea {
    domain = "git.witchcraft.systems";
    owner = "scientific-witchery";
    repo = "pds-dash";
    rev = "1.0";
    hash = "sha256-a4ECUtjeC2XW5YyOzV49V+ZhYtgL37Z+YiFH6BNpBbU=";
  };

  npmDepsHash = ""; # Placeholder, will be filled by Nix

  # Use npm ci for reproducible installs and then npm run build
  npmBuild = "npm ci && npm run build";

  # We don't want buildNpmPackage to run its default build,
  # as we're controlling it with npmBuild.
  dontBuild = true;

  nativeBuildInputs = [ deno nodejs ]; # Ensure deno and nodejs are available

  postPatch = ''
    cp ${packageLockJson} $src/package-lock.json
  '';

  installPhase = ''
    echo "Running custom installPhase for copying build output"
    mkdir -p $out/share/${pname}
    cp -r dist/* $out/share/${pname}/
    cp ${src}/config.ts.example $out/share/${pname}/
    cp -r ${src}/themes $out/share/${pname}/
  '';

  # ATProto-specific metadata
  passthru.atproto = atprotoLib.mkAtprotoPackage {
    type = "application";
    services = [];
    protocols = ["com.atproto"];
  };

  meta = with lib; {
    description = "A frontend dashboard with stats for your ATProto PDS.";
    homepage = "https://git.witchcraft.systems/scientific-witchery/pds-dash";
    license = licenses.mit;
    platforms = platforms.all;
  };
}