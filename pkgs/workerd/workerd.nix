{ lib
, stdenv
, fetchurl
, unzip
, autoPatchelfHook
, glibc
, zlib
, openssl
}:

let
  # Map system to npm package name
  systemMap = {
    x86_64-linux = "linux-64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-64";
    aarch64-darwin = "darwin-arm64";
  };

  # workerd version (matches npm package version)
  version = "1.20251106.1";

  # Get the npm platform suffix for current system
  npmPlatform = systemMap.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");

  # Hashes for workerd binaries on different platforms
  # To update: nix-prefetch-url "https://registry.npmjs.org/@cloudflare/workerd-PLATFORM/-/workerd-PLATFORM-VERSION.tgz"
  hashes = {
    x86_64-linux = "sha256-uxyz+oWHRsyuMlSWQ2jLkNt5qQczLcKPj5dxmXv6Wpo=";      # TODO: Calculate
    aarch64-linux = "sha256-1234567890abcdef1234567890abcdef1234567890=";   # TODO: Calculate
    x86_64-darwin = "sha256-1234567890abcdef1234567890abcdef1234567890=";   # TODO: Calculate
    aarch64-darwin = "sha256-1234567890abcdef1234567890abcdef1234567890=";  # TODO: Calculate (darwin-arm64)
  };

  # Fetch the workerd binary for the target platform from npm
  workerdBinary = fetchurl {
    url = "https://registry.npmjs.org/@cloudflare/workerd-${npmPlatform}/-/workerd-${npmPlatform}-${version}.tgz";
    hash = hashes.${stdenv.hostPlatform.system} or (throw "no hash for ${stdenv.hostPlatform.system}");
  };
in
stdenv.mkDerivation rec {
  pname = "workerd";
  inherit version;

  src = workerdBinary;

  nativeBuildInputs = [
    unzip
  ] ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    glibc
    zlib
    openssl
  ];

  sourceRoot = ".";

  unpackPhase = ''
    ${unzip}/bin/unzip -q $src
  '';

  buildPhase = ''
    # workerd npm package contains prebuilt binaries in bin/
    # No building needed, just extraction
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Extract the workerd binary from the npm package
    find . -name "workerd" -type f -executable | while read binary; do
      cp "$binary" $out/bin/workerd
      chmod +x $out/bin/workerd
      break
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Cloudflare's JavaScript/Wasm Runtime - workerd";
    longDescription = ''
      workerd is a JavaScript/Wasm server runtime based on the same code that
      powers Cloudflare Workers. It allows running Cloudflare Workers code
      outside of the Cloudflare platform.

      This package enables self-hosting of Worker-based services like the
      Tangled avatar service.
    '';
    homepage = "https://github.com/cloudflare/workerd";
    license = licenses.asl20;
    platforms = lib.attrNames systemMap;
    maintainers = [];
    mainProgram = "workerd";
  };
}
