{ lib, buildBazelPackage, fetchFromGitHub, bazel, clang_19, libcxx_19, lld_19, python3, tcl }:

buildBazelPackage rec {
  pname = "workerd";
  version = "unstable-2023-10-26"; # This can be updated to a specific release tag

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "workerd";
    rev = "main"; # Or a specific commit hash
    # The sha256 hash will need to be calculated
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Placeholder
  };

  nativeBuildInputs = [ bazel ];
  buildInputs = [ clang_19 libcxx_19 lld_19 python3 tcl ];

  bazelFlags = [
    "--config=thin-lto"
  ];

  buildTarget = "//src/workerd/server:workerd";

  installPhase = ''
    install -Dm755 bazel-bin/src/workerd/server/workerd $out/bin/workerd
  '';

  meta = with lib; {
    description = "Cloudflare's JavaScript/Wasm runtime, the open-source version of Cloudflare Workers";
    homepage = "https://github.com/cloudflare/workerd";
    license = licenses.asl20;
    maintainers = with maintainers; [ ]; # Add your handle here
    platforms = platforms.linux;
  };
}
