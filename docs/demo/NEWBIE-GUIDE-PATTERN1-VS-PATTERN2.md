# 🎓 Newbie Guide: Understanding Pattern 1 vs Pattern 2

## ❓ The Confusion

**You might think:**
- "Pattern 1 creates its own VNet"
- "Pattern 2 creates its own VNet"
- "They are completely separate"

**❌ WRONG!** This is the most common misunderstanding!

---

## ✅ The Truth

**Platform team (Pattern 1) creates ALL the VNets!**

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ONE FILE creates ALL the networking!                  ┃
┃  File: infra/envs/dev/main.tf                          ┃
┃                                                         ┃
┃  Platform team runs: terraform apply                   ┃
┃                                                         ┃
┃  Result: 3 VNets created                               ┃
┃  ├── 10.1.0.0/16 (Pattern 1 shared services)          ┃
┃  ├── 10.2.0.0/16 (CRM app - Pattern 2)                ┃
┃  └── 10.3.0.0/16 (E-commerce app - Pattern 2)         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## 📂 Where Is The Code?

### **File 1: Platform Team Creates Everything**

**Location:** `infra/envs/dev/main.tf`

```hcl
# Line 56 - VNet for Pattern 1 shared services
module "networking" {
  source        = "../../modules/networking"
  address_space = ["10.1.0.0/16"]
  network_name  = "platform-vnet-dev"
}

# Line 115 - VNet for CRM team (Pattern 2)
module "networking_crm" {
  source        = "../../modules/networking"
  address_space = ["10.2.0.0/16"]
  network_name  = "vnet-contoso-dev-crm-001"
  # 👆 Platform creates this for CRM team!
}

# Line 172 - VNet for E-commerce team (Pattern 2)
module "networking_ecommerce" {
  source        = "../../modules/networking"
  address_space = ["10.3.0.0/16"]
  network_name  = "vnet-contoso-dev-ecommerce-001"
  # 👆 Platform creates this for E-commerce team!
}
```

### **File 2: CRM Team Reads VNet**

**Location:** `examples/pattern-2-delegated/dev-app-crm/main.tf`

```hcl
# Line 41 - READ the VNet (don't create it!)
data "azurerm_virtual_network" "crm" {
  name                = "vnet-contoso-dev-crm-001"
  resource_group_name = "contoso-platform-rg-dev"
  # 👆 This VNet was created by Platform team above!
}

# Line 48 - READ the subnet
data "azurerm_subnet" "crm_app" {
  name                 = "crm-app-subnet"
  virtual_network_name = data.azurerm_virtual_network.crm.name
}

# NOW create your apps using Platform's network
resource "azurerm_app_service" "crm" {
  # ... uses Platform's subnet
}
```

### **File 3: E-commerce Team Reads VNet**

**Location:** `examples/pattern-2-delegated/dev-app-ecommerce/main.tf`

```hcl
# Line 41 - READ the VNet (don't create it!)
data "azurerm_virtual_network" "ecommerce" {
  name                = "vnet-contoso-dev-ecommerce-001"
  resource_group_name = "contoso-platform-rg-dev"
  # 👆 This VNet was created by Platform team above!
}

# Line 48 - READ the subnet
data "azurerm_subnet" "ecom_aks" {
  name                 = "ecom-aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.ecommerce.name
}

# NOW create your apps using Platform's network
resource "azurerm_kubernetes_cluster" "ecommerce" {
  # ... uses Platform's subnet
}
```

---

## 🔄 Deployment Flow

```
Step 1: Platform Team
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cd infra/envs/dev
terraform init
terraform apply

Creates:
✅ VNet 10.1.0.0/16 (Pattern 1)
✅ VNet 10.2.0.0/16 (for CRM)
✅ VNet 10.3.0.0/16 (for E-commerce)
✅ Shared AKS, CosmosDB, etc.

State file: dev.terraform.tfstate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 2: CRM Team (can run in parallel with E-commerce!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cd examples/pattern-2-delegated/dev-app-crm
terraform init
terraform apply

Reads:
📖 VNet 10.2.0.0/16 (created by Platform)
📖 Subnet crm-app-subnet

Creates:
✅ App Service
✅ CosmosDB (separate from Platform's)
✅ Key Vault

State file: dev-app-crm.tfstate (SEPARATE!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 3: E-commerce Team (can run in parallel with CRM!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cd examples/pattern-2-delegated/dev-app-ecommerce
terraform init
terraform apply

Reads:
📖 VNet 10.3.0.0/16 (created by Platform)
📖 Subnet ecom-aks-subnet

Creates:
✅ AKS Cluster
✅ CosmosDB (separate from everyone)
✅ Key Vault

State file: dev-app-ecommerce.tfstate (SEPARATE!)
```

---

## 💡 Why This Design?

### **Analogy: Building a City**

Think of it like a city:

| Role | Responsibility | In Terraform |
|------|----------------|--------------|
| **City Government** | Builds roads, electricity, water | Platform team creates VNets |
| **Homeowners** | Build houses on the roads | Pattern 2 teams create apps |
| **Why?** | Government ensures roads meet standards | Platform ensures networking is secure & consistent |

### **Benefits**

| Benefit | Explanation |
|---------|-------------|
| 🛡️ **Governance** | Platform enforces security rules (NSGs, IP ranges) |
| ♻️ **Reusability** | Same networking module used 3 times (DRY principle) |
| 🎯 **Focus** | Teams focus on apps, not networking boilerplate |
| 🔒 **Safety** | Teams can't accidentally break networking |
| 📦 **Isolation** | Each app has dedicated VNet (blast radius limited) |

---

## 🤔 Common Questions

### **Q: Why can't Pattern 2 teams create their own VNet?**

**A:** They COULD, but then:
- ❌ Each team reinvents networking (code duplication)
- ❌ Security rules might be different (governance lost)
- ❌ IP ranges might conflict (management nightmare)
- ❌ No central control (chaos)

**Better:** Platform creates standardized VNets, teams focus on apps!

### **Q: What if I need different networking settings?**

**A:** Ask Platform team to update `infra/envs/dev/main.tf`. They add the settings, you read them via data sources. Governance maintained!

### **Q: Can Pattern 2 work without Pattern 1?**

**A:** No! Pattern 2 depends on Pattern 1 creating the VNets first. Deploy Pattern 1 first!

### **Q: What does 'data source' mean?**

**A:** 
- `resource` = CREATE something
- `data` = READ something that already exists

```hcl
# CREATE a VNet (Platform team)
resource "azurerm_virtual_network" "crm" {
  name     = "vnet-contoso-dev-crm-001"
  address_space = ["10.2.0.0/16"]
  # ... lots of configuration
}

# READ that VNet (Your team)
data "azurerm_virtual_network" "crm" {
  name = "vnet-contoso-dev-crm-001"
  # No configuration needed - just read it!
}
```

---

## 📋 Quick Reference

| Concept | Pattern 1 | Pattern 2 |
|---------|-----------|-----------|
| **Who?** | Platform team | App teams (CRM, E-commerce) |
| **File?** | `infra/envs/dev/main.tf` | `examples/.../dev-app-*/main.tf` |
| **Creates VNets?** | ✅ YES (all 3 VNets!) | ❌ NO (reads via data sources) |
| **Creates Apps?** | ✅ Optional (shared AKS, CosmosDB) | ✅ YES (own apps) |
| **State file?** | `dev.terraform.tfstate` | `dev-app-crm.tfstate`, `dev-app-ecommerce.tfstate` |
| **Deploy order?** | FIRST | SECOND (after Pattern 1) |

---

## 🎯 Key Takeaway

**ONE file creates networking for BOTH patterns:**

```
infra/envs/dev/main.tf
├── module "networking"           → Pattern 1 VNet (10.1.x)
├── module "networking_crm"       → Pattern 2 CRM VNet (10.2.x)
└── module "networking_ecommerce" → Pattern 2 E-commerce VNet (10.3.x)
```

**Pattern 2 teams just READ and build apps!** 🚀
