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
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "teal" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Music social platform";
      status = "planned";
    };
    
    organization = {
      name = "teal-fm";
      displayName = "Teal.fm";
      website = "https://teal.fm";
      contact = null;
      maintainer = "Teal.fm";
      repository = "https://github.com/teal-fm/teal";
      packageCount = 1;
      atprotoFocus = [ "applications" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "Music social platform (planned)";
    longDescription = ''
      Music social platform built on ATProto.
      
      Maintained by Teal.fm (https://teal.fm)
    '';
    homepage = "https://teal.fm";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
    
    organizationalContext = {
      organization = "teal-fm";
      displayName = "Teal.fm";
      needsMigration = false;
      migrationPriority = "low";
    };
  };
}