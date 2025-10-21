{ pkgs, ... }:

# Yoten - Language learning social platform using ATProto (placeholder - complex templ/tailwind build)
pkgs.writeTextFile {
  name = "yoten-placeholder";
  text = ''
    # Yoten Placeholder
    
    This is a placeholder for Yoten - a social platform for tracking language learning progress.
    The actual implementation requires complex Go template generation and frontend build tools.
    
    Source: https://tangled.org/@yoten.app/yoten
    Commit: 2de6115fc7b166148b7d9206809e0f4f0c6916d7
    Vendor Hash: sha256-gjlwSBmyHy0SXTnOi+XNVBKm4t7HWRVNA19Utx3Eh/w=
    
    Required build tools:
    - templ (Go template generator)
    - tailwindcss (CSS framework)
    - minify (JS/CSS minifier)
    
    To build manually:
    1. Install required tools: templ, tailwindcss, minify
    2. Set up static assets (see docs/hacking.md)
    3. Generate templates: templ generate
    4. Build: go build ./cmd/server
  '';
  
  passthru.atproto = {
    type = "application";
    services = [ "yoten" ];
    protocols = [ "com.atproto" "app.bsky" ];
    schemaVersion = "1.0";
    description = "Social platform for tracking language learning progress";
    
    # Source information for future implementation
    source = {
      url = "https://tangled.org/@yoten.app/yoten";
      rev = "2de6115fc7b166148b7d9206809e0f4f0c6916d7";
      sha256 = "00lx7pkms1ycrbcmihqc5az98xvw0pb3107b107zikj8i08hygxz";
      vendorHash = "sha256-gjlwSBmyHy0SXTnOi+XNVBKm4t7HWRVNA19Utx3Eh/w=";
    };
  };
  
  meta = with pkgs.lib; {
    description = "Social platform for tracking language learning progress (placeholder - requires templ/tailwind)";
    homepage = "https://yoten.app";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ ];
  };
}