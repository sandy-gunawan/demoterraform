# Document 06: Diagrams Collection

This document contains all Mermaid diagrams for the framework. You can copy-paste these into any Mermaid-compatible renderer (Azure DevOps Wiki, GitHub, VS Code Mermaid plugins, mermaid.live, etc.).

---

## Diagram 1: High-Level Framework Architecture

```mermaid
graph TB
    subgraph "Enterprise Terraform Framework"
        subgraph "Layer 0: Global Standards"
            GL[infra/global/]
            GL --> |"Naming Rules"| NM[locals.tf]
            GL --> |"Version Locks"| VR[versions.tf]
            GL --> |"Provider Docs"| PR[providers.tf]
        end

        subgraph "Layer 0.5: Reusable Modules"
            MOD[infra/modules/]
            MOD --> AKS[aks/]
            MOD --> CDB[cosmosdb/]
            MOD --> CAP[container-app/]
            MOD --> PG[postgresql/]
            MOD --> NET[networking/]
            MOD --> LZ[landing-zone/]
            MOD --> SEC[security/]
            MOD --> WEB[webapp/]
            MOD --> ST[storage/]
        end

        subgraph "Layer 1: Platform Infrastructure"
            PLT[infra/platform/]
            PLT --> PDEV[dev/main.tf]
            PLT --> PSTG[staging/main.tf]
            PLT --> PPRD[prod/main.tf]
        end

        subgraph "Layer 2: Applications"
            ENV[infra/envs/ - Pattern 1]
            ENV --> DEV[dev/main.tf]
            ENV --> STG[staging/main.tf]
            ENV --> PRD[prod/main.tf]

            P2[examples/pattern-2-delegated/]
            P2 --> CRM[dev-app-crm/]
            P2 --> ECM[dev-app-ecommerce/]
        end
    end

    GL -.->|"Standards applied to"| PDEV
    GL -.->|"Standards applied to"| DEV
    GL -.->|"Standards applied to"| CRM
    MOD -.->|"Modules used by"| PDEV
    MOD -.->|"Modules used by"| DEV
    PLT -.->|"data sources"| DEV
    PLT -.->|"data sources"| CRM
    PLT -.->|"data sources"| ECM

    style GL fill:#4CAF50,color:#fff
    style MOD fill:#2196F3,color:#fff
    style PLT fill:#FF5722,color:#fff
    style ENV fill:#FF9800,color:#fff
    style P2 fill:#9C27B0,color:#fff
```

---

## Diagram 2: Data Flow - How Values Travel Through Files

```mermaid
flowchart LR
    subgraph "Input"
        TFVARS[dev.tfvars<br/>Values:<br/>enable_aks=true<br/>project_name=contoso]
    end

    subgraph "Declaration"
        VARS[variables.tf<br/>Declares:<br/>variable enable_aks<br/>variable project_name]
    end

    subgraph "Orchestration"
        MAIN[main.tf<br/>Uses values to:<br/>- Call modules<br/>- Create resources<br/>- Apply conditionals]
    end

    subgraph "Standards"
        GLOBAL[global/locals.tf<br/>Generates:<br/>- Resource names<br/>- Standard tags]
    end

    subgraph "Building Blocks"
        MODS[modules/aks/<br/>modules/cosmosdb/<br/>modules/networking/]
    end

    subgraph "Results"
        OUT[outputs.tf<br/>Shows:<br/>- Resource IDs<br/>- Connection strings<br/>- Cluster names]
    end

    subgraph "State"
        STATE[backend.tf<br/>Saves to:<br/>Azure Storage<br/>dev.terraform.tfstate]
    end

    TFVARS -->|"provides values"| VARS
    VARS -->|"validates & passes"| MAIN
    MAIN -->|"imports standards"| GLOBAL
    MAIN -->|"calls modules"| MODS
    GLOBAL -->|"returns tags & names"| MAIN
    MODS -->|"returns resource IDs"| MAIN
    MAIN -->|"exposes results"| OUT
    MAIN -->|"records state"| STATE

    style TFVARS fill:#E8F5E9
    style VARS fill:#E3F2FD
    style MAIN fill:#FFF3E0
    style GLOBAL fill:#F3E5F5
    style MODS fill:#E0F7FA
    style OUT fill:#FBE9E7
    style STATE fill:#F5F5F5
```

---

## Diagram 3: Demo Scenario - Complete Team Workflow

```mermaid
sequenceDiagram
    participant Andi as 🧑‍💻 Andi<br/>(Platform Team)
    participant Budi as 👨‍💻 Budi<br/>(Team Alpha)
    participant Citra as 👩‍💻 Citra<br/>(Team Beta)
    participant Dewi as 👩‍💻 Dewi<br/>(Team Gamma/CRM)
    participant Eka as 👨‍💻 Eka<br/>(Team Delta/E-com)
    participant Azure as ☁️ Azure

    Note over Andi,Azure: ACT 1: Platform Layer Setup
    Andi->>Azure: Create state storage (az CLI)
    Andi->>Andi: Edit platform/dev/dev.tfvars
    Andi->>Azure: terraform apply → VNet, Subnets, Logs, KeyVault
    Azure-->>Andi: ✅ Platform layer ready (platform-dev.tfstate)

    Note over Budi,Azure: ACT 2A: Team Alpha Request (App Layer)
    Budi->>Andi: "We need AKS + CosmosDB"
    Andi->>Andi: Set enable_aks=true, enable_cosmosdb=true in envs/dev/
    Andi->>Azure: terraform apply (reads VNets from platform via data sources)
    Azure-->>Andi: ✅ AKS + CosmosDB created
    Andi-->>Budi: "Your AKS cluster is ready!"

    Note over Citra,Azure: ACT 2B: Team Beta Request (App Layer)
    Citra->>Andi: "We need ContainerApps + PostgreSQL"
    Andi->>Andi: Set enable_container_apps=true, enable_postgresql=true
    Andi->>Azure: terraform apply
    Azure-->>Andi: ✅ ContainerApps + PostgreSQL created
    Andi-->>Citra: "Your services are ready!"

    Note over Dewi,Eka: ACT 3: Independent Teams (Pattern 2)
    
    par CRM Team works independently
        Dewi->>Dewi: Edit dev-app-crm/dev.tfvars
        Dewi->>Azure: terraform apply
        Azure-->>Dewi: ✅ CRM resources created
    and E-commerce Team works independently
        Eka->>Eka: Edit dev-app-ecommerce/dev.tfvars
        Eka->>Azure: terraform apply
        Azure-->>Eka: ✅ E-commerce resources created
    end

    Note over Andi,Azure: All teams deployed successfully!
```

---

## Diagram 4: Pattern 1 vs Pattern 2 - Side by Side

```mermaid
graph TB
    subgraph "Pattern 1: Centralized (Layered)"
        P1_PLT[Platform Layer<br/>infra/platform/dev/<br/>VNets, Security, Monitoring]
        P1_STATE_P[(platform-dev.tfstate)]

        P1_TFVARS[dev.tfvars<br/>enable_aks=true<br/>enable_cosmosdb=true]
        P1_MAIN[App Layer main.tf<br/>reads from platform]
        P1_STATE[(dev.terraform.tfstate)]

        P1_AKS[AKS Module]
        P1_CDB[CosmosDB Module]

        P1_PLT --> P1_STATE_P
        P1_PLT -.->|"data sources"| P1_MAIN
        P1_TFVARS --> P1_MAIN
        P1_MAIN --> P1_AKS
        P1_MAIN --> P1_CDB
        P1_MAIN --> P1_STATE
    end

    subgraph "Pattern 2: Delegated"
        P2_PLT[Platform Layer<br/>Same platform-dev.tfstate]

        P2_CRM_MAIN[CRM main.tf]
        P2_CRM_STATE[(crm.tfstate)]

        P2_ECM_MAIN[E-com main.tf]
        P2_ECM_STATE[(ecom.tfstate)]

        P2_PLT -.->|"data source"| P2_CRM_MAIN
        P2_PLT -.->|"data source"| P2_ECM_MAIN
        P2_CRM_MAIN --> P2_CRM_STATE
        P2_ECM_MAIN --> P2_ECM_STATE
    end

    style P1_STATE_P fill:#FFCDD2
    style P1_STATE fill:#FFF9C4
    style P2_CRM_STATE fill:#C8E6C9
    style P2_ECM_STATE fill:#BBDEFB
```

---

## Diagram 5: Module Dependency Chain

```mermaid
graph TD
    RG[Resource Group<br/>Must exist FIRST]
    NET[Networking Module<br/>VNet + Subnets + NSGs]
    LOG[Log Analytics Workspace<br/>Monitoring foundation]
    KV[Key Vault Module<br/>Secrets management]
    
    AKS[AKS Module<br/>Kubernetes cluster]
    CDB[CosmosDB Module<br/>Document database]
    CAP[Container App Module<br/>Serverless containers]
    PG[PostgreSQL Module<br/>Relational database]
    WEB[Web App Module<br/>App Service]

    RG --> NET
    RG --> LOG
    RG --> KV
    
    NET -->|"subnet_ids"| AKS
    NET -->|"subnet_ids"| CAP
    NET -->|"subnet_ids"| PG
    LOG -->|"workspace_id"| AKS
    LOG -->|"workspace_id"| CAP
    
    RG --> CDB
    RG --> WEB

    style RG fill:#F44336,color:#fff
    style NET fill:#FF9800,color:#fff
    style LOG fill:#FFC107,color:#fff
    style KV fill:#4CAF50,color:#fff
    style AKS fill:#2196F3,color:#fff
    style CDB fill:#9C27B0,color:#fff
    style CAP fill:#00BCD4,color:#fff
    style PG fill:#795548,color:#fff
    style WEB fill:#607D8B,color:#fff
```

---

## Diagram 6: File Interaction in Pattern 1 (Layered Architecture)

```mermaid
graph LR
    subgraph "infra/platform/dev/ (Layer 1)"
        PLT_MA[main.tf<br/>VNets, Security]
        PLT_STATE[(platform-dev.tfstate)]
        PLT_MA --> PLT_STATE
    end

    subgraph "infra/envs/dev/ (Layer 2)"
        BE[backend.tf<br/>State: Azure Storage]
        TV[dev.tfvars<br/>Values: org, project,<br/>toggles]
        VA[variables.tf<br/>Declarations]
        MA[main.tf<br/>Orchestrator]
        OU[outputs.tf<br/>Results]
    end

    subgraph "infra/global/"
        GL[locals.tf<br/>Naming + Tags]
        GO[outputs.tf<br/>Exports standards]
    end

    subgraph "infra/modules/"
        MA_AKS[aks/<br/>Kubernetes]
        MC[cosmosdb/<br/>CosmosDB]
        MCA[container-app/<br/>ContainerApps]
        MP[postgresql/<br/>PostgreSQL]
    end

    TV -->|"values"| VA
    VA -->|"variables"| MA
    MA -->|"source=../../global"| GL
    GL --> GO
    GO -->|"common_tags"| MA
    
    PLT_MA -.->|"data sources<br/>VNet, Subnets, Logs"| MA
    
    MA -->|"source=../../modules/aks"| MA_AKS
    MA -->|"source=../../modules/cosmosdb"| MC
    MA -->|"source=../../modules/container-app"| MCA
    MA -->|"source=../../modules/postgresql"| MP

    MA --> OU
    MA --> BE

    style BE fill:#ECEFF1
    style TV fill:#E8F5E9
    style VA fill:#E3F2FD
    style MA fill:#FFF3E0
    style OU fill:#FBE9E7
    style GL fill:#F3E5F5
    style PLT_MA fill:#FFCDD2
```

---

## Diagram 7: Pattern 2 - How Teams Connect to Shared Infrastructure

```mermaid
graph TB
    subgraph "Platform Team Manages"
        SHARED_RG[Resource Group<br/>rg-contoso-dev-network-001]
        SHARED_VNET[VNet<br/>vnet-contoso-dev-001]
        SHARED_SUB1[Subnet: aks<br/>snet-contoso-dev-aks-001]
        SHARED_SUB2[Subnet: app<br/>snet-contoso-dev-app-001]
        SHARED_LOG[Log Analytics<br/>log-contoso-dev-001]

        SHARED_RG --> SHARED_VNET
        SHARED_VNET --> SHARED_SUB1
        SHARED_VNET --> SHARED_SUB2
        SHARED_RG --> SHARED_LOG
    end

    subgraph "CRM Team (Dewi)"
        CRM_DATA1[data azurerm_virtual_network<br/>Reads: vnet-contoso-dev-001]
        CRM_DATA2[data azurerm_subnet<br/>Reads: snet-contoso-dev-app-001]
        CRM_RG[Own RG:<br/>rg-contoso-dev-crm-001]
        CRM_APP[App Service]
        CRM_DB[CosmosDB]
        CRM_KV[Key Vault]

        CRM_DATA1 --> CRM_APP
        CRM_DATA2 --> CRM_APP
        CRM_RG --> CRM_APP
        CRM_RG --> CRM_DB
        CRM_RG --> CRM_KV
    end

    subgraph "E-commerce Team (Eka)"
        ECM_DATA1[data azurerm_virtual_network<br/>Reads: vnet-contoso-dev-001]
        ECM_DATA2[data azurerm_subnet<br/>Reads: snet-contoso-dev-aks-001]
        ECM_RG[Own RG:<br/>rg-contoso-dev-ecommerce-001]
        ECM_AKS[AKS Cluster]
        ECM_DB[CosmosDB]
        ECM_KV[Key Vault]

        ECM_DATA1 --> ECM_AKS
        ECM_DATA2 --> ECM_AKS
        ECM_RG --> ECM_AKS
        ECM_RG --> ECM_DB
        ECM_RG --> ECM_KV
    end

    SHARED_VNET -.->|"Referenced by<br/>data source"| CRM_DATA1
    SHARED_SUB2 -.->|"Referenced by<br/>data source"| CRM_DATA2
    SHARED_VNET -.->|"Referenced by<br/>data source"| ECM_DATA1
    SHARED_SUB1 -.->|"Referenced by<br/>data source"| ECM_DATA2

    style SHARED_RG fill:#4CAF50,color:#fff
    style CRM_RG fill:#FF9800,color:#fff
    style ECM_RG fill:#2196F3,color:#fff
```

---

## Diagram 8: State File Isolation

```mermaid
graph TB
    subgraph "Azure Storage Account: stcontosotfstate001"
        subgraph "Container: tfstate"
            S0[platform-dev.tfstate<br/>Platform Layer: VNets, Security<br/>Monitoring]
            S1[dev.terraform.tfstate<br/>App Layer Pattern 1<br/>AKS, CosmosDB, etc.]
            S2[dev-app-crm.tfstate<br/>CRM Team Only<br/>Pattern 2]
            S3[dev-app-ecommerce.tfstate<br/>E-commerce Team Only<br/>Pattern 2]
            S4[platform-staging.tfstate<br/>Staging Platform]
            S5[staging.terraform.tfstate<br/>Staging Apps]
            S6[platform-prod.tfstate<br/>Prod Platform]
            S7[prod.terraform.tfstate<br/>Prod Apps]
        end
    end

    subgraph "What Each State Controls"
        S0 --> P0[VNets, Subnets, NSGs,<br/>Log Analytics, Key Vault]
        S1 --> P1[AKS, CosmosDB,<br/>ContainerApps, PostgreSQL]
        S2 --> P2[CRM App Service,<br/>CRM CosmosDB,<br/>CRM Key Vault]
        S3 --> P3[E-com AKS,<br/>E-com CosmosDB,<br/>E-com Key Vault]
    end

    subgraph "Isolation Benefit"
        ISO1[Platform change ≠ App affected ✅]
        ISO2[CRM destroy ≠ E-com affected ✅]
        ISO3[Dev destroy ≠ Prod affected ✅]
    end

    style S0 fill:#FFCDD2
    style S1 fill:#FFF9C4
    style S2 fill:#C8E6C9
    style S3 fill:#BBDEFB
    style S4 fill:#FFE0B2
    style S5 fill:#FFE0B2
    style S6 fill:#E1BEE7
    style S7 fill:#E1BEE7
```

---

## Diagram 9: Complete Azure Resource Map After Demo

```mermaid
graph TB
    subgraph "Azure Subscription"
        subgraph "contoso-tfstate-rg"
            SA[Storage Account<br/>stcontosotfstate001]
        end

        subgraph "contoso-platform-rg-dev (Platform Layer)"
            P1_VNET[VNet: vnet-contoso-dev-001<br/>10.1.0.0/16]
            P1_AKS_SUB[Subnet: aks-subnet<br/>10.1.1.0/24]
            P1_APP_SUB[Subnet: app-subnet<br/>10.1.2.0/24]
            P1_NSG[NSG: aks-nsg]
            P1_LOG[Log Analytics:<br/>contoso-logs-dev]
            P1_KV[Key Vault:<br/>platformkvdev]
        end

        subgraph "contoso-apps-rg-dev (App Layer - Pattern 1)"
            P1_AKS[AKS: platform-aks-dev<br/>1x Standard_D8ds_v5]
            P1_CDB[CosmosDB:<br/>platformcosmosdev]
            P1_CAE[Container App Env:<br/>platform-cae-dev]
            P1_PG[PostgreSQL:<br/>platform-pg-dev]
        end

        subgraph "rg-contoso-dev-crm-001 (Pattern 2)"
            CRM_ASP[App Service Plan]
            CRM_WEB[Web App:<br/>app-contoso-dev-crm-001]
            CRM_CDB[CosmosDB:<br/>cosmos-contoso-dev-crm-001]
            CRM_KV[Key Vault:<br/>kv-contoso-dev-crm]
            CRM_ID[Managed Identity:<br/>id-contoso-dev-crm-001]
        end

        subgraph "rg-contoso-dev-ecommerce-001 (Pattern 2)"
            ECM_AKS[AKS:<br/>aks-contoso-dev-ecommerce-001]
            ECM_CDB[CosmosDB:<br/>cosmos-contoso-dev-ecommerce-001]
            ECM_KV[Key Vault:<br/>kv-contoso-dev-ecommerce]
            ECM_ID[Managed Identity:<br/>id-contoso-dev-ecommerce-001]
        end
    end

    P1_VNET --> P1_AKS_SUB
    P1_VNET --> P1_APP_SUB
    P1_AKS_SUB --> P1_AKS
    P1_APP_SUB --> P1_CAE
    P1_AKS_SUB -.-> ECM_AKS
    P1_APP_SUB -.-> CRM_WEB

    style SA fill:#ECEFF1
    style P1_AKS fill:#2196F3,color:#fff
    style P1_CDB fill:#9C27B0,color:#fff
    style P1_CAE fill:#00BCD4,color:#fff
    style P1_PG fill:#795548,color:#fff
    style CRM_WEB fill:#FF9800,color:#fff
    style CRM_CDB fill:#FF9800,color:#fff
    style ECM_AKS fill:#4CAF50,color:#fff
    style ECM_CDB fill:#4CAF50,color:#fff
```

---

## Diagram 10: Team Responsibility Matrix

```mermaid
graph LR
    subgraph "Platform Team (Andi)"
        PT_RESP["Responsibilities:<br/>✅ State storage setup<br/>✅ VNet & Subnets<br/>✅ NSGs & Security<br/>✅ Log Analytics<br/>✅ Module maintenance<br/>✅ Pipeline management<br/>✅ Pattern 1 toggles<br/><br/>Skills needed:<br/>🔧 Terraform advanced<br/>🔧 Azure networking<br/>🔧 DevOps pipelines"]
    end

    subgraph "App Team - Pattern 1 (Budi/Citra)"
        P1_RESP["Responsibilities:<br/>✅ Request services to Platform<br/>✅ Test their applications<br/>✅ Report issues<br/><br/>Skills needed:<br/>📖 Basic Terraform<br/>📖 Application deployment<br/><br/>NOT responsible for:<br/>❌ Infrastructure code<br/>❌ Network config<br/>❌ Security settings"]
    end

    subgraph "App Team - Pattern 2 (Dewi/Eka)"
        P2_RESP["Responsibilities:<br/>✅ Own folder management<br/>✅ Own resource deployment<br/>✅ Own state management<br/>✅ Own PR reviews<br/>✅ Cost optimization<br/><br/>Skills needed:<br/>🔧 Intermediate Terraform<br/>🔧 Module usage<br/>🔧 Data sources<br/><br/>NOT responsible for:<br/>❌ Shared networking<br/>❌ Module internals"]
    end

    PT_RESP -->|"Provides base infra"| P1_RESP
    PT_RESP -->|"Provides shared VNet"| P2_RESP
```

---

## How to Use These Diagrams

### In Azure DevOps Wiki
Copy the Mermaid code blocks directly into an Azure DevOps Wiki page. Azure DevOps supports Mermaid natively.

### In Presentations
1. Go to [mermaid.live](https://mermaid.live)
2. Paste the Mermaid code
3. Export as PNG or SVG
4. Insert into PowerPoint/Google Slides

### In VS Code
Install the "Mermaid Preview" extension to see diagrams rendered in VS Code.

### In GitHub
Mermaid is supported in GitHub markdown files natively.

---

*Previous: [05 - Pattern 2 Demo](05-PATTERN2-DEMO.md)* | *Back to: [00 - Document Index](00-DOCUMENT-INDEX.md)*
