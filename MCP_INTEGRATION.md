# MCP-NixOS Integration Plan

## Overview

Integrate MCP-NixOS (Model Context Protocol server) to provide AI assistants with accurate, real-time information about NixOS packages and configuration options.

**Benefits:**
- ✅ Access to 130K+ NixOS packages information
- ✅ 22K+ NixOS configuration options
- ✅ 4K+ Home Manager options
- ✅ Prevent hallucinations about package availability
- ✅ Real-time version information across nixpkgs channels

**Source:** https://mcp-nixos.io/ | https://github.com/utensils/mcp-nixos

---

## Phase 1: Local Development Setup

### Task 1.1: Install MCP-NixOS

**Priority:** 🟢 MEDIUM
**Time Estimate:** 10 minutes

**For development machine:**

**Option A: Quick test (no installation):**
```bash
uvx mcp-nixos
```

**Option B: Install with Nix (recommended for this repo):**
```bash
nix profile install github:utensils/mcp-nixos
```

**Option C: Install via pip:**
```bash
pip install mcp-nixos
```

**Verification:**
```bash
# Test it works
mcp-nixos --help

# Or with uvx
uvx mcp-nixos --help
```

---

### Task 1.2: Configure for Claude Code

**Priority:** 🟡 HIGH (if using Claude Code for development)
**Time Estimate:** 15 minutes

**Location:** `~/.config/claude-code/mcp.json` (or equivalent for your system)

**Configuration:**
```json
{
  "mcpServers": {
    "mcp-nixos": {
      "command": "uvx",
      "args": ["mcp-nixos"]
    }
  }
}
```

**Or with Nix:**
```json
{
  "mcpServers": {
    "mcp-nixos": {
      "command": "nix",
      "args": ["run", "github:utensils/mcp-nixos"]
    }
  }
}
```

**Test:**
1. Restart Claude Code
2. Check that MCP server is available
3. Try querying: "What NixOS options are available for systemd services?"

---

### Task 1.3: Document in Repository

**Priority:** 🟢 MEDIUM
**Time Estimate:** 20 minutes

**Add to CLAUDE.md:**

```markdown
## MCP Integration

This repository uses MCP-NixOS for accurate package and configuration information.

### Setup for Contributors

If you're using Claude Code or other MCP-compatible AI assistants:

1. Install MCP-NixOS:
   ```bash
   nix profile install github:utensils/mcp-nixos
   # Or: uvx mcp-nixos (no installation needed)
   ```

2. Configure your AI assistant (example for Claude Code):
   ```json
   {
     "mcpServers": {
       "mcp-nixos": {
         "command": "uvx",
         "args": ["mcp-nixos"]
       }
     }
   }
   ```

3. Benefits:
   - Real-time package information (130K+ packages)
   - Accurate NixOS options (22K+)
   - Version tracking across channels
   - Prevents hallucinations about availability

### Available Queries

With MCP-NixOS, you can ask:
- "What NixOS packages are available for ATProto?"
- "Show me systemd service options in NixOS"
- "What version of Rust is in nixpkgs-unstable?"
- "Which NixOS options configure firewall rules?"

This significantly improves AI assistance accuracy when working with Nix.
```

---

## Phase 2: Repository Integration

### Task 2.1: Add Development Shell with MCP

**Priority:** 🟢 MEDIUM
**Time Estimate:** 20 minutes

**Update `flake.nix`:**

```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    deadnix
    nixpkgs-fmt
    # MCP-NixOS for AI assistance
    (pkgs.python3.withPackages (ps: with ps; [
      # mcp-nixos dependencies
    ]))
  ];

  shellHook = ''
    echo "ATProto NUR Development Environment"
    echo "======================================"
    echo ""
    echo "Available tools:"
    echo "  - deadnix: Find unused Nix code"
    echo "  - nixpkgs-fmt: Format Nix files"
    echo "  - mcp-nixos: AI assistant integration"
    echo ""
    echo "MCP-NixOS Setup:"
    echo "  Run 'uvx mcp-nixos' to test MCP server"
    echo "  See MCP_INTEGRATION.md for AI assistant setup"
    echo ""
  '';
};
```

---

### Task 2.2: Create MCP Usage Examples

**Priority:** 🟢 LOW
**Time Estimate:** 30 minutes

**Create:** `docs/mcp-examples.md`

```markdown
# MCP-NixOS Usage Examples for ATProto NUR

## Common Queries for This Repository

### Package Discovery

**Query:** "Are there any NixOS packages for ATProto or Bluesky?"
- **Result:** Gets current nixpkgs packages, helps avoid duplication

**Query:** "What Go packages are available in nixpkgs for building servers?"
- **Result:** Helps choose dependencies for new packages

**Query:** "Show me buildGoModule examples in nixpkgs"
- **Result:** Gets real examples of Go packaging

### Configuration Options

**Query:** "What systemd service options are available in NixOS?"
- **Result:** Helps write better NixOS modules

**Query:** "Show me firewall configuration options in NixOS"
- **Result:** For modules that need `openFirewall` option

**Query:** "What user/group management options exist in NixOS?"
- **Result:** For service user creation in modules

### Version Information

**Query:** "What version of Rust is in nixpkgs-unstable?"
- **Result:** Helps determine Rust compatibility

**Query:** "Which Node.js versions are available in nixpkgs?"
- **Result:** For TypeScript package builds

**Query:** "Show me the latest commit hash for nixpkgs-unstable"
- **Result:** For updating flake inputs

## Benefits for This Repository

1. **Accurate Package Information:**
   - No more guessing about nixpkgs package names
   - Real-time availability checking
   - Version compatibility verification

2. **Better Module Development:**
   - Accurate NixOS option documentation
   - Example configurations from real packages
   - Best practices from nixpkgs

3. **Dependency Management:**
   - Check what's already in nixpkgs
   - Verify dependency versions
   - Find compatible package versions

4. **Reduced Errors:**
   - Less hallucination about package names
   - Correct attribute paths
   - Valid configuration syntax
```

---

## Phase 3: CI/CD Integration (Optional)

### Task 3.1: MCP in GitHub Actions

**Priority:** 🔵 LOW (nice-to-have)
**Time Estimate:** 45 minutes

**Use case:** Automated package updates with AI assistance

**Workflow:** `.github/workflows/mcp-assisted-updates.yml`

```yaml
name: MCP-Assisted Package Updates

on:
  schedule:
    # Run weekly
    - cron: '0 0 * * 0'
  workflow_dispatch:

jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v24

      - name: Install MCP-NixOS
        run: |
          nix profile install github:utensils/mcp-nixos

      - name: Check for upstream updates
        run: |
          # Script that uses MCP to check package versions
          # Compare with upstream repositories
          # Generate update suggestions

      - name: Create update PR
        # Only if updates are available
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "chore: Update package versions"
          title: "Automated package updates (MCP-assisted)"
          body: |
            Automated updates detected by MCP-NixOS integration.

            Please review changes before merging.
```

---

## Phase 4: Documentation & Training

### Task 4.1: Contributor Guide

**Priority:** 🟢 MEDIUM
**Time Estimate:** 30 minutes

**Add to CONTRIBUTING.md (create if doesn't exist):**

```markdown
## AI-Assisted Development

This repository is optimized for AI-assisted development using MCP-NixOS.

### Setup

1. **Install MCP-NixOS:**
   ```bash
   nix profile install github:utensils/mcp-nixos
   ```

2. **Configure your AI assistant** (Claude Code, Cursor, etc.)

3. **Use it for:**
   - Package discovery and version checking
   - NixOS option documentation
   - Example configurations
   - Best practices from nixpkgs

### Best Practices

**DO:**
- ✅ Query MCP before adding new dependencies
- ✅ Use MCP to verify NixOS option syntax
- ✅ Check nixpkgs for existing similar packages
- ✅ Verify package availability across channels

**DON'T:**
- ❌ Trust AI suggestions without MCP verification
- ❌ Assume package names without checking
- ❌ Copy configurations without understanding them
```

---

### Task 4.2: Update README.md

**Priority:** 🟢 MEDIUM
**Time Estimate:** 15 minutes

**Add badge:**
```markdown
[![MCP-NixOS](https://img.shields.io/badge/MCP-NixOS-blue)](https://mcp-nixos.io/)
```

**Add section:**
```markdown
## AI-Assisted Development

This repository uses [MCP-NixOS](https://mcp-nixos.io/) for AI-assisted development.

Contributors using Claude Code, Cursor, or other MCP-compatible assistants can benefit from:
- Real-time NixOS package information (130K+ packages)
- Accurate configuration options (22K+ options)
- Version tracking across nixpkgs channels
- Reduced hallucinations about package availability

See [MCP_INTEGRATION.md](./MCP_INTEGRATION.md) for setup instructions.
```

---

## Timeline

### Immediate (This Week)
- ✅ Install MCP-NixOS locally (10 min)
- ✅ Configure Claude Code/IDE (15 min)
- ✅ Test with example queries (15 min)

### Short-term (Next Week)
- ✅ Update CLAUDE.md with MCP info (20 min)
- ✅ Add to development shell (20 min)
- ✅ Update README (15 min)

### Medium-term (Next Month)
- ✅ Create MCP usage examples doc (30 min)
- ✅ Add to CONTRIBUTING.md (30 min)
- ⚠️ CI/CD integration (optional, 45 min)

**Total Time:** 2-3 hours (excluding optional CI/CD)

---

## Success Metrics

### Immediate Benefits
- [ ] AI assistant provides accurate package names
- [ ] Configuration suggestions use real NixOS options
- [ ] Version information is up-to-date
- [ ] Fewer build errors from incorrect package references

### Long-term Benefits
- [ ] Faster package addition (less trial-and-error)
- [ ] Better module quality (accurate options)
- [ ] Easier onboarding for new contributors
- [ ] Reduced maintenance burden (automated checks)

---

## Resources

- **Official Site:** https://mcp-nixos.io/
- **GitHub:** https://github.com/utensils/mcp-nixos
- **PyPI:** https://pypi.org/project/mcp-nixos/
- **Glama:** https://glama.ai/mcp/servers/@utensils/mcp-nixos

---

## Quick Start Commands

```bash
# Test MCP-NixOS (no installation)
uvx mcp-nixos

# Install with Nix
nix profile install github:utensils/mcp-nixos

# Install with pip
pip install mcp-nixos

# Run from Nix flake
nix run github:utensils/mcp-nixos

# Check version
mcp-nixos --version
```

---

**Status:** Ready to implement
**Priority:** Medium (improves development experience)
**Effort:** Low (2-3 hours total)
**Impact:** High (better AI assistance quality)
