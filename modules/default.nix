{ pkgs, ... }:

{
  imports = [
    # Existing organizational modules
    ./microcosm
    ./blacksky
    ./bluesky
    
    # New organizational modules
    ./hyperlink-academy
    ./slices-network
    ./teal-fm
    ./parakeet-social
    ./stream-place
    ./yoten-app
    ./red-dwarf-client
    ./tangled
    ./smokesignal-events
    ./microcosm-blue
    ./witchcraft-systems
    ./atbackup-pages-dev
    ./bluesky-social
    ./individual
    
    # New organizational framework modules
    ./atproto
    ./individual
    ./likeandscribe
    
    # Legacy atproto module (for remaining modules)
    # Note: This will be phased out as packages migrate to new structure
    
    # Backward compatibility aliases
    ./compatibility.nix
    
    # Profiles
    ../profiles
  ];
}