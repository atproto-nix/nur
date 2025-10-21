{ pkgs, ... }:

pkgs.writeTextFile {
  name = "tangled-appview-placeholder";
  text = ''
    # Tangled AppView Placeholder
    
    This is a placeholder for Tangled AppView.
    The actual implementation can be built using the Nix files in:
    code-references/tangled-core
    
    To build the real package, use:
    nix build ./code-references/tangled-core#appview
  '';
  
  passthru.atproto = {
    type = "application";
    services = [ "appview" "web-interface" ];
    protocols = [ "com.atproto" ];
    schemaVersion = "1.0";
    
    tangled = {
      component = "appview";
      description = "Web interface for Tangled git forge with ATProto integration";
      nixPath = "code-references/tangled-core";
    };
  };
  
  meta = with pkgs.lib; {
    description = "Tangled AppView - Web interface for ATProto git forge (placeholder)";
    homepage = "https://github.com/tangled-dev/tangled-core";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}