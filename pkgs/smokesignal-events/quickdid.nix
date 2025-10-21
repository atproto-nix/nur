{ pkgs, craneLib, fetchgit, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../lib/atproto.nix { inherit craneLib; };
in

atprotoLib.mkRustAtprotoService {
  pname = "quickdid";
  version = "1.0.0-rc.5";
  
  src = fetchgit {
    url = "https://tangled.org/@smokesignal.events/quickdid";
    rev = "eaebd066cf27ad6671a21652c5d7c66e8a2885be";
    sha256 = "1gmqqakc6ljndw3lgv8c6ggwy1ag577hlja1gqq5f77j862yxs7v";
  };
  
  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ openssl sqlite ];
  
  # Build the main quickdid binary
  cargoExtraArgs = "--bin quickdid";
  
  passthru.atproto = {
    type = "application";
    services = [ "quickdid" ];
    protocols = [ "com.atproto" ];
    schemaVersion = "1.0";
    description = "Fast and scalable identity resolution service";
  };
  
  meta = with pkgs.lib; {
    description = "A fast and scalable com.atproto.identity.resolveHandle service";
    homepage = "https://tangled.org/@smokesignal.events/quickdid";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}