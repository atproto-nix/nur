# ATProto Packaging Priority Matrix

## Overview

This matrix provides a systematic approach to packaging ATProto applications based on complexity, dependencies, community value, and strategic importance to the ecosystem.

## Scoring Criteria

Each application is scored on a scale of 1-5 in the following categories:

- **Complexity**: Build complexity and dependency management (1=simple, 5=very complex)
- **Dependencies**: Number and complexity of external dependencies (1=few/simple, 5=many/complex)
- **Community Value**: Importance to ATProto ecosystem and user adoption (1=niche, 5=critical)
- **Strategic Value**: Alignment with repository goals and packaging patterns (1=low, 5=high)
- **Maintenance Burden**: Ongoing maintenance and update complexity (1=low, 5=high)

**Priority Score**: (Community Value × 2) + Strategic Value - (Complexity + Dependencies + Maintenance Burden)

## Application Matrix

| Application | Language | Complexity | Dependencies | Community Value | Strategic Value | Maintenance | Priority Score | Tier | Implementation Status |
|-------------|----------|------------|--------------|-----------------|-----------------|-------------|----------------|------|---------------------|
| **Allegedly** | Rust | 2 | 2 | 5 | 5 | 2 | **9** | 1 | ❌ No Nix config |
| **Tangled** | Go | 4 | 4 | 4 | 5 | 3 | **8** | 1 | ✅ Complete, needs config fixes |
| **Frontpage/Bluesky** | TypeScript | 4 | 4 | 5 | 5 | 4 | **8** | 1 | ❌ No Nix config |
| **Microcosm-rs** | Rust | 3 | 3 | 4 | 4 | 3 | **7** | 1 | ⚠️ Partial, needs updates |
| **Indigo** | Go | 4 | 4 | 5 | 4 | 4 | **7** | 1 | ❌ No Nix config |
| **rsky** | Rust | 3 | 3 | 4 | 4 | 3 | **6** | 2 | ⚠️ Partial (blacksky) |
| **atbackup** | TypeScript/Tauri | 3 | 3 | 3 | 3 | 3 | **6** | 2 | ❌ No Nix config |
| **quickdid** | Rust | 2 | 2 | 3 | 3 | 2 | **6** | 2 | ❌ No Nix config |
| **Leaflet** | TypeScript | 4 | 4 | 3 | 3 | 4 | **5** | 2 | ❌ No Nix config |
| **pds-dash** | Svelte/Deno | 3 | 3 | 3 | 3 | 3 | **5** | 2 | ❌ No Nix config |
| **pds-gatekeeper** | Rust | 3 | 3 | 3 | 3 | 3 | **5** | 2 | ❌ No Nix config |
| **Grain** | TypeScript | 4 | 4 | 3 | 3 | 4 | **4** | 2 | ❌ No Nix config |
| **Slices** | Rust+Deno | 5 | 5 | 3 | 3 | 5 | **4** | 3 | ❌ No Nix config |
| **Parakeet** | Rust | 4 | 4 | 2 | 2 | 4 | **3** | 3 | ❌ No Nix config |
| **Yoten** | Go | 3 | 3 | 2 | 2 | 3 | **3** | 3 | ❌ No Nix config |
| **Red Dwarf** | TypeScript | 2 | 2 | 2 | 2 | 2 | **3** | 3 | ❌ No Nix config |
| **Teal** | Rust+TypeScript | 5 | 5 | 2 | 2 | 5 | **2** | 3 | ❌ No Nix config |
| **Streamplace** | Multi-lang | 5 | 5 | 2 | 2 | 5 | **2** | 3 | ❌ No Nix config |

## Tier Definitions

### Tier 1: Immediate Priority (Score ≥ 4)
**Target Timeline**: Next 1-2 months

Applications that provide maximum value with manageable complexity:

1. **Allegedly** (Score: 7) - Critical identity infrastructure, clean Rust implementation
2. **Tangled** (Score: 5) - Already has Nix support, strategic development tooling
3. **Microcosm-rs** (Score: 4) - Good Rust packaging example, active community
4. **Frontpage/Bluesky** (Score: 4) - Official implementation, high community value

### Tier 2: High Priority (Score 0-3)
**Target Timeline**: Months 3-6

Applications with good value proposition but higher complexity:

1. **Indigo** (Score: 2) - Official Go implementation, comprehensive but complex
2. **rsky** (Score: 3) - Community Rust implementation, good reference
3. **atbackup** (Score: 3) - Useful utility, moderate complexity
4. **quickdid** (Score: 3) - Identity tooling, straightforward packaging
5. **pds-dash** (Score: 0) - PDS management interface, Svelte packaging
6. **pds-gatekeeper** (Score: 0) - PDS registration system, moderate complexity

### Tier 3: Future Consideration (Score < 0)
**Target Timeline**: Months 6+

Applications with specialized use cases or high complexity:

1. **Leaflet** (Score: -2) - Collaborative writing, complex frontend
2. **Yoten** (Score: -3) - Specialized service, moderate complexity
3. **Red Dwarf** (Score: -2) - Client application, limited server value
4. **Slices** (Score: -6) - Multi-language platform, very complex
5. **Parakeet** (Score: -6) - Specialized indexing, complex dependencies
6. **Teal** (Score: -9) - Full platform, very high complexity
7. **Streamplace** (Score: -9) - Multimedia infrastructure, extremely complex

## Implementation Roadmap

### Phase 1: Foundation (Tier 1 Applications)

**Month 1: Core Infrastructure**
- Complete Allegedly packaging (DID/PLC tools)
- Improve Tangled configuration handling
- Begin Microcosm-rs packaging improvements

**Month 2: Official Support**
- Package Frontpage/Bluesky official implementation
- Establish TypeScript packaging patterns
- Create comprehensive testing framework

### Phase 2: Ecosystem Expansion (Tier 2 Applications)

**Month 3: Go Ecosystem**
- Package Indigo Go implementation
- Establish Go packaging patterns
- Create cross-language compatibility examples

**Month 4: Community Tools**
- Package rsky community implementation
- Add atbackup and quickdid utilities
- Improve Rust packaging patterns

**Month 5: Management Tools**
- Package pds-dash and pds-gatekeeper
- Create PDS ecosystem integration
- Establish Svelte packaging patterns

**Month 6: Integration and Polish**
- Complete Tier 2 applications
- Create deployment profiles and examples
- Comprehensive documentation and guides

### Phase 3: Specialized Applications (Tier 3)

**Months 7+: Advanced Features**
- Evaluate Tier 3 applications based on community demand
- Focus on applications with emerging importance
- Consider specialized use cases and complex dependencies

## Success Criteria

### Tier 1 Success Metrics
- All Tier 1 applications packaged and functional
- Established packaging patterns for Rust, Go, and TypeScript
- Active community adoption and contributions
- Comprehensive testing and CI/CD integration

### Tier 2 Success Metrics
- 80% of Tier 2 applications packaged
- Cross-language compatibility demonstrated
- Production deployment examples available
- Community feedback incorporated

### Tier 3 Success Metrics
- Strategic subset of Tier 3 applications packaged
- Advanced packaging patterns established
- Specialized use cases supported
- Long-term maintenance strategy in place

## Risk Mitigation

### High Complexity Applications
- Start with simpler components within complex applications
- Create modular packaging approach
- Establish clear maintenance boundaries

### Dependency Management
- Prioritize applications with well-defined dependencies
- Create shared dependency packages where possible
- Monitor upstream changes and security updates

### Community Engagement
- Regular feedback collection from users
- Transparent roadmap communication
- Contribution guidelines and mentorship

## Conclusion

This priority matrix provides a data-driven approach to packaging ATProto applications, balancing community value with implementation complexity. The tiered approach ensures steady progress while building the foundation for long-term ecosystem growth.

The focus on Tier 1 applications establishes core patterns and provides immediate value, while the roadmap for Tier 2 and 3 applications ensures comprehensive ecosystem coverage over time.