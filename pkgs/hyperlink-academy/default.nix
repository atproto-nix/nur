{ pkgs, lib, ... }:

# Hyperlink Academy ATProto packages
# Organization: hyperlink-academy
# Website: https://hyperlink.academy
# Contact: contact@leaflet.pub

let
  # Organizational metadata
  organizationMeta = {
    name = "hyperlink-academy";
    displayName = "Hyperlink Academy";
    website = "https://hyperlink.academy";
    contact = "contact@leaflet.pub";
    maintainer = "Learning Futures Inc.";
    description = "Educational technology company building collaborative learning tools on ATProto";
    atprotoFocus = [ "applications" "tools" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    leaflet = pkgs.callPackage ./leaflet.nix { };
  };

in
packages // {
  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}