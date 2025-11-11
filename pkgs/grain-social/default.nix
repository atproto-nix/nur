{ pkgs, lib, craneLib }:

# Grain Social - Photo-sharing platform on ATProto
# Maintained by Chad Miller
# Repository: https://tangled.org/@grain.social/grain

let
  organizationMeta = {
    name = "grain-social";
    displayName = "Grain Social";
    description = "Photo-sharing platform built on AT Protocol by Chad Miller";
    packageCount = 6; # grain (placeholder), darkroom, cli, appview, labeler, notifications
  };

  packages = {
    # Placeholder for full Grain platform (AppView + all services)
    grain = pkgs.callPackage ./grain.nix { };

    # Darkroom: Image processing and screenshot service (Rust)
    darkroom = pkgs.callPackage ./darkroom.nix { inherit lib craneLib; };

    # CLI: Command-line interface for gallery management (Rust)
    cli = pkgs.callPackage ./cli.nix { inherit lib craneLib; };

    # AppView: Photo gallery web application (Deno/TypeScript)
    appview = pkgs.callPackage ./appview.nix { };

    # Labeler: Content moderation service (Deno/TypeScript)
    labeler = pkgs.callPackage ./labeler.nix { };

    # Notifications: Real-time notification delivery service (Deno/TypeScript)
    notifications = pkgs.callPackage ./notifications.nix { };
  };
in
packages // {
  _organizationMeta = organizationMeta;
}
