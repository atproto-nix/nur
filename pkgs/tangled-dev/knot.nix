{ pkgs, ... }:

pkgs.writeTextFile {
  name = "tangled-knot-placeholder";
  text = ''
    # Tangled Knot Placeholder
    
    This is a placeholder for Tangled Knot.
    The actual implementation can be built using the Nix files in:
    code-references/tangled-core
    
    To build the real package, use:
    nix build ./code-references/tangled-core#knot
  '';
  
  passthru.atproto = {
    type = "application";
    services = [ "knot" "git-server" ];
    protocols = [ "com.atproto" ];
    schemaVersion = "1.0";
    
    tangled = {
      component = "knot";
      description = "Git server component of Tangled with ATProto integration";
      nixPath = "code-references/tangled-core";
    };
  };
  
  meta = with pkgs.lib; {
    description = "Tangled Knot - Git server with ATProto integration (placeholder)";
    homepage = "https://github.com/tangled-dev/tangled-core";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}