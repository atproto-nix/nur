{ pkgs, craneLib, fetchFromGitHub, buildNpmPackage, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../lib/atproto.nix { inherit craneLib; };
in
{
  # Placeholder ATProto core library - demonstrates the structure
  lexicon = pkgs.writeTextFile {
    name = "atproto-lexicon-placeholder";
    text = ''
      # ATProto Lexicon Library Placeholder
      
      This is a placeholder for the ATProto lexicon library.
      In a real implementation, this would be built from the official ATProto repository.
    '';
    
    passthru = atprotoLib.mkAtprotoPackage {
      type = "library";
      services = [];
      protocols = [ "com.atproto" ];
    }.passthru;
    
    meta = with pkgs.lib; {
      description = "ATProto lexicon schema definition and validation library (placeholder)";
      homepage = "https://github.com/bluesky-social/atproto";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
    };
  };

  api = pkgs.writeTextFile {
    name = "atproto-api-placeholder";
    text = ''
      # ATProto API Library Placeholder
      
      This is a placeholder for the ATProto API library.
      In a real implementation, this would be built from the official ATProto repository.
    '';
    
    passthru = atprotoLib.mkAtprotoPackage {
      type = "library";
      services = [];
      protocols = [ "com.atproto" "app.bsky" ];
    }.passthru;
    
    meta = with pkgs.lib; {
      description = "ATProto client API library (placeholder)";
      homepage = "https://github.com/bluesky-social/atproto";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
    };
  };


}