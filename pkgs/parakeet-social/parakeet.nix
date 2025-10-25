{ lib, pkgs, craneLib, fetchgit, ... }:

craneLib.buildPackage rec {
  pname = "parakeet";
  version = "0.1.0"; # Placeholder version, will need to be updated if a release version becomes available

  src = fetchgit {
    url = "https://gitlab.com/parakeet-social/parakeet";
    rev = "HEAD"; # Fetch the latest commit on the default branch
    hash = "sha256-Cv8xHa8psCNBXy5DpQSQw2yJ3Ogae/9d7sj999iDgxU="; # The hash obtained from get_nix_hash.sh
  };

  # Standard Rust environment for ATProto services (assuming it's a Rust project based on search results)
  env = {
    OPENSSL_NO_VENDOR = "1";
    # Add other necessary environment variables if known
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    # Add other native build inputs if known
  ];

  buildInputs = with pkgs; [
    openssl
    sqlite # Assuming sqlite based on other ATProto services
    # Add other build inputs if known
  ];

  # Assuming the main binary is named 'parakeet'
  cargoExtraArgs = "--bin parakeet";

  # Add any postInstall steps if necessary, e.g., copying assets

  passthru = {
    atproto = {
      type = "application";
      services = [ "parakeet" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Bluesky AppView implementation";
      status = "active"; # Change from planned to active
    };

    organization = {
      name = "parakeet-social";
      displayName = "Parakeet Social";
      website = "https://gitlab.com/parakeet-social/parakeet"; # Update website
      contact = null;
      maintainer = "Parakeet Social";
      repository = "https://gitlab.com/parakeet-social/parakeet"; # Update repository
      packageCount = 1;
      atprotoFocus = [ "infrastructure" "servers" ];
    };
  };

  meta = with lib; {
    description = "Bluesky AppView implementation";
    longDescription = ''
      Bluesky AppView implementation for ATProto infrastructure.
      Maintained by Parakeet Social
    '';
    homepage = "https://gitlab.com/parakeet-social/parakeet"; # Update homepage
    license = licenses.mit; # Assuming MIT license
    platforms = platforms.all;
    maintainers = [ ];

    organizationalContext = {
      organization = "parakeet-social";
      displayName = "Parakeet Social";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}