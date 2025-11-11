# Archived Documentation

This directory contains historical documentation that is no longer actively maintained or relevant to current development.

## Contents

### Planning (planning/)
Documents describing planned work, features, or architectural improvements that were not completed or superseded by newer approaches.

**Files:**
- `LIB_PACKAGING_IMPROVEMENTS.md` - Proposed improvements to lib/packaging.nix (not yet implemented)
- `MODULAR_PACKAGING_PLAN.md` - Strategic plan for restructuring lib/ (not yet implemented)
- `PLANNING_SUMMARY.md` - October 2025 planning notes (superseded by ROADMAP.md)

**Rationale for archival:**
- These documents describe future work that either wasn't completed or was superseded
- For implemented features, the code itself is the source of truth
- Historical planning is kept for reference but not actively maintained
- New planning uses ROADMAP.md instead

### Research (research/)
Research notes and explorations that were conducted during development but are no longer actively referenced.

**Files:**
- `pds_dash_research_summary.md` - Research on pds-dash implementation
- `research_summary.md` - General research notes

**Rationale for archival:**
- Research findings have been incorporated into package implementations
- Individual package/service guides (PDS_DASH_*.md, etc.) contain current information
- Kept for historical reference and context about decision-making process

## How to Use This Archive

If you're looking for information about:

| Topic | Current Source |
|-------|---|
| Development roadmap | `../ROADMAP.md` |
| Recent changes | `../ROADMAP.md` (Recent Completions section) |
| Package build patterns | `../CLAUDE.md` (Build System Patterns) |
| PDS Dashboard | `../PDS_DASH_*.md` files |
| Architecture decisions | `../NUR_BEST_PRACTICES.md` |
| New packaging ideas | Create an issue or discussion |

## Restoring from Archive

If a planning document needs to be revisited or archived content needs updating:

1. Copy the file from `.archived/` back to the main `docs/` directory
2. Update it with current information
3. Add it back to active documentation
4. Commit with clear message explaining why it's being restored

## Contributing to Archive

When archiving documents:
- Keep original files intact (no editing)
- Add archival date in commit message
- Ensure current source of information is available elsewhere
- Document rationale in this README

---

**Archive created:** November 11, 2025
**Archival rationale:** Consolidate historical documentation and reduce active documentation maintenance burden while keeping valuable historical context available for reference.
