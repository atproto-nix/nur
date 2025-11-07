{ pkgs, lib, buildGoModule, fetchFromGitHub, ... }:

# Indigo - Official Bluesky ATProto services
# Complete collection of all production services from github.com/bluesky-social/indigo
let
  # Common source and build configuration
  indigoSrc = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "indigo";
    rev = "0b4bd2478a617cc6855683786a2144ad494256fc";
    hash = "sha256-JRzjZ46SFu+tp/sA1rmN6Oj3LYMGdyVqhb1c4jvzyV4=";
  };

  indigoVendorHash = "sha256-9hKOHJzG7YWW/ZN8xF8Z6JsR506fiNTzeeGqSy/oCGc=";

  # Build individual service from indigo source
  buildIndigoService = { subPackage, name, description }:
    buildGoModule {
      pname = "indigo-${name}";
      version = "unstable";

      src = indigoSrc;
      vendorHash = indigoVendorHash;

      # Build the specific service
      subPackages = [ "cmd/${subPackage}" ];

      meta = with lib; {
        inherit description;
        homepage = "https://github.com/bluesky-social/indigo";
        license = licenses.mit;
        platforms = platforms.all;
        maintainers = [ ];
      };
    };

  # ============================================================================
  # Core Relay Services
  # ============================================================================

  relay = buildIndigoService {
    subPackage = "relay";
    name = "relay";
    description = "Official Bluesky ATProto Relay (sync v1.1) - subscribes to PDS hosts and outputs combined firehose";
  };

  bigsky = buildIndigoService {
    subPackage = "bigsky";
    name = "bigsky";
    description = "Indigo BigSky - original relay implementation with full repo mirroring and CAR storage";
  };

  rainbow = buildIndigoService {
    subPackage = "rainbow";
    name = "rainbow";
    description = "Indigo Rainbow - firehose fanout/splitter service for distributing events";
  };

  # ============================================================================
  # Search & Discovery Services
  # ============================================================================

  palomar = buildIndigoService {
    subPackage = "palomar";
    name = "palomar";
    description = "Indigo Palomar - full-text search service for posts and profiles";
  };

  bluepages = buildIndigoService {
    subPackage = "bluepages";
    name = "bluepages";
    description = "Indigo Bluepages - identity directory service that caches handle/DID resolution";
  };

  collectiondir = buildIndigoService {
    subPackage = "collectiondir";
    name = "collectiondir";
    description = "Indigo CollectionDir - collection directory service for discovering which DIDs have data";
  };

  # ============================================================================
  # Moderation & Monitoring Services
  # ============================================================================

  hepa = buildIndigoService {
    subPackage = "hepa";
    name = "hepa";
    description = "Indigo Hepa - auto-moderation service for Ozone";
  };

  beemo = buildIndigoService {
    subPackage = "beemo";
    name = "beemo";
    description = "Indigo Beemo - sends moderation reports to Slack";
  };

  sonar = buildIndigoService {
    subPackage = "sonar";
    name = "sonar";
    description = "Indigo Sonar - operational monitoring and metrics for firehose events";
  };

  # ============================================================================
  # Operational Tools
  # ============================================================================

  netsync = buildIndigoService {
    subPackage = "netsync";
    name = "netsync";
    description = "Indigo NetSync - clone repos from relay/PDS to local disk for archival";
  };

  gosky = buildIndigoService {
    subPackage = "gosky";
    name = "gosky";
    description = "Indigo GoSky - CLI client tool for interacting with ATProto services";
  };

in relay // {
  # Re-export all services
  inherit relay bigsky rainbow palomar bluepages collectiondir hepa beemo sonar netsync gosky;

  passthru = {
    atproto = {
      type = "services";
      services = [ "relay" "bigsky" "rainbow" "palomar" "bluepages" "collectiondir" "hepa" "beemo" "sonar" "netsync" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Official Bluesky ATProto services collection";
      status = "active";
    };

    organization = {
      name = "bluesky-social";
      displayName = "Official Bluesky";
      website = "https://bsky.social";
      contact = null;
      maintainer = "Bluesky Social";
      repository = "https://github.com/bluesky-social/indigo";
      packageCount = 10;
      atprotoFocus = [ "infrastructure" "services" ];
    };
  };
}