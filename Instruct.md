Your client has many application teams already using Azure and Azure DevOps, but each team has different Terraform folder structures, formats, and deployment patterns. This inconsistency makes it difficult to track changes, maintain governance, troubleshoot, or enforce standards across the organization.
You want to design a standardized, reusable Terraform framework that all teams can follow. This includes technical structure, documentation, environments, and CI/CD usage.

📘 Reformatted and Improved Requirements
1. Standardized Terraform Structure
The client needs a single Terraform framework that is:

Reusable across all teams and applications
Uses a common format for modules, variables, naming, and deployment steps
Helps every team understand how infrastructure is created, updated, and traced
Supports centralized governance while allowing team-level customization
Includes a primary landing zone where all applications can be onboarded


2. Terraform Must Support All Azure Resource Types
The structure must cover a wide range of Azure services, including but not limited to:

Azure Kubernetes Service (AKS)
Landing Zone foundation
App Services / Web Apps
General applications
Databases (SQL, PostgreSQL, Cosmos, etc.)
Container Apps
Networking, Identity, and Security components
Any other Azure resources used by teams

This means the framework must be modular, scalable, and easy to extend.

3. Structure Must Be Reusable Across All Teams
The overall design needs to:

Use modular Terraform (root module + reusable submodules)
Allow teams to reuse the same modules even if their applications differ
Enforce consistency across naming, tagging, versioning, and structure
Include grouping such as /modules, /environments, /global, /pipelines, etc.


4. Environment Separation
The framework must support:

Development
Staging
Production

Each environment must have its own directory, variables, and configuration for governance and security separation.

5. Environment-Based Security Levels
Each environment should have different security expectations:

Development → simple, fast, minimal restrictions
Staging → moderate security, closer to production
Production → strongest security, with policies, compliance checks, and locked-down pipelines

This requires applying different:

RBAC
Azure Policies
Network rules
Module parameters
CI/CD approvals

Based on environment.

6. Separate Directory Structure Per Environment
Example structure (for clarity):
/infra
  /modules
      /aks
      /webapp
      /network
      /database
      /landingzone
  /environments
      /dev
      /staging
      /prod
  /pipelines
  /docs


7. Two Types of Documentation Required
You need to produce two documentation sets:
🧑‍💻 Technical Documentation
Includes:

Folder structure details
How modules work
Variable/TFVARS usage
How to run / plan / apply
CI/CD integration
Architecture and diagrams
Example configuration

🧑‍💼 Management-Friendly Documentation
Explains:

Why standardization is needed
Benefits for governance, cost, and operations
How the structure reduces risk
What the Landing Zone solves
How teams onboard
High-level workflow diagrams

Both sets must include “why” and “how” for every major component.

8. Include Full Examples
You need a full end-to-end example that shows:
🔹 Example Scenario 1: Deploying an AKS-based application
With sample:

Variables
Values
Module usage

🔹 Example Scenario 2: Setting up Landing Zone
Using the same structural approach to show framework reusability.
This demonstrates the unified architecture for all resource types.

9. Designed for CI/CD (Azure DevOps or GitHub)
The framework must be optimized for:

Azure DevOps pipelines
GitHub Actions

Including:

Terraform state handling
Approvals
Environment variables
Secure pipeline configuration
Reusable pipeline templates


✅ Concise Summary
You want to build a standardized, reusable, multi-environment Terraform framework that all development teams will use consistently for deploying Azure resources. This framework must support all major Azure services, include both technical and management documentation, and integrate cleanly with Azure DevOps/GitHub CI/CD pipelines. It also needs to demonstrate how the same structure can deploy different scenarios (e.g., AKS and Landing Zone).