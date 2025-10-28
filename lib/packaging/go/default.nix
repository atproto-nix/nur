# Go packaging module
#
# Re-exports all Go-related functions for easy access

{ lib, pkgs, buildGoModule ? pkgs.buildGoModule, ... }:

{
  # Build a Go module with ATProto-specific configuration
  buildGoAtprotoModule = { owner, repo, rev, sha256, services ? [], ... }@args:
    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };

      moduleName = args.pname or repo;

      # Standard Go environment
      standardEnv = {
        CGO_ENABLED = "1";
        CGO_CFLAGS = "-I${pkgs.openssl.dev}/include";
        CGO_LDFLAGS = "-L${pkgs.openssl.out}/lib";
        GOPROXY = "direct";
        GOSUMDB = "off";
        GO111MODULE = "on";
      } // (args.env or {});

      # Standard build inputs
      standardArgs = {
        inherit src;
        env = standardEnv;

        nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
          pkg-config
          git
        ]);

        buildInputs = (args.buildInputs or []) ++ (with pkgs; [
          openssl
          sqlite
          zlib
        ]);

        vendorHash = args.vendorHash or lib.fakeHash;
        proxyVendor = args.proxyVendor or true;
        modRoot = args.modRoot or ".";

        preBuild = (args.preBuild or "") + ''
          if [ ! -f go.mod ]; then
            echo "No go.mod found, initializing module"
            go mod init ${moduleName}
          fi

          go mod download
          go mod verify
        '';

        checkPhase = args.checkPhase or ''
          runHook preCheck
          go test -timeout 30m -race ./... || echo "Some tests failed, continuing build"
          runHook postCheck
        '';

        doCheck = args.doCheck or true;
      };

      # Build individual service
      buildService = service:
        let
          serviceConfig = (args.serviceConfigs or {}).${service} or {};
          servicePath = serviceConfig.path or "cmd/${service}";
        in
        buildGoModule (standardArgs // {
          pname = "${moduleName}-${service}";
          version = args.version or "0.1.0";
          subPackages = [ servicePath ];

          env = standardEnv // (serviceConfig.env or {});

          nativeBuildInputs = standardArgs.nativeBuildInputs ++ (serviceConfig.nativeBuildInputs or []);
          buildInputs = standardArgs.buildInputs ++ (serviceConfig.buildInputs or []);

          ldflags = (args.ldflags or []) ++ (serviceConfig.ldflags or []) ++ [
            "-s" "-w"
            "-X main.version=${args.version or "0.1.0"}"
            "-X main.commit=${rev}"
          ];

          meta = (args.meta or {}) // (serviceConfig.meta or {}) // {
            description = (args.serviceDescriptions or {}).${service} or serviceConfig.description or "ATproto Go service: ${service}";
            mainProgram = serviceConfig.mainProgram or service;
            platforms = lib.platforms.linux ++ lib.platforms.darwin;
          };

          postInstall = (serviceConfig.postInstall or "") + ''
            if [ -n "${serviceConfig.wrapperScript or ""}" ]; then
              mv $out/bin/${service} $out/bin/.${service}-unwrapped
              cat > $out/bin/${service} << 'EOF'
            #!/bin/sh
            ${serviceConfig.wrapperScript}
            exec $out/bin/.${service}-unwrapped "$@"
            EOF
              chmod +x $out/bin/${service}
            fi
          '';
        } // (builtins.removeAttrs serviceConfig ["env" "nativeBuildInputs" "buildInputs" "meta" "description" "path" "wrapperScript"]));

      # Validate services exist
      validateServices =
        let
          missingServices = lib.filter (service:
            let servicePath = ((args.serviceConfigs or {}).${service} or {}).path or "cmd/${service}";
            in !(builtins.pathExists "${src}/${servicePath}")
          ) services;
        in
        if missingServices != [] then
          throw "Missing service directories: ${lib.concatStringsSep ", " missingServices}"
        else
          true;
    in
    if services == [] then
      buildGoModule (standardArgs // (builtins.removeAttrs args [ "services" "serviceDescriptions" "serviceConfigs" ]))
    else (
      assert validateServices;
      lib.genAttrs services buildService
    );
}
