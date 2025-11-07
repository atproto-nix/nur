{ ... }:

# Grain Social NixOS Modules
# ===========================
#
# Photo-sharing platform built on AT Protocol
# Organization: grain-social
# Maintainer: Chad Miller
# Repository: https://tangled.org/@grain.social/grain
#
# MODULE STATUS:
# ✅ grain-darkroom.nix       - Implemented, fully functional, security hardened
# ⚠️  grain-appview.nix       - Module defined, awaiting package implementation
# ⚠️  grain-labeler.nix       - Module defined, awaiting package implementation
# ⚠️  grain-notifications.nix - Module defined, awaiting package implementation
#
# CURRENT CAPABILITIES:
# - Image processing and screenshot service (Darkroom) works independently
# - Can be used with any Grain-compatible frontend
# - All modules will work once packages are implemented
#
# NEXT STEPS:
# 1. Implement grain-social-appview package (Deno/TypeScript)
# 2. Implement grain-social-labeler package (Rust)
# 3. Implement grain-social-notifications package (TypeScript/Deno or Rust)
# 4. Integration testing across all services
#
# SECURITY NOTES:
# - All modules use strict systemd sandboxing
# - Darkroom no longer uses --no-sandbox (uses systemd RestrictNamespaces instead)
# - Secrets should be passed via secure files, not environment variables
#

{
  imports = [
    ./grain-appview.nix
    ./grain-darkroom.nix
    ./grain-labeler.nix
    ./grain-notifications.nix
  ];
}
