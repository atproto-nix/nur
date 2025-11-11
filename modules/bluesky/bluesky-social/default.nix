{ ... }:

# Official Bluesky modules - Indigo services
# Organization: bluesky-social
# Website: https://bsky.social

{
  imports = [
    # Core relay services
    ./indigo-relay.nix      # NEW relay (sync v1.1)
    ./indigo-bigsky.nix     # Original relay with full mirroring
    ./indigo-rainbow.nix    # Firehose fanout/splitter

    # Search & discovery services
    ./indigo-palomar.nix    # Full-text search
    ./indigo-bluepages.nix  # Identity directory/caching
    ./indigo-collectiondir.nix  # Collection discovery

    # Moderation & monitoring services
    ./indigo-hepa.nix       # Auto-moderation
    ./indigo-beemo.nix      # Moderation notifications to Slack
    ./indigo-sonar.nix      # Operational monitoring

    # Operational tools
    ./indigo-netsync.nix    # Repository cloning/archival
  ];
}