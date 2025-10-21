{ pkgs, craneLib, fetchgit, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../lib/atproto.nix { inherit craneLib; };
in

atprotoLib.mkRustAtprotoService {
  pname = "allegedly";
  version = "0.3.3";
  
  src = fetchgit {
    url = "https://tangled.org/@microcosm.blue/Allegedly";
    rev = "d66bb7f31fbedc2d813b659fb84c6a8cbf1fb428";
    sha256 = "03fah42q5y3dx7l4kr15msmxhlw508pamls130kn2k1v201w7a7p";
  };
  
  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ openssl postgresql ];
  
  # Build the main allegedly binary
  cargoExtraArgs = "--bin allegedly";
  
  passthru.atproto = {
    type = "application";
    services = [ "allegedly" ];
    protocols = [ "com.atproto" ];
    schemaVersion = "1.0";
    description = "Public ledger server tools and services for the PLC";
  };
  
  meta = with pkgs.lib; {
    description = "Public ledger server tools and services (for the PLC)";
    homepage = "https://tangled.org/@microcosm.blue/Allegedly";
    license = with licenses; [ mit asl20 ];
    platforms = platforms.unix;
    maintainers = [ ];
  };
}