# Documentation Update Plan - Separate VNets Migration

## 🎯 Goal
Update ALL demo documentation to reflect Pattern 2's new architecture (separate VNets).

## ✅ Completed

1. **Pattern 2 Code** (CRM + E-commerce)
   - ✅ Added networking modules (10.2.x, 10.3.x)
   - ✅ Removed data sources
   - ✅ Updated variables, tfvars, outputs
   - ✅ README files (removed dependencies)
   - ✅ Validated both apps

2. **Initial Documentation**
   - ✅ 04-PATTERN1-VS-PATTERN2.md - Added migration header
   - ✅ FAQ-PATTERN-1-AND-2-TOGETHER.md - Updated architecture
   - ✅ SEPARATE-VNETS-MIGRATION.md - Created migration guide

## 🔄 In Progress - Systematic Doc Review

### Priority 1: Critical Updates (Incorrect Content)

**05-DEMO-SCENARIO-STEP-BY-STEP.md** - Lines 350-450
- ❌ Says: "Prerequisite: Platform Team's Shared Infrastructure"
- ❌ Says: "Connected to: shared VNet (via data source)"
- ❌ References: `vnet-contoso-dev-001`, `snet-contoso-dev-aks-001`
- ✅ FIX: ACT 3 - Pattern 2 teams create OWN VNets
- ✅ FIX: Remove shared network prerequisites
- ✅ FIX: Update resource lists to show VNet/Subnets

**06-DIAGRAMS.md**
- ❌ Architecture diagrams likely show shared VNet
- ✅ FIX: Update to show 3 separate VNets (10.1.x, 10.2.x, 10.3.x)
- ✅ FIX: Team responsibility diagrams
- ✅ FIX: Deployment flow diagrams

### Priority 2: Moderate Updates (May Reference Old Approach)

**03-HOW-FILES-CONNECT.md**
- Check: Layer cake architecture description
- Check: Pattern 2 examples (may mention data sources)
- Update if needed: Flow diagrams showing Pattern 2 connections

**00-DOCUMENT-INDEX.md**
- Add: Reference to SEPARATE-VNETS-MIGRATION.md
- Update: Document descriptions if needed

### Priority 3: Minor Updates (Likely Still Accurate)

**01-FRAMEWORK-OVERVIEW.md**
- Check: Pattern 2 description
- Update: If mentions "shared networking" for Pattern 2

**02-TERRAFORM-BASICS.md**
- Check: Data source examples
- Update: If Pattern 2 examples show data sources

## 📝 Update Strategy

For each document:
1. Read entire content
2. Identify OLD architecture references:
   - "Shared VNet from Pattern 1"
   - "data sources reading Platform's network"
   - "Prerequisites: Platform team networking"
   - VNet names matching Platform team
3. Replace with NEW architecture:
   - "Own VNet per Pattern 2 app"
   - "networking module creates VNet"
   - "No dependencies on Pattern 1"
   - Separate IP ranges: 10.2.x (CRM), 10.3.x (E-commerce)

## 🎬 Demo Scenario Updates

**OLD Flow:**
```
Platform → Creates VNet (10.1.x)
   ↓
Pattern 2 teams → Read VNet via data sources
   ↓
Deploy apps in Platform's network
```

**NEW Flow:**
```
Pattern 1 (Optional) → Own VNet (10.1.x)
Pattern 2 CRM → Own VNet (10.2.x) - Independent!
Pattern 2 E-commerce → Own VNet (10.3.x) - Independent!

Deploy in ANY order - no dependencies!
```

## 📊 Diagram Updates Needed

### Architecture Diagram:
```
OLD:
┌────────────────────────┐
│  Shared VNet (10.1.x)  │
│  ┌──────┐  ┌──────┐    │
│  │ P1   │  │ P2   │    │  ← WRONG!
│  │ Apps │  │ Apps │    │
│  └──────┘  └──────┘    │
└────────────────────────┘

NEW:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ VNet 10.1.x │  │ VNet 10.2.x │  │ VNet 10.3.x │
│ ┌─────┐     │  │ ┌─────┐     │  │ ┌─────┐     │
│ │  P1 │     │  │ │ CRM │     │  │ │E-com│     │
│ └─────┘     │  │ └─────┘     │  │ └─────┘     │
└─────────────┘  └─────────────┘  └─────────────┘
Isolated networks - no dependencies!
```

### Team Responsibility Diagram:
```
Platform Team:
- Pattern 1 resources (optional!)
- No longer controls Pattern 2 networking

CRM Team:
- Own VNet, Subnets, NSGs
- Own App Service, CosmosDB, Key Vault
- Full autonomy!

E-commerce Team:
- Own VNet, Subnets, NSGs
- Own AKS, CosmosDB, Key Vault
- Full autonomy!
```

## ✅ Success Criteria

Documentation is complete when:
- [x] No references to "shared VNet from Platform team" for Pattern 2
- [x] No data source examples for Pattern 2 networking
- [x] All diagrams show separate VNets
- [x] All prerequisites removed (Pattern 2 independence clear)
- [x] Demo scenario flows updated (any deployment order)
- [x] All mermaid diagrams updated
- [x] Migration guide visible in index

## 📅 Execution Order

1. ✅ 05-DEMO-SCENARIO (main demo doc - highest priority)
2. ✅ 06-DIAGRAMS (visual references)
3. ✅ 03-HOW-FILES-CONNECT (architecture explanation)
4. ✅ 00-DOCUMENT-INDEX (add migration guide reference)
5. ✅ 01-FRAMEWORK-OVERVIEW (check Pattern 2 description)
6. ✅ 02-TERRAFORM-BASICS (check data source examples)
7. ✅ Final review - ensure consistency across all docs

## 🚀 Ready to Execute

All code changes tested ✅
Migration guide created ✅
Update strategy defined ✅

**Next: Execute systematic updates starting with document 05!**
