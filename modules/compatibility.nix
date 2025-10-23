# Module Compatibility Aliases
#
# This file provides backward compatibility aliases for modules that have been
# reorganized from their original locations to organizational directories.
# 
# These aliases ensure that existing NixOS configurations continue to work
# during the transition period. Users should migrate to the new organizational
# module paths as documented in the migration guide.

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkEnableOption mkIf types mkRenamedOptionModule;
  
  # Helper function to create a deprecation warning
  mkDeprecationWarning = oldPath: newPath: 
    "The module option '${oldPath}' is deprecated. Please use '${newPath}' instead. " +
    "See the migration guide for more information.";

in
{
  # Import renamed option modules for backward compatibility
  imports = [
    # ATProto module aliases - services moved from atproto/ to organizational directories
    
    # Slices Network modules (moved from atproto/)  
    (mkRenamedOptionModule [ "services" "atproto-slices" ] [ "services" "slices-network-slices" ])
    
    # Teal.fm modules (moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-teal" ] [ "services" "teal-fm-teal" ])
    
    # Parakeet Social modules (moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-parakeet" ] [ "services" "parakeet-social-parakeet" ])
    
    # Stream.place modules (moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-streamplace" ] [ "services" "stream-place-streamplace" ])
    
    # Yoten App modules (moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-yoten" ] [ "services" "yoten-app-yoten" ])
    
    # Red Dwarf Client modules (moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-red-dwarf" ] [ "services" "red-dwarf-client-red-dwarf" ])
    
    # Smokesignal Events modules (moved from atproto/)
    # Note: quickdid currently uses services.quickdid, will be renamed to services.smokesignal-events-quickdid
    (mkRenamedOptionModule [ "services" "atproto-quickdid" ] [ "services" "smokesignal-events-quickdid" ])
    
    # Microcosm Blue modules (allegedly moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-allegedly" ] [ "services" "microcosm-blue-allegedly" ])
    
    # ATBackup modules (moved from atproto/)
    (mkRenamedOptionModule [ "services" "atproto-atbackup" ] [ "services" "atbackup-pages-dev-atbackup" ])
    
    # Official Bluesky Indigo modules (moved from atproto/ to bluesky-social/)
    (mkRenamedOptionModule [ "services" "atproto-indigo-hepa" ] [ "services" "bluesky-social-indigo-hepa" ])
    (mkRenamedOptionModule [ "services" "atproto-indigo-palomar" ] [ "services" "bluesky-social-indigo-palomar" ])
    (mkRenamedOptionModule [ "services" "atproto-indigo-rainbow" ] [ "services" "bluesky-social-indigo-rainbow" ])
    (mkRenamedOptionModule [ "services" "atproto-indigo-relay" ] [ "services" "bluesky-social-indigo-relay" ])

    # Grain Social modules (moved from atproto/ to grain-social/)
    (mkRenamedOptionModule [ "services" "atproto-grain-appview" ] [ "services" "grain-social-grain-appview" ])
    (mkRenamedOptionModule [ "services" "atproto-grain-darkroom" ] [ "services" "grain-social-grain-darkroom" ])
    (mkRenamedOptionModule [ "services" "atproto-grain-labeler" ] [ "services" "grain-social-grain-labeler" ])
    (mkRenamedOptionModule [ "services" "atproto-grain-notifications" ] [ "services" "grain-social-grain-notifications" ])
    
    # Bluesky module aliases - services moved from bluesky/ to organizational directories
    
    # Witchcraft Systems modules (moved from bluesky/)
    # Note: pds-dash currently uses services.bluesky.pds-dash, will be renamed to services.witchcraft-systems-pds-dash
    (mkRenamedOptionModule [ "services" "bluesky" "pds-dash" ] [ "services" "witchcraft-systems-pds-dash" ])
    
    # Individual developer modules (moved from bluesky/)
    (mkRenamedOptionModule [ "services" "bluesky-pds-gatekeeper" ] [ "services" "individual-pds-gatekeeper" ])
    
    # Bluesky Social modules (moved from bluesky/ to bluesky-social/)
    (mkRenamedOptionModule [ "services" "bluesky-frontpage" ] [ "services" "bluesky-social-frontpage" ])

    # Phase 3 module consolidation (2025-10-22)
    # Frontpage: corrected to likeandscribe organization
    (mkRenamedOptionModule [ "services" "atproto" "frontpage" ] [ "services" "likeandscribe" "frontpage" ])
    (mkRenamedOptionModule [ "services" "bluesky-social" "frontpage" ] [ "services" "likeandscribe" "frontpage" ])

    # Drainpipe: moved to likeandscribe (part of frontpage monorepo)
    (mkRenamedOptionModule [ "services" "atproto" "drainpipe" ] [ "services" "likeandscribe" "drainpipe" ])
    (mkRenamedOptionModule [ "services" "individual" "drainpipe" ] [ "services" "likeandscribe" "drainpipe" ])
    
    # Additional legacy aliases for services that may have used different naming patterns
    
        # Legacy atproto service aliases (for services that might have been named differently)
    (mkRenamedOptionModule [ "services" "slices" ] [ "services" "slices-network-slices" ])
    (mkRenamedOptionModule [ "services" "teal" ] [ "services" "teal-fm-teal" ])
    (mkRenamedOptionModule [ "services" "parakeet" ] [ "services" "parakeet-social-parakeet" ])
    (mkRenamedOptionModule [ "services" "streamplace" ] [ "services" "stream-place-streamplace" ])
    (mkRenamedOptionModule [ "services" "yoten" ] [ "services" "yoten-app-yoten" ])
    (mkRenamedOptionModule [ "services" "red-dwarf" ] [ "services" "red-dwarf-client-red-dwarf" ])

    (mkRenamedOptionModule [ "services" "quickdid" ] [ "services" "smokesignal-events-quickdid" ])
    (mkRenamedOptionModule [ "services" "allegedly" ] [ "services" "microcosm-blue-allegedly" ])
    (mkRenamedOptionModule [ "services" "atbackup" ] [ "services" "atbackup-pages-dev-atbackup" ])
    (mkRenamedOptionModule [ "services" "pds-dash" ] [ "services" "witchcraft-systems-pds-dash" ])
    (mkRenamedOptionModule [ "services" "pds-gatekeeper" ] [ "services" "individual-pds-gatekeeper" ])
  ];
  
  # Deprecation warnings for users still using old service names
  warnings = lib.flatten [
    # ATProto module deprecation warnings
    (lib.optional (config.services ? atproto-slices) 
      (mkDeprecationWarning "services.atproto-slices" "services.slices-network-slices"))
    (lib.optional (config.services ? atproto-teal) 
      (mkDeprecationWarning "services.atproto-teal" "services.teal-fm-teal"))
    (lib.optional (config.services ? atproto-parakeet) 
      (mkDeprecationWarning "services.atproto-parakeet" "services.parakeet-social-parakeet"))
    (lib.optional (config.services ? atproto-streamplace) 
      (mkDeprecationWarning "services.atproto-streamplace" "services.stream-place-streamplace"))
    (lib.optional (config.services ? atproto-yoten) 
      (mkDeprecationWarning "services.atproto-yoten" "services.yoten-app-yoten"))
    (lib.optional (config.services ? atproto-red-dwarf) 
      (mkDeprecationWarning "services.atproto-red-dwarf" "services.red-dwarf-client-red-dwarf"))
    (lib.optional (config.services ? atproto-appview) 
      (mkDeprecationWarning "services.atproto-appview" "services.tangled-dev-appview"))
    (lib.optional (config.services ? atproto-knot) 
      (mkDeprecationWarning "services.atproto-knot" "services.tangled-dev-knot"))
    (lib.optional (config.services ? atproto-spindle) 
      (mkDeprecationWarning "services.atproto-spindle" "services.tangled-dev-spindle"))
    (lib.optional (config.services ? atproto-quickdid) 
      (mkDeprecationWarning "services.atproto-quickdid" "services.smokesignal-events-quickdid"))
    (lib.optional (config.services ? atproto-allegedly) 
      (mkDeprecationWarning "services.atproto-allegedly" "services.microcosm-blue-allegedly"))
    (lib.optional (config.services ? atproto-atbackup) 
      (mkDeprecationWarning "services.atproto-atbackup" "services.atbackup-pages-dev-atbackup"))
    
    # Legacy service name deprecation warnings
    (lib.optional (config.services ? slices) 
      (mkDeprecationWarning "services.slices" "services.slices-network-slices"))
    (lib.optional (config.services ? teal) 
      (mkDeprecationWarning "services.teal" "services.teal-fm-teal"))
    (lib.optional (config.services ? parakeet) 
      (mkDeprecationWarning "services.parakeet" "services.parakeet-social-parakeet"))
    (lib.optional (config.services ? streamplace) 
      (mkDeprecationWarning "services.streamplace" "services.stream-place-streamplace"))
    (lib.optional (config.services ? yoten) 
      (mkDeprecationWarning "services.yoten" "services.yoten-app-yoten"))
    (lib.optional (config.services ? red-dwarf) 
      (mkDeprecationWarning "services.red-dwarf" "services.red-dwarf-client-red-dwarf"))
    (lib.optional (config.services ? appview) 
      (mkDeprecationWarning "services.appview" "services.tangled-dev-appview"))
    (lib.optional (config.services ? knot) 
      (mkDeprecationWarning "services.knot" "services.tangled-dev-knot"))
    (lib.optional (config.services ? spindle) 
      (mkDeprecationWarning "services.spindle" "services.tangled-dev-spindle"))
    (lib.optional (config.services ? quickdid) 
      (mkDeprecationWarning "services.quickdid" "services.smokesignal-events-quickdid"))
    (lib.optional (config.services ? allegedly) 
      (mkDeprecationWarning "services.allegedly" "services.microcosm-blue-allegedly"))
    (lib.optional (config.services ? atbackup) 
      (mkDeprecationWarning "services.atbackup" "services.atbackup-pages-dev-atbackup"))
    (lib.optional (config.services ? pds-dash) 
      (mkDeprecationWarning "services.pds-dash" "services.witchcraft-systems-pds-dash"))
    (lib.optional (config.services ? pds-gatekeeper) 
      (mkDeprecationWarning "services.pds-gatekeeper" "services.individual-pds-gatekeeper"))
    
    # Bluesky module deprecation warnings
    (lib.optional (config.services ? bluesky-pds-gatekeeper) 
      (mkDeprecationWarning "services.bluesky-pds-gatekeeper" "services.individual-pds-gatekeeper"))
    (lib.optional (config.services ? bluesky-frontpage) 
      (mkDeprecationWarning "services.bluesky-frontpage" "services.bluesky-social-frontpage"))
    (lib.optional (config.services.bluesky or {} ? pds-dash) 
      (mkDeprecationWarning "services.bluesky.pds-dash" "services.witchcraft-systems-pds-dash"))
      
    # Official Bluesky Indigo service deprecation warnings
    (lib.optional (config.services ? atproto-indigo-hepa)
      (mkDeprecationWarning "services.atproto-indigo-hepa" "services.bluesky-social-indigo-hepa"))
    (lib.optional (config.services ? atproto-indigo-palomar)
      (mkDeprecationWarning "services.atproto-indigo-palomar" "services.bluesky-social-indigo-palomar"))
    (lib.optional (config.services ? atproto-indigo-rainbow)
      (mkDeprecationWarning "services.atproto-indigo-rainbow" "services.bluesky-social-indigo-rainbow"))
    (lib.optional (config.services ? atproto-indigo-relay)
      (mkDeprecationWarning "services.atproto-indigo-relay" "services.bluesky-social-indigo-relay"))

    # Grain Social service deprecation warnings
    (lib.optional (config.services ? atproto-grain-appview)
      (mkDeprecationWarning "services.atproto-grain-appview" "services.grain-social-grain-appview"))
    (lib.optional (config.services ? atproto-grain-darkroom)
      (mkDeprecationWarning "services.atproto-grain-darkroom" "services.grain-social-grain-darkroom"))
    (lib.optional (config.services ? atproto-grain-labeler)
      (mkDeprecationWarning "services.atproto-grain-labeler" "services.grain-social-grain-labeler"))
    (lib.optional (config.services ? atproto-grain-notifications)
      (mkDeprecationWarning "services.atproto-grain-notifications" "services.grain-social-grain-notifications"))

    # Phase 3 module consolidation deprecation warnings (2025-10-22)
    (lib.optional (config.services.atproto or {} ? frontpage)
      (mkDeprecationWarning "services.atproto.frontpage" "services.likeandscribe.frontpage"))
    (lib.optional (config.services.bluesky-social or {} ? frontpage)
      (mkDeprecationWarning "services.bluesky-social.frontpage" "services.likeandscribe.frontpage"))
    (lib.optional (config.services.atproto or {} ? drainpipe)
      (mkDeprecationWarning "services.atproto.drainpipe" "services.likeandscribe.drainpipe"))
    (lib.optional (config.services.individual or {} ? drainpipe)
      (mkDeprecationWarning "services.individual.drainpipe" "services.likeandscribe.drainpipe"))
  ];
}