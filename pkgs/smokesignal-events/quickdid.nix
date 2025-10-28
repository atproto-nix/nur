{ pkgs, craneLib, fetchgit, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../lib/atproto.nix { inherit craneLib; };
in

atprotoLib.mkRustAtprotoService {
  pname = "quickdid";
  version = "1.0.0-rc.5";
  
  src = fetchgit {
    url = "https://tangled.sh/@smokesignal.events/quickdid";
    rev = "eaebd066cf27ad6671a21652c5d7c66e8a2885be";
    sha256 = "1gmqqakc6ljndw3lgv8c6ggwy1ag577hlja1gqq5f77j862yxs7v";
  };
  
  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ openssl sqlite ];
  
  # Build the main quickdid binary
  cargoExtraArgs = "--bin quickdid";
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "quickdid" ];
      protocols = [ "com.atproto" ];
      schemaVersion = "1.0";
      description = "Fast and scalable identity resolution service";
    };
    
    organization = {
      name = "smokesignal-events";
      displayName = "Smokesignal Events";
      website = null;
      contact = null;
      maintainer = "Smokesignal Events";
      repository = "https://tangled.sh/@smokesignal.events/quickdid";
      packageCount = 1;
      atprotoFocus = [ "infrastructure" "identity" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "A fast and scalable com.atproto.identity.resolveHandle service";
    longDescription = ''
      A fast and scalable com.atproto.identity.resolveHandle service for ATProto identity resolution.
      Provides efficient DID resolution for ATProto applications.
      
      Maintained by Smokesignal Events
    '';
    homepage = "https://tangled.sh/@smokesignal.events/quickdid";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    
    organizationalContext = {
      organization = "smokesignal-events";
      displayName = "Smokesignal Events";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}