# Konbini Package Fix: Hardcoded API URL Issue

## Problem Summary

The `whyrusleeping-konbini` package in the NUR has a critical issue: the React frontend is built with hardcoded `http://localhost:4444` API URLs, making it non-functional when deployed behind a reverse proxy (Caddy/nginx).

### Symptoms

When accessing the konbini frontend through a reverse proxy:
- Browser loads the page successfully
- Console shows: `Failed to fetch current user: TypeError: Failed to fetch`
- Network tab shows: `localhost:4444/api/... - ERR_BLOCKED_BY_CLIENT`
- Frontend is completely non-functional

### Root Cause

The frontend build process doesn't set environment variables to configure the API URL:

```nix
# Current broken build in pkgs/whyrusleeping/konbini/default.nix
frontend = buildNpmPackage {
  pname = "konbini-frontend";
  inherit version src;
  sourceRoot = "${src.name}/frontend";

  buildPhase = ''
    runHook preBuild
    npm run build  # <-- No environment variables set
    runHook postBuild
  '';
};
```

This results in the built JavaScript having hardcoded absolute URLs (`http://localhost:4444/api`) instead of relative URLs (`/api`).

## The Fix

### What Needs to Change

The frontend build needs to set environment variables that instruct React/Vite to use relative URLs:

```nix
frontend = buildNpmPackage {
  pname = "konbini-frontend";
  inherit version src;
  sourceRoot = "${src.name}/frontend";
  npmDepsHash = "sha256-jqO9ll1KnbqsB9wxxjzVheZ3P+MXk63rRJL7vPdxKLs=";

  buildPhase = ''
    runHook preBuild

    # Set environment variables for relative API URLs
    export REACT_APP_API_URL=""
    export VITE_API_URL=""
    export PUBLIC_URL=""

    npm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r build/* $out/
    runHook postInstall
  '';
};
```

### Why This Works

1. Setting `REACT_APP_API_URL=""` to an empty string tells React to use relative URLs
2. The built JavaScript will use `/api/...` instead of `http://localhost:4444/api/...`
3. When the frontend is served through nginx, requests to `/api/...` go through the nginx reverse proxy
4. The nginx proxy then routes to the backend API server (either local or remote via Tailscale)

### How It Flows

**Before fix (broken):**
```
Browser → Caddy (konbini.snek.cc) → nginx (3000) → serves HTML/JS
Browser executes JS → tries http://localhost:4444/api → ❌ fails
```

**After fix (working):**
```
Browser → Caddy (konbini.snek.cc) → nginx (3000) → serves HTML/JS
Browser executes JS → tries /api (relative) → nginx proxies to backend → ✅ works
nginx reverse proxy (backendUrl option):
  locations."/api" = {
    proxyPass = "http://localhost:4444/api";  # ← configured by module
  };
```

## Investigation Steps

Before applying the fix, verify what environment variables the konbini frontend supports:

1. **Check the konbini repository:**
   ```bash
   # Look for environment variable documentation
   grep -r "REACT_APP\|VITE_" https://github.com/whyrusleeping/konbini/frontend

   # Check for .env.example or similar
   cat https://github.com/whyrusleeping/konbini/blob/main/frontend/.env.example
   ```

2. **Check the package.json build scripts:**
   ```bash
   # Look at what build tools are used
   grep "build" https://github.com/whyrusleeping/konbini/frontend/package.json
   ```

3. **Check the API client code:**
   ```bash
   # See how the API URL is currently configured
   grep -r "http://localhost:4444\|API_URL" https://github.com/whyrusleeping/konbini/frontend/src
   ```

## Implementation

### Files to Modify

- `pkgs/whyrusleeping/konbini/default.nix` - Update the frontend build phase

### Patch Template

```diff
  frontend = buildNpmPackage {
    pname = "konbini-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-jqO9ll1KnbqsB9wxxjzVheZ3P+MXk63rRJL7vPdxKLs=";

    buildPhase = ''
      runHook preBuild

+     # Configure frontend to use relative URLs for API
+     export REACT_APP_API_URL=""
+     export VITE_API_URL=""
+     export PUBLIC_URL=""

      npm run build

      runHook postBuild
    '';
  };
```

### Testing the Fix

After applying the fix:

```bash
# Rebuild the package locally
cd /Users/jack/Software/nur-vps
nix build .#whyrusleeping-konbini -L

# Verify the built files don't contain localhost:4444
grep -r "localhost:4444" ./result/share/konbini/frontend/
# Should return NO matches if fix is correct

# Deploy to bingus
nix copy --to ssh://root@100.113.12.42 ./result
# Then rebuild on bingus: sudo nixos-rebuild switch --flake .#bingus

# Test in browser
# Visit https://konbini.snek.cc
# Check browser console - should see /api calls instead of localhost:4444
```

## Related Configuration

### NixOS Module Architecture

The `services.whyrusleeping.konbini-frontend` module handles nginx configuration:

```nix
# Server-side proxy (configured by module):
locations."/api" = {
  proxyPass = "${cfg.backendUrl}/api";  # Points to backend
};

# This only works if frontend uses relative URLs!
# Current config on bingus:
backendUrl = "http://localhost:4444";  # Local backend
```

When deployed via Caddy:
- Caddy proxies `konbini.snek.cc` → `100.113.12.42:3000` (frontend nginx)
- Frontend requests `/api/...` → nginx proxies to `http://localhost:4444/api/...` (backend)

### Current Deployment

**snek server (our server):**
- Caddy reverse proxy on port 443 (SSL via Let's Encrypt)
- `konbini.snek.cc` → proxies to bingus:3000 (frontend)
- `api.konbini.snek.cc` → proxies to bingus:4446 (XRPC backend)

**bingus server (100.113.12.42):**
- konbini backend (port 4444: API, port 4446: XRPC)
- konbini frontend nginx (port 3000) - proxies /api to backend

## Priority and Impact

**Priority:** High - Frontend is currently non-functional in production

**Impact:**
- ✅ Fixes broken deployment
- ✅ No breaking changes to module API
- ✅ Works with existing configuration
- ✅ Works with both local and remote backends (via Tailscale proxy)

## Workarounds (If Fix Delayed)

If the package fix takes time, temporary workarounds:

### Workaround 1: nginx sub_filter (URL rewriting)

Add to the frontend module's nginx config:
```nix
locations."~* \\.(js)$" = {
  extraConfig = ''
    sub_filter 'http://localhost:4444' '';
    sub_filter_once off;
    sub_filter_types application/javascript;
    # ... rest of config
  '';
};
```

This rewrites the hardcoded URLs on-the-fly but is less efficient than fixing the build.

### Workaround 2: Package override on bingus

```nix
# In bingus configuration.nix
pkgs.whyrusleeping-konbini.overrideAttrs (oldAttrs: {
  frontend = oldAttrs.frontend.overrideAttrs (old: {
    buildPhase = ''
      runHook preBuild
      export REACT_APP_API_URL=""
      npm run build
      runHook postBuild
    '';
  });
})
```

## Documentation References

- [whyrusleeping/konbini GitHub](https://github.com/whyrusleeping/konbini)
- [React environment variables](https://create-react-app.dev/docs/adding-custom-environment-variables/)
- [Vite environment variables](https://vitejs.dev/guide/env-and-modes.html)
- [Nginx reverse proxy with sub_filter](https://nginx.org/en/docs/http/ngx_http_sub_module.html)

## Next Steps

1. Investigate the konbini frontend source for env var support
2. Apply the fix to `pkgs/whyrusleeping/konbini/default.nix`
3. Build and test locally
4. Deploy to bingus and verify
5. Document in CLAUDE.md under "Known Issues" once resolved

