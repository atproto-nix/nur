{ lib
, stdenv
, fetchurl
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
  # Obtained via: nix-prefetch-url "https://registry.npmjs.org/@cloudflare/workerd-PLATFORM/-/workerd-PLATFORM-VERSION.tgz"
  # Format: base32 (directly from nix-prefetch-url output)
  # Note: fetchurl requires hash argument in format: "sha256-base64" or "base32-hash"
  # Since nix-prefetch-url outputs base32, we use it directly
  hashes = {
    x86_64-linux = "00gg0axvl8whqvbl3iqa8yr3spjfny44v0mcl6hcmsm5x78rfsx0";
    aarch64-linux = "0xpcl52h5wfs4ld7fb6q2y9ab6g9dqm9lcpgwvp5cr188zni1pyc";
    x86_64-darwin = "0nmk1v7icgjffv1nwbh6v3n82msdwa6lrnl3h5w25w7m3ah2m0sn";
    aarch64-darwin = "10d1afpgcq7f31aqvmf2mld0chqsjxq3pvrij9z3aqmdwixwypd1";
  };

  # Fetch the workerd binary for the target platform from npm
  workerdBinary = fetchurl {
    url = "https://registry.npmjs.org/@cloudflare/workerd-${npmPlatform}/-/workerd-${npmPlatform}-${version}.tgz";
    # Use hash attribute with base32 format from nix-prefetch-url
    # Format: "sha256:base32hash" (Nix will convert to SRI internally)
    hash = "sha256:" + (hashes.${stdenv.hostPlatform.system} or (throw "no hash for ${stdenv.hostPlatform.system}"));
  };
in
stdenv.mkDerivation rec {
  pname = "workerd";
  inherit version;

  src = workerdBinary;

  nativeBuildInputs = lib.optionals stdenv.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    glibc
    zlib
    openssl
  ];

  sourceRoot = ".";

  unpackPhase = ''
    mkdir -p workerd-extract
    cd workerd-extract
    tar -xzf $src
    cd ..
  '';

  buildPhase = ''
    # workerd npm package contains prebuilt binaries in bin/
    # No building needed, just extraction
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # The npm package unpacks to package/ directory, with binary in bin/
    find workerd-extract -name "workerd" -type f | while read binary; do
      cp "$binary" $out/bin/workerd
      chmod +x $out/bin/workerd
      break
    done

    # If not found, search more broadly
    if [ ! -f $out/bin/workerd ]; then
      find workerd-extract -type f -executable -name "workerd*" | head -1 | xargs -I {} cp {} $out/bin/workerd
      chmod +x $out/bin/workerd
    fi

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
