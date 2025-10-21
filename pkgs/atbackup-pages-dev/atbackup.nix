{ pkgs, ... }:

# ATBackup - One-click Bluesky backups (placeholder - complex Tauri/Yarn build)
pkgs.writeTextFile {
  name = "atbackup-placeholder";
  text = ''
    # ATBackup Placeholder
    
    This is a placeholder for ATBackup - a Tauri-based desktop application for Bluesky backups.
    The actual implementation requires complex Yarn/Tauri build setup.
    
    Source: https://tangled.org/@atbackup.pages.dev/atbackup
    Commit: deb720914f4c36557bcd5ee9af95791e42afd45f
    
    To build manually:
    1. Clone the repository
    2. Install Yarn dependencies: yarn install
    3. Build frontend: yarn build
    4. Build Tauri app: yarn tauri build
  '';
  
  passthru.atproto = {
    type = "application";
    services = [ "atbackup" ];
    protocols = [ "com.atproto" "app.bsky" ];
    schemaVersion = "1.0";
    hasWebFrontend = true;
    description = "One-click Bluesky backups desktop application";
    
    # Source information for future implementation
    source = {
      url = "https://tangled.org/@atbackup.pages.dev/atbackup";
      rev = "deb720914f4c36557bcd5ee9af95791e42afd45f";
      sha256 = "0ksqwsqv95lq97rh8z9dc0m1bjzc2fb4yjlksyfx7p49f1slcv8r";
    };
  };
  
  meta = with pkgs.lib; {
    description = "One-click bluesky backups (placeholder - requires Tauri/Yarn setup)";
    homepage = "https://tangled.org/@atbackup.pages.dev/atbackup";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = [ ];
  };
}