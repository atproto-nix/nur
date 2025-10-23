{ ... }:

# Official Bluesky modules
# Organization: bluesky-social
# Website: https://bsky.social

{
  imports = [
    # Note: frontpage.nix moved to modules/likeandscribe/frontpage.nix
    # Note: grain-*.nix moved to modules/grain-social/ (different organization)
    ./indigo-hepa.nix
    ./indigo-palomar.nix
    ./indigo-rainbow.nix
    ./indigo-relay.nix
  ];
}