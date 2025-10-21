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
  
  passthru.atproto = {
    type = "application";
    services = [ "grain" ];
    protocols = [ "com.atproto" "app.bsky" ];
    schemaVersion = "1.0";
    description = "Official Bluesky TypeScript implementation";
    status = "planned";
  };
  
  meta = with pkgs.lib; {
    description = "Official Bluesky TypeScript implementation (planned)";
    homepage = "https://github.com/bluesky-social/grain";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}