# Terraform Framework — Client Demo Documentation

## Document Index

This documentation explains the **Enterprise Terraform Framework for Azure** to clients. It covers basic concepts through to advanced multi-team deployment patterns.

**Audience**: Client stakeholders, developers, and DevOps engineers who are new to Terraform and Azure DevOps.

---

## Documents Overview

| # | Document | Description | Who Should Read |
|---|----------|-------------|-----------------|
| 01 | [Framework Overview](01-FRAMEWORK-OVERVIEW.md) | What this framework is, why it exists, house-building analogy, feature toggles | Everyone |
| 02 | [Terraform Basics for Beginners](02-TERRAFORM-BASICS.md) | What each Terraform file does, how they connect, what happens when you run `terraform apply` | Developers new to Terraform |
| 03 | [How Files Connect — The Big Picture](03-HOW-FILES-CONNECT.md) | How `global/`, `modules/`, `envs/`, and `examples/` interact with each other | Developers, DevOps Engineers |
| 04 | [Pattern 1 Demo — Centralized](04-PATTERN1-DEMO.md) | **Standalone test case**: Platform team deploys all resources with feature toggles | Everyone (main demo #1) |
| 05 | [Pattern 2 Demo — Delegated](05-PATTERN2-DEMO.md) | **Standalone test case**: Application teams deploy independently with own state files | Everyone (main demo #2) |
| 06 | [Mermaid Diagrams Collection](06-DIAGRAMS.md) | Architecture diagrams, flow diagrams, team responsibility charts | Everyone |

---

## How to Use This Documentation

1. **Start with 01** → Understand the "why" behind this framework
2. **Read 02** if new to Terraform → Learn what each file does
3. **Read 03** to see how all files connect together
4. **Demo 04** → Pattern 1: Centralized deployment (can run as CI/CD test case)
5. **Demo 05** → Pattern 2: Delegated per-team deployment (can run as CI/CD test case)
6. **Reference 06** for diagrams during presentations

### For CI/CD Demo

- **Pattern 1 test case**: Document 04 → `cd infra/envs/dev && terraform validate && terraform plan`
- **Pattern 2 test case**: Document 05 → `cd examples/pattern-2-delegated/dev-app-crm && terraform validate`

---

## Quick Reference

```
Framework Structure:
├── infra/global/      → Standards everyone follows (naming, tags)
├── infra/modules/     → Reusable building blocks (AKS, CosmosDB, etc.)
├── infra/envs/        → Pattern 1: Centralized environments
├── examples/          → Pattern 2: Delegated per-team examples
├── pipelines/         → Azure DevOps CI/CD
├── scripts/           → Helper scripts
└── docs/              → This documentation
```
