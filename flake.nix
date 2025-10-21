{
  description = "ATproto NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      crane,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (
      system:
      let
        overlays = [
          (import rust-overlay)
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustVersion = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
        
        nurOverlay = final: prev: {
          nur = import ./default.nix {
            pkgs = final;
            inherit craneLib;
          };
        };
        
        # Apply the NUR overlay to get our packages
        pkgsWithNur = pkgs.extend nurOverlay;
        
        # Organizational mapping for backward compatibility
        organizationalMapping = import ./lib/organizational-mapping.nix { inherit (pkgs) lib; };
        
        allPackages = 
          let
            # Check if a package is a valid derivation or ATProto package
            isPackage = pkg: 
              (pkg.type or "" == "derivation") ||  # Regular Nix derivations
              (pkg ? atproto) ||                   # ATProto packages with metadata
              (pkg ? passthru.atproto);            # ATProto packages with passthru metadata
            
            # Check if a package is supported on current platform
            isPlatformSupported = pkg:
              let
                meta = pkg.meta or {};
                platforms = meta.platforms or pkgs.lib.platforms.all;
                badPlatforms = meta.badPlatforms or [];
              in
              (builtins.elem system platforms) && !(builtins.elem system badPlatforms);
            
            # Get all packages from the NUR overlay
            nurPackages = pkgsWithNur.nur;
            
            # Filter out non-package attributes (lib, organizations, organizationalMetadata)
            basePackages = pkgs.lib.filterAttrs (n: v: 
              n != "lib" && 
              n != "organizations" && 
              n != "_organizationalMetadata" &&
              isPackage v && 
              isPlatformSupported v
            ) nurPackages;
            
            # Create deprecation wrapper for old package names
            wrapWithDeprecation = oldName: newName: package:
              if package == null then null
              else pkgs.lib.warn 
                "Package '${oldName}' is deprecated. Use '${newName}' instead. See migration guide at: https://github.com/ATProto-NUR/atproto-nur/blob/main/docs/MIGRATION.md"
                package;
            
            # Create backward compatibility aliases with deprecation warnings
            backwardCompatibilityAliases = 
              let
                # Get packages that were moved and need aliases
                movedPackages = organizationalMapping.getPackagesToMove;
                
                # Create aliases for each moved package
                createAlias = packageName: packageInfo:
                  let
                    # Extract old package name from current path
                    oldName = packageName;
                    # Create new prefixed name
                    newName = "${packageInfo.organization}-${packageName}";
                    # Get the actual package from base packages
                    package = basePackages.${newName} or basePackages.${oldName} or null;
                  in
                  if package != null then {
                    ${oldName} = wrapWithDeprecation oldName newName package;
                  } else {};
                
                # Generate all aliases
                allAliases = pkgs.lib.foldl' (acc: alias: acc // alias) {} 
                  (pkgs.lib.mapAttrsToList createAlias movedPackages);
                
              in
              # Filter out null packages
              pkgs.lib.filterAttrs (n: v: v != null) allAliases;
            
          in
          basePackages // backwardCompatibilityAliases;
      in
      {
        packages = allPackages;
        
        # ATProto packaging utilities library
        lib = pkgsWithNur.nur.lib;
        
        nixosModules = {
          # Legacy module collections (for backward compatibility)
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
          bluesky = import ./modules/bluesky;
          atproto = import ./modules/atproto;
          
          # New organizational module collections
          hyperlink-academy = import ./modules/hyperlink-academy;
          slices-network = import ./modules/slices-network;
          teal-fm = import ./modules/teal-fm;
          parakeet-social = import ./modules/parakeet-social;
          stream-place = import ./modules/stream-place;
          yoten-app = import ./modules/yoten-app;
          red-dwarf-client = import ./modules/red-dwarf-client;
          tangled-dev = import ./modules/tangled-dev;
          smokesignal-events = import ./modules/smokesignal-events;
          microcosm-blue = import ./modules/microcosm-blue;
          witchcraft-systems = import ./modules/witchcraft-systems;
          atbackup-pages-dev = import ./modules/atbackup-pages-dev;
          bluesky-social = import ./modules/bluesky-social;
          individual = import ./modules/individual;
          
          # Profiles and defaults
          profiles = import ./profiles;
          default = import ./modules;
        };
        homeManagerModules = {
          # Legacy module collections (for backward compatibility)
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
          bluesky = import ./modules/bluesky;
          atproto = import ./modules/atproto;
          
          # New organizational module collections
          hyperlink-academy = import ./modules/hyperlink-academy;
          slices-network = import ./modules/slices-network;
          teal-fm = import ./modules/teal-fm;
          parakeet-social = import ./modules/parakeet-social;
          stream-place = import ./modules/stream-place;
          yoten-app = import ./modules/yoten-app;
          red-dwarf-client = import ./modules/red-dwarf-client;
          tangled-dev = import ./modules/tangled-dev;
          smokesignal-events = import ./modules/smokesignal-events;
          microcosm-blue = import ./modules/microcosm-blue;
          witchcraft-systems = import ./modules/witchcraft-systems;
          atbackup-pages-dev = import ./modules/atbackup-pages-dev;
          bluesky-social = import ./modules/bluesky-social;
          individual = import ./modules/individual;
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ deadnix nixpkgs-fmt ];
        };
        tests = import ./tests { inherit pkgs; };
      }
    ) // {
      # Flake templates for creating new ATProto packages
      templates = {
        rust-atproto = {
          path = ./templates/rust-atproto;
          description = "ATProto Rust service template with comprehensive NixOS module";
          welcomeText = ''
            # ATProto Rust Service Template

            You have created a new ATProto Rust service template with:
            - Axum web server with async/await support
            - Comprehensive error handling and logging
            - NixOS module with security hardening
            - ATProto integration patterns

            ## Next steps:
            1. Replace 'my-atproto-service' with your service name in:
               - Cargo.toml, flake.nix, src/main.rs
            2. Update ATProto metadata (type, services, protocols)
            3. Enter development environment: `nix develop`
            4. Run the service: `cargo run`
            5. Test NixOS module: `nix build .#nixosConfigurations.test`

            See README.md for detailed instructions and examples.
          '';
        };

        nodejs-atproto = {
          path = ./templates/nodejs-atproto;
          description = "ATProto Node.js/TypeScript service template with web frontend support";
          welcomeText = ''
            # ATProto Node.js Service Template

            You have created a new ATProto Node.js/TypeScript service template with:
            - Express.js server with TypeScript support
            - ATProto SDK integration and XRPC setup
            - Web frontend asset building
            - NixOS module with security hardening
            - Comprehensive testing with Jest

            ## Next steps:
            1. Replace 'my-atproto-node-service' with your service name in:
               - package.json, flake.nix, src/index.ts
            2. Update ATProto metadata (type, services, protocols)
            3. Enter development environment: `nix develop`
            4. Install dependencies: `npm install`
            5. Run the service: `npm run dev`
            6. Test NixOS module: `nix build .#nixosConfigurations.test`

            See README.md for detailed instructions and deployment examples.
          '';
        };

        go-atproto = {
          path = ./templates/go-atproto;
          description = "ATProto Go service template with CLI and web server support";
          welcomeText = ''
            # ATProto Go Service Template

            You have created a new ATProto Go service template with:
            - Gorilla Mux HTTP router and Cobra CLI framework
            - Viper configuration management
            - ATProto integration patterns
            - NixOS module with security hardening
            - Standard library focus with minimal dependencies

            ## Next steps:
            1. Replace 'my-atproto-go-service' with your service name in:
               - go.mod, flake.nix, main.go
            2. Update ATProto metadata (type, services, protocols)
            3. Enter development environment: `nix develop`
            4. Initialize modules: `go mod tidy`
            5. Run the service: `go run .`
            6. Test NixOS module: `nix build .#nixosConfigurations.test`

            See README.md for detailed instructions and CLI usage examples.
          '';
        };
      };
    };
}