{ pkgs, ... }:

# Grain Social - Photo-sharing platform on ATProto
# Maintained by Chad Miller
# Repository: https://tangled.org/@grain.social/grain

{
  grain = pkgs.callPackage ./grain.nix { };
}
