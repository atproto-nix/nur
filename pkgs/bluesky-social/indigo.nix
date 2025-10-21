{ pkgs, ... }:

# Indigo - Official Bluesky Go implementation (planned package)
pkgs.writeTextFile {
  name = "indigo-placeholder";
  text = ''
    # Indigo Placeholder
    
    This is a placeholder for Indigo - the official Bluesky Go implementation.
    The actual implementation is planned for future development.
    
    Source: https://github.com/bluesky-social/indigo
    Organization: Official Bluesky
    Website: https://bsky.social
    
    This package will be implemented when packaging is ready.
  '';
  
  passthru.atproto = {
    type = "application";
    services = [ "indigo" ];
    protocols = [ "com.atproto" "app.bsky" ];
    schemaVersion = "1.0";
    description = "Official Bluesky Go implementation";
    status = "planned";
  };
  
  meta = with pkgs.lib; {
    description = "Official Bluesky Go implementation (planned)";
    homepage = "https://github.com/bluesky-social/indigo";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}