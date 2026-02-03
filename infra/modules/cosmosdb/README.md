# Azure Cosmos DB Module

## Purpose
This module creates an Azure Cosmos DB account optimized for global distribution, high availability, and performance. It follows best practices for data modeling, partitioning, and security.

## Why This Module?
- **Global Distribution**: Multi-region replication for low latency worldwide
- **Scalability**: Supports hierarchical partition keys to overcome 20GB partition limits
- **Data Modeling**: Follows embedding and referencing patterns based on access patterns
- **Security**: VNet integration, private endpoints, and Azure AD authentication
- **Cost Optimization**: Autoscale throughput and efficient indexing
- **Observability**: Integrated diagnostics for monitoring query performance and RU consumption

## How It Works
1. Creates a Cosmos DB account with configurable consistency levels
2. Supports multiple geo-replicated regions with automatic failover
3. Creates SQL databases with shared or dedicated throughput
4. Creates containers with optimized partition keys and indexing policies
5. Enables diagnostic logging for query analysis and troubleshooting
6. Implements security controls based on environment requirements

## Data Modeling Best Practices (Built-in)

### Embedded Data Pattern
Use when:
- Data is always accessed together
- One-to-few relationships
- Data rarely changes independently

### Referenced Data Pattern
Use when:
- Data size grows unbounded (exceeds 2MB item limit)
- Data is updated frequently
- Many-to-many relationships

### Hierarchical Partition Keys (HPK)
- Enables scaling beyond 20GB per logical partition
- Improves query performance by limiting partition scans
- Example: `["/tenantId", "/userId", "/year"]`

## Resources Created
- Cosmos DB Account (with managed identity)
- SQL Databases with autoscale or manual throughput
- SQL Containers with partition keys and indexing policies
- Diagnostic settings for monitoring

## Usage Example

```hcl
module "cosmosdb" {
  source = "../../modules/cosmosdb"

  account_name      = "myapp-cosmos-prod"
  location          = "eastus"
  consistency_level = "Session"
  
  # Multi-region setup for production
  failover_locations = [
    {
      location          = "westus"
      failover_priority = 1
    }
  ]

  # Create databases and containers
  sql_databases = {
    "UserDatabase" = {
      autoscale_max_throughput = 4000
    }
  }

  sql_containers = {
    "users" = {
      database_name         = "UserDatabase"
      partition_key_paths   = ["/userId"]
      partition_key_version = 2
      autoscale_max_throughput = 1000
      
      # Optimize indexing
      indexing_mode   = "consistent"
      included_paths  = ["/*"]
      excluded_paths  = ["/largeField/?"]
    }
    
    "chatHistory" = {
      database_name         = "UserDatabase"
      partition_key_paths   = ["/tenantId", "/userId"] # Hierarchical
      partition_key_version = 2
      autoscale_max_throughput = 1000
      default_ttl           = 2592000  # 30 days TTL
    }
  }

  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Environment-Specific Configurations

### Development
- Single region deployment
- Lower throughput (400-1000 RU/s)
- Public network access enabled
- Periodic backup (every 240 min)

### Staging
- Two regions with automatic failover
- Moderate throughput (1000-4000 RU/s)
- VNet integration
- Periodic backup (every 60 min)

### Production
- Multi-region with multi-region writes
- High throughput with autoscale (4000+ RU/s)
- Private endpoints only
- Continuous backup for point-in-time restore
- Strong consistency if needed

## Recommended Use Cases

### AI/Chat Applications
- Chat history and conversation logging
- User context and memory
- RAG (Retrieval-Augmented Generation) pattern
- Low-cost vector search for semantic retrieval

### Transactional Applications
- User profiles and membership management
- Product catalogs
- Shopping carts and orders
- Real-time recommendations

### IoT Scenarios
- Device twins and profiles
- Current state and metadata
- Predictive maintenance data

## Monitoring and Optimization
- Use diagnostic logs to identify slow queries
- Monitor Request Units (RU) consumption
- Review partition key statistics for hotspots
- Enable query runtime statistics for optimization
- Use the Azure Cosmos DB VS Code extension for data inspection
