{ pkgs, ... }:

pkgs.writeTextFile {
  name = "tangled-lexgen-placeholder";
  text = ''
    # Tangled Lexicon Generator Placeholder
    
    This is a placeholder for Tangled lexicon generator.
    The actual implementation can be built using the Nix files in:
    code-references/tangled-core
    
    To build the real package, use:
    nix build ./code-references/tangled-core#lexgen
  '';
  
  passthru.atproto = {
    type = "tool";
    services = [];
    protocols = [ "com.atproto" ];
    schemaVersion = "1.0";
    
    tangled = {
      component = "lexgen";
      description = "Lexicon generator for ATProto schemas in Tangled";
      nixPath = "code-references/tangled-core";
    };
  };
  
  meta = with pkgs.lib; {
    description = "Tangled Lexicon generator for ATProto schemas (placeholder)";
    homepage = "https://github.com/tangled-dev/tangled-core";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}