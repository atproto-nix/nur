{ pkgs, ... }:

# Grain Social - Photo-sharing platform built on ATProto (planned package)
pkgs.writeTextFile {
  name = "grain-placeholder";
  text = ''
    # Grain Social Placeholder

    This is a placeholder for Grain Social - a photo-sharing social platform
    built on the AT Protocol by Chad Miller.
    The actual implementation is planned for future development.

    Source: https://tangled.org/@grain.social/grain
    Organization: Grain Social
    Maintainer: Chad Miller

    Components:
    - AppView: Main application server
    - Darkroom: Image processing service
    - Notifications: Notification service
    - Labeler: Content moderation
    - CLI: Command-line interface

    Technologies: Deno, TypeScript, Rust, HTMX

    This package will be implemented when packaging is ready.
  '';

  passthru = {
    atproto = {
      type = "application";
      services = [ "grain-appview" "grain-darkroom" "grain-notifications" "grain-labeler" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Photo-sharing social platform built on ATProto";
      status = "planned";
    };

    organization = {
      name = "grain-social";
      displayName = "Grain Social";
      website = "https://grain.social";
      contact = null;
      maintainer = "Chad Miller";
      repository = "https://tangled.org/@grain.social/grain";
      packageCount = 1;
      atprotoFocus = [ "applications" "media" "social" ];
    };
  };

  meta = with pkgs.lib; {
    description = "Photo-sharing social platform built on ATProto (planned)";
    longDescription = ''
      Grain Social is a photo-sharing platform built on the AT Protocol.
      It allows users to upload photos, organize them into galleries,
      and share them in a decentralized social network.

      The platform consists of multiple microservices:
      - AppView: Main web application
      - Darkroom: Image processing and optimization
      - Notifications: Real-time notification system
      - Labeler: Content moderation service
      - CLI: Command-line management tools

      Built with Deno, TypeScript, Rust, and HTMX.

      Maintained by Chad Miller (https://grain.social)

      This is a planned package for future development.
    '';
    homepage = "https://grain.social";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];

    organizationalContext = {
      organization = "grain-social";
      displayName = "Grain Social";
      needsMigration = false;
      migrationPriority = "low";
    };
  };
}
