{ pkgs, ... }:

# Grain - Official Bluesky TypeScript implementation (planned package)
pkgs.writeTextFile {
  name = "grain-placeholder";
  text = ''
    # Grain Placeholder
    
    This is a placeholder for Grain - the official Bluesky TypeScript implementation.
    The actual implementation is planned for future development.
    
    Source: https://github.com/bluesky-social/grain
    Organization: Official Bluesky
    Website: https://bsky.social
    
    This package will be implemented when packaging is ready.
  '';
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "grain" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Official Bluesky TypeScript implementation";
      status = "planned";
    };
    
    organization = {
      name = "bluesky-social";
      displayName = "Official Bluesky";
      website = "https://bsky.social";
      contact = null;
      maintainer = "Bluesky Social";
      repository = "https://github.com/bluesky-social/grain";
      packageCount = 2;
      atprotoFocus = [ "infrastructure" "servers" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "Official Bluesky TypeScript implementation (planned)";
    longDescription = ''
      Official Bluesky TypeScript implementation for ATProto services.
      This is a planned package for future development.
      
      Maintained by Official Bluesky (https://bsky.social)
    '';
    homepage = "https://bsky.social";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
    
    organizationalContext = {
      organization = "bluesky-social";
      displayName = "Official Bluesky";
      needsMigration = false;
      migrationPriority = "low";
    };
  };
}