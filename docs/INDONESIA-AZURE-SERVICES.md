# Azure Services Availability for Indonesia

## Recommended Region: Southeast Asia (Singapore)

**Location Code**: `southeastasia`

Southeast Asia (Singapore) is the recommended Azure region for Indonesia deployments because:
- ✅ Geographically closest (latency ~10-30ms from Jakarta)
- ✅ Full service availability
- ✅ Availability Zones supported
- ✅ All enterprise features available
- ✅ Data residency compliance for ASEAN

---

## Service SKU Recommendations for Indonesia

All SKUs below are **verified available** in Southeast Asia region and optimized for cost while maintaining functionality.

### 1. Azure Kubernetes Service (AKS)

| Environment | SKU | vCPU | RAM | Cost/Month (approx) | Use Case |
|-------------|-----|------|-----|---------------------|----------|
| **Dev** | `Standard_D2s_v3` | 2 | 8 GB | ~$70 | Minimal but functional for testing |
| **Staging** | `Standard_D4s_v3` | 4 | 16 GB | ~$140 | Production-like testing |
| **Prod** | `Standard_D4s_v3` | 4 | 16 GB | ~$140 per node | Reliable performance |
| **Prod (High)** | `Standard_D8s_v3` | 8 | 32 GB | ~$280 per node | High-performance workloads |

**Why D-series v3?**
- ✅ Widely available
- ✅ Good price/performance ratio
- ✅ Supports Premium Storage
- ✅ Proven for production workloads

**Avoid:**
- ❌ `Standard_B*` series - Too small for AKS, will have issues
- ❌ `*_v5` or `*_v6` - Limited availability in some regions
- ❌ `Standard_DS1_v2` - Deprecated, too small

---

### 2. Azure Cosmos DB

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| **Consistency Level** | `Session` | `Session` | `Session` or `BoundedStaleness` |
| **Throughput RU/s** | 400 (min) | 400-1000 | Autoscale 1000-10000 |
| **Backup Type** | `Periodic` | `Periodic` | `Continuous` |
| **Backup Redundancy** | `Local` | `Local` | `Local` or `Zone` |
| **Multi-region** | No | No | Yes (add East Asia) |

**Important for Southeast Asia:**
- ✅ `Local` backup redundancy works in all scenarios
- ⚠️ `Geo` redundancy may have limitations
- ✅ Multi-region: Southeast Asia (primary) + East Asia (secondary) for Asia coverage

**Minimum RU/s:** Always use at least 400 RU/s (you cannot go lower)

---

### 3. PostgreSQL Flexible Server

| Environment | SKU | vCPU | RAM | Storage | Cost/Month |
|-------------|-----|------|-----|---------|------------|
| **Dev** | `B_Standard_B1ms` | 1 (burst) | 2 GB | 32 GB | ~$15 |
| **Staging** | `B_Standard_B2s` | 2 (burst) | 4 GB | 64 GB | ~$35 |
| **Prod** | `GP_Standard_D2s_v3` | 2 | 8 GB | 128 GB | ~$120 |
| **Prod (High)** | `GP_Standard_D4s_v3` | 4 | 16 GB | 256 GB | ~$240 |

**SKU Tiers:**
- **B (Burstable)** - Dev/test, workloads that don't need continuous full CPU
- **GP (General Purpose)** - Production, balanced compute and memory
- **MO (Memory Optimized)** - High memory requirements

**PostgreSQL Versions:** 13, 14, 15, 16 (recommend: 16)

**High Availability:**
- Dev: Disabled
- Staging: `SameZone` (optional)
- Prod: `ZoneRedundant` (recommended)

---

### 4. Azure Container Apps

| Environment | Pricing Mode | vCPU | RAM | Instances |
|-------------|-------------|------|-----|-----------|
| **Dev** | Consumption | 0.25-0.5 | 0.5-1 GB | 1 |
| **Staging** | Consumption | 0.5-1 | 1-2 GB | 1-3 |
| **Prod** | Consumption | 1-2 | 2-4 GB | 2-10 |

**Notes:**
- ✅ Consumption plan available in Southeast Asia
- ✅ Auto-scales to zero (save cost)
- ✅ Pay only for actual usage
- No need for Container App Environment redundancy in dev

---

### 5. Azure App Service (Web Apps)

| Environment | SKU | vCPU | RAM | Cost/Month | Features |
|-------------|-----|------|-----|------------|----------|
| **Dev** | `F1` (Free) | Shared | 1 GB | $0 | Good for testing |
| **Dev** | `B1` (Basic) | 1 | 1.75 GB | ~$13 | Custom domain, SSL |
| **Staging** | `S1` (Standard) | 1 | 1.75 GB | ~$70 | Staging slots, auto-scale |
| **Prod** | `P1V2` (Premium) | 1 | 3.5 GB | ~$80 | VNet integration |
| **Prod (High)** | `P2V2` (Premium) | 2 | 7 GB | ~$160 | Better performance |

**Recommended:**
- Dev: `B1` (avoid F1 - too limited)
- Staging: `S1` 
- Prod: `P1V2` or `P1V3`

---

### 6. Azure Storage Account

| Redundancy | Code | Availability | Cost | When to Use |
|------------|------|--------------|------|-------------|
| **Locally Redundant** | `LRS` | 99.999999999% (11 9's) | Cheapest | Dev, non-critical data |
| **Zone Redundant** | `ZRS` | 99.9999999999% (12 9's) | +50% | Prod, same-region HA |
| **Geo Redundant** | `GRS` | 99.99999999999999% (16 9's) | +100% | Prod, disaster recovery |

**Performance Tiers:**
- **Standard** - HDD-backed, good for most workloads
- **Premium** - SSD-backed, low latency (use for VM disks only)

**Recommendations:**
- Dev: `Standard_LRS`
- Staging: `Standard_LRS` or `Standard_ZRS`
- Prod: `Standard_ZRS` or `Standard_GRS`

---

### 7. Azure SQL Database

| Environment | SKU | DTU/vCore | Storage | Cost/Month |
|-------------|-----|-----------|---------|------------|
| **Dev** | `Basic` | 5 DTU | 2 GB | ~$5 |
| **Dev** | `S0` | 10 DTU | 250 GB | ~$15 |
| **Staging** | `S1` | 20 DTU | 250 GB | ~$30 |
| **Prod** | `S2` | 50 DTU | 250 GB | ~$75 |
| **Prod** | `GP_Gen5_2` | 2 vCore | 32 GB | ~$330 |

**Model Recommendations:**
- Dev/Staging: DTU model (simpler, cheaper)
- Prod: vCore model (more predictable, better control)

---

### 8. Azure Key Vault

| SKU | Cost | Features | When to Use |
|-----|------|----------|-------------|
| **Standard** | ~$0.03/10k ops | Software-protected keys | Dev, Staging, most Prod |
| **Premium** | ~$1.00/month + ops | HSM-protected keys | High-security Prod, compliance |

**Recommendation:** `Standard` is sufficient for 99% of use cases

---

## Network Service SKUs

### NAT Gateway
- **SKU**: `Standard` (only option)
- **Cost**: ~$33/month + $0.045/GB processed
- **When to use**: Production; skip in dev to save cost

### Load Balancer
- **Basic**: Free, but no SLA
- **Standard**: ~$18/month + data processing
- **Recommendation**: Standard for production

### DDoS Protection
- **SKU**: `Standard` (only option)
- **Cost**: ~$2,944/month (expensive!)
- **When to use**: Only for critical production with high attack risk
- **Alternative**: Use Azure Front Door or Application Gateway (includes basic DDoS)

---

## Cost Optimization Tips for Indonesia Deployment

### 1. Use Reserved Instances
- Save 30-60% on compute (AKS, VMs, App Service)
- Commit to 1-year or 3-year terms
- Good for production workloads

### 2. Auto-scaling
- Container Apps: Scale to zero when not used
- AKS: Use cluster autoscaler (min: 1, max: 10)
- App Service: Scale based on CPU/memory metrics

### 3. Dev/Test Pricing
- Use Azure Dev/Test subscription (up to 40% off)
- Must be used only for non-production

### 4. Spot Instances (AKS)
- Use spot node pools for dev (save up to 90%)
- Not recommended for production (can be evicted)

### 5. Storage Lifecycle Management
- Move old data to Cool/Archive tiers
- Set retention policies
- Use blob lifecycle policies

---

## Latency from Indonesia to Azure Regions

| Region | City | Typical Latency | Notes |
|--------|------|-----------------|-------|
| **Southeast Asia** | Singapore | 10-30 ms | ✅ **Recommended** |
| East Asia | Hong Kong | 50-80 ms | Secondary/failover |
| Japan East | Tokyo | 60-100 ms | Higher latency |
| Australia East | Sydney | 100-150 ms | Too far |
| West Europe | Netherlands | 200-250 ms | Too far for primary |

---

## Service Limits in Southeast Asia

All services have standard Azure limits. No special restrictions for Southeast Asia region.

**Key Limits:**
- AKS: Max 100 nodes per node pool, 1000 nodes per cluster
- Cosmos DB: Unlimited storage, RU/s scalable to millions
- PostgreSQL: Max 16 TB storage, up to 64 vCores
- Storage Account: 5 PB per account
- Key Vault: 25,000 secrets per vault

---

## Compliance & Data Residency

**Data at Rest Location:** 
- Primary: Singapore (Southeast Asia datacenter)
- Backup/GRS: If enabled, replicated to East Asia (Hong Kong)

**Certifications Available:**
- ISO 27001, ISO 27018
- SOC 1, SOC 2, SOC 3
- PCI DSS Level 1
- GDPR compliant

**ASEAN Compliance:**
- Data stays within ASEAN region (Singapore)
- Good for companies with data residency requirements

---

## Summary: Default SKUs for Indonesia Framework

Here's what the framework now uses by default:

```hcl
# Southeast Asia (Singapore) - closest to Indonesia
location = "southeastasia"

# AKS - Minimal but functional
aks_node_size = "Standard_D2s_v3"  # Dev: 2 vCPU, 8 GB
                "Standard_D4s_v3"  # Staging/Prod: 4 vCPU, 16 GB

# PostgreSQL - Burstable for dev, GP for prod
postgresql_sku = "B_Standard_B1ms"    # Dev
                 "GP_Standard_D2s_v3" # Prod

# Cosmos DB - Local backup redundancy
cosmosdb_backup_storage_redundancy = "Local"

# Storage - LRS for dev, ZRS for prod
storage_redundancy = "Standard_LRS"  # Dev
                     "Standard_ZRS"  # Prod

# App Service - Basic for dev, Premium for prod
app_service_sku = "B1"    # Dev
                  "P1V2"  # Prod

# Key Vault - Standard tier
key_vault_sku = "standard"
```

---

## Testing Service Availability

To verify a service is available in Southeast Asia:

```bash
# Check VM sizes
az vm list-sizes --location southeastasia --output table

# Check PostgreSQL versions
az postgres flexible-server list-skus --location southeastasia

# Check Cosmos DB capabilities
az cosmosdb locations list --output table

# Check AKS versions
az aks get-versions --location southeastasia --output table
```

---

**Last Updated:** February 2026  
**Region Tested:** Southeast Asia (Singapore)  
**All SKUs Verified:** Yes ✅
