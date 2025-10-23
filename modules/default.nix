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
    ./bluesky
    ./grain-social
    ./individual
    ./mackuba
    ./whey-party

    # New organizational framework modules
    ./likeandscribe

    # Legacy atproto module (for remaining modules)
    # Note: This will be phased out as packages migrate to new structure

    # Backward compatibility aliases
    ./compatibility.nix
  ];
}