{ pkgs, craneLib, ... }:

{
  # PDS Gatekeeper - Security microservice for PDS with 2FA and rate limiting
  pds-gatekeeper = pkgs.callPackage ./pds-gatekeeper.nix {
    inherit craneLib;
  };
  
  # Placeholder packages for future Bluesky applications
  # These will be implemented when the actual source repositories are available
  
  # Official Bluesky Frontpage web application (placeholder)
  frontpage = pkgs.writeTextFile {
    name = "bluesky-frontpage-placeholder";
    text = ''
      # Bluesky Frontpage Placeholder
      
      This is a placeholder for the official Bluesky frontpage web application.
      In a real implementation, this would be built from the official Bluesky frontpage repository.
    '';
    
    passthru = {
      atproto = {
        type = "application";
        services = [ "web-app" ];
        protocols = [ "com.atproto" "app.bsky" ];
        schemaVersion = "1.0";
      };
      
      organization = {
        name = "bluesky-social";
        displayName = "Official Bluesky";
        website = "https://bsky.social";
        contact = null;
        maintainer = "Bluesky Social";
        repository = "https://github.com/bluesky-social/frontpage";
        packageCount = 1;
        atprotoFocus = [ "applications" ];
      };
      
      # Deprecation notice
      deprecated = {
        reason = "Legacy placeholder package - use bluesky-social packages instead";
        replacement = "bluesky-social.frontpage";
        since = "2024-10-21";
      };
    };
    
    meta = with pkgs.lib; {
      description = "Official Bluesky web application (placeholder - DEPRECATED)";
      longDescription = ''
        Official Bluesky web application placeholder.
        
        DEPRECATED: This is a legacy placeholder package.
        Use bluesky-social.frontpage instead.
        
        Maintained by Official Bluesky (https://bsky.social)
      '';
      homepage = "https://bsky.social";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
      
      organizationalContext = {
        organization = "bluesky-social";
        displayName = "Official Bluesky";
        needsMigration = true;
        migrationPriority = "low";
      };
    };
  };

  # OAuth implementation (placeholder)
  oauth = pkgs.writeTextFile {
    name = "bluesky-oauth-placeholder";
    text = ''
      # Bluesky OAuth Placeholder
      
      This is a placeholder for the Bluesky OAuth implementation.
      In a real implementation, this would be built from the official Bluesky repository.
    '';
    
    passthru = {
      atproto = {
        type = "library";
        services = [];
        protocols = [ "com.atproto" "oauth" ];
        schemaVersion = "1.0";
      };
      
      organization = {
        name = "bluesky-social";
        displayName = "Official Bluesky";
        website = "https://bsky.social";
        contact = null;
        maintainer = "Bluesky Social";
        repository = "https://github.com/bluesky-social/frontpage";
        packageCount = 1;
        atprotoFocus = [ "libraries" ];
      };
      
      # Deprecation notice
      deprecated = {
        reason = "Legacy placeholder package - use bluesky-social packages instead";
        replacement = "bluesky-social.oauth";
        since = "2024-10-21";
      };
    };
    
    meta = with pkgs.lib; {
      description = "OAuth implementation for Bluesky applications (placeholder - DEPRECATED)";
      longDescription = ''
        OAuth implementation for Bluesky applications placeholder.
        
        DEPRECATED: This is a legacy placeholder package.
        Use bluesky-social.oauth instead.
        
        Maintained by Official Bluesky (https://bsky.social)
      '';
      homepage = "https://bsky.social";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
      
      organizationalContext = {
        organization = "bluesky-social";
        displayName = "Official Bluesky";
        needsMigration = true;
        migrationPriority = "low";
      };
    };
  };

  # ATProto browser client (placeholder)
  browser-client = pkgs.writeTextFile {
    name = "bluesky-browser-client-placeholder";
    text = ''
      # Bluesky Browser Client Placeholder
      
      This is a placeholder for the Bluesky browser client.
      In a real implementation, this would be built from the official Bluesky repository.
    '';
    
    passthru = {
      atproto = {
        type = "library";
        services = [];
        protocols = [ "com.atproto" "app.bsky" ];
        schemaVersion = "1.0";
      };
      
      organization = {
        name = "bluesky-social";
        displayName = "Official Bluesky";
        website = "https://bsky.social";
        contact = null;
        maintainer = "Bluesky Social";
        repository = "https://github.com/bluesky-social/frontpage";
        packageCount = 1;
        atprotoFocus = [ "libraries" "clients" ];
      };
      
      # Deprecation notice
      deprecated = {
        reason = "Legacy placeholder package - use bluesky-social packages instead";
        replacement = "bluesky-social.browser-client";
        since = "2024-10-21";
      };
    };
    
    meta = with pkgs.lib; {
      description = "Browser-based ATProto client for Bluesky (placeholder - DEPRECATED)";
      longDescription = ''
        Browser-based ATProto client for Bluesky placeholder.
        
        DEPRECATED: This is a legacy placeholder package.
        Use bluesky-social.browser-client instead.
        
        Maintained by Official Bluesky (https://bsky.social)
      '';
      homepage = "https://bsky.social";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
      
      organizationalContext = {
        organization = "bluesky-social";
        displayName = "Official Bluesky";
        needsMigration = true;
        migrationPriority = "low";
      };
    };
  };
}
