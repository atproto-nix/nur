{ pkgs, ... }:

# Teal - Music social platform (planned package)
pkgs.writeTextFile {
  name = "teal-placeholder";
  text = ''
    # Teal Placeholder
    
    This is a placeholder for Teal - a music social platform.
    The actual implementation is planned for future development.
    
    Source: https://github.com/teal-fm/teal
    Organization: Teal.fm
    Website: https://teal.fm
    
    This package will be implemented when the source repository becomes available.
  '';
  
  passthru.atproto = {
    type = "application";
    services = [ "teal" ];
    protocols = [ "com.atproto" "app.bsky" ];
    schemaVersion = "1.0";
    description = "Music social platform";
    status = "planned";
  };
  
  meta = with pkgs.lib; {
    description = "Music social platform (planned)";
    homepage = "https://github.com/teal-fm/teal";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}