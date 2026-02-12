# Terraform Framework - Client Demo Documentation

## Document Index

This documentation is designed to explain the **Enterprise Terraform Framework for Azure** to clients. It covers everything from basic concepts to advanced multi-team scenarios.

**Audience**: Client stakeholders, developers, and DevOps engineers who are new to Terraform and Azure DevOps.

---

## Documents Overview

| # | Document | Description | Who Should Read |
|---|----------|-------------|-----------------|
| 01 | [Framework Overview](01-FRAMEWORK-OVERVIEW.md) | What this framework is, why it exists, and how it solves the problem of inconsistent Terraform across teams | Everyone |
| 02 | [Terraform Basics for Beginners](02-TERRAFORM-BASICS.md) | What each Terraform file does, how files connect to each other, what happens when you run `terraform apply` | Developers new to Terraform |
| 03 | [How Files Connect - The Big Picture](03-HOW-FILES-CONNECT.md) | Deep dive into how `global/`, `modules/`, `envs/`, and `examples/` interact with each other, with diagrams | Developers, DevOps Engineers |
| 04 | [Pattern 1 vs Pattern 2 Explained](04-PATTERN1-VS-PATTERN2.md) | Centralized vs Delegated patterns - when to use which, advantages, disadvantages, and comparison table | Everyone |
| 05 | [Demo Scenario - Step by Step](05-DEMO-SCENARIO-STEP-BY-STEP.md) | Complete walkthrough: Create AKS, CosmosDB, ContainerApp, PostgreSQL across multiple teams | Everyone (main demo doc) |
| 06 | [Mermaid Diagrams Collection](06-DIAGRAMS.md) | All architecture diagrams, flow diagrams, and team responsibility diagrams | Everyone |

---

## How to Use This Documentation

1. **Start with Document 01** to understand the "why" behind this framework
2. **Read Document 02** if you are new to Terraform (highly recommended)
3. **Read Document 03** to understand how all the files work together
4. **Read Document 04** to understand the two deployment patterns
5. **Follow Document 05** for the live demo walkthrough
6. **Reference Document 06** for diagrams you can show during presentations

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
