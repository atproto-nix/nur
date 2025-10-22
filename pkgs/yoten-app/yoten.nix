{ pkgs, buildGoModule, fetchFromTangled, ... }:

# Yoten - Language learning social platform using ATProto
# Note: This is a basic build - the full implementation requires templ and tailwindcss
buildGoModule rec {
  pname = "yoten";
  version = "0.1.0";
  
  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@yoten.app";
    repo = "yoten";
    rev = "2de6115fc7b166148b7d9206809e0f4f0c6916d7";
    sha256 = "00lx7pkms1ycrbcmihqc5az98xvw0pb3107b107zikj8i08hygxz";
  };
  
  vendorHash = "sha256-gjlwSBmyHy0SXTnOi+XNVBKm4t7HWRVNA19Utx3Eh/w=";
  
  # Build the main server binary
  subPackages = [ "cmd/server" ];
  
  # Skip tests for now due to complex dependencies
  doCheck = false;
  
  # Note: This is a basic build that doesn't include templ generation or tailwind CSS
  # For full functionality, additional build steps would be needed:
  # 1. templ generate (requires templ tool)
  # 2. tailwindcss build (requires tailwindcss and minify)
  # 3. Static asset processing
  
  postInstall = ''
    # Rename binary to yoten
    mv $out/bin/server $out/bin/yoten
  '';
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "yoten" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Social platform for tracking language learning progress";
    };
    
    organization = {
      name = "yoten-app";
      displayName = "Yoten App";
      website = "https://yoten.app";
      contact = null;
      maintainer = "Yoten App";
      repository = "https://tangled.org/@yoten.app/yoten";
      packageCount = 1;
      atprotoFocus = [ "applications" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "Social platform for tracking language learning progress";
    longDescription = ''
      Social platform for tracking language learning progress built on ATProto.
      
      Note: This is a basic build that includes the core Go server but does not include
      the full frontend build process (templ templates and tailwindcss). For full
      functionality, additional build tools would be needed.
      
      Maintained by Yoten App (https://yoten.app)
    '';
    homepage = "https://yoten.app";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "yoten";
    
    organizationalContext = {
      organization = "yoten-app";
      displayName = "Yoten App";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}