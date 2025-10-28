{ pkgs, lib, craneLib }:

# Grain Social - Photo-sharing platform on ATProto
# Maintained by Chad Miller
# Repository: https://tangled.org/@grain.social/grain

let
  organizationMeta = {
    name = "grain-social";
    displayName = "Grain Social";
    description = "Photo-sharing platform built on AT Protocol by Chad Miller";
    packageCount = 3; # grain (placeholder), darkroom, cli
  };

  packages = {
    # Placeholder for full Grain platform (AppView + all services)
    grain = pkgs.callPackage ./grain.nix { };

    # Darkroom: Image processing and screenshot service
    darkroom = pkgs.callPackage ./darkroom.nix { inherit lib craneLib; };

    # CLI: Command-line interface for gallery management
    cli = pkgs.callPackage ./cli.nix { inherit lib craneLib; };
  };
in
packages // {
  _organizationMeta = organizationMeta;
}
