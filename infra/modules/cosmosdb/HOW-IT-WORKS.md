# Cosmos DB - How It Works

A beginner-friendly guide to Azure Cosmos DB. No database experience required!

---

## What is Cosmos DB?

**Simple explanation:** Cosmos DB is like a magical filing cabinet that can store anything, find it instantly, and make copies of itself around the world.

```
Traditional Database:           Cosmos DB:
────────────────────           ───────────
One location                   Copies everywhere in the world
Fixed structure (tables)       Flexible structure (any shape)
Slower as data grows          Fast no matter how much data
You manage scaling            Azure handles scaling
```

### Real-World Analogy

Think of Cosmos DB like a global chain of identical libraries:

| Traditional Database | Cosmos DB |
|---------------------|-----------|
| One library in one city | Same library in every city |
| Walk across town to visit | Walk to nearest location |
| If that library burns down, books are gone | Other copies exist |
| Fixed catalog system | Organize books however you want |

---

## Key Concepts (Plain English)

### 1. Account
Your Cosmos DB subscription. Think of it as **owning the library chain**.

### 2. Database
A logical grouping of containers. Think of it as **one library building**.

### 3. Container
Where your data actually lives. Think of it as **a section of the library** (fiction, non-fiction, etc.).

### 4. Item
A single piece of data (JSON document). Think of it as **one book**.

### 5. Partition Key
How Cosmos DB organizes data. Think of it as **which shelf a book goes on**.

```
┌─────────────────────────────────────────────────────────────────┐
│                    COSMOS DB ACCOUNT                             │
│                  (The Library Chain)                             │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                DATABASE: myapp-db                        │   │
│   │               (One Library Building)                     │   │
│   │                                                          │   │
│   │   ┌─────────────────────┐  ┌─────────────────────┐      │   │
│   │   │  CONTAINER: users   │  │ CONTAINER: orders   │      │   │
│   │   │  (Non-Fiction)      │  │ (Fiction)           │      │   │
│   │   │                     │  │                     │      │   │
│   │   │  Partition Key:     │  │ Partition Key:      │      │   │
│   │   │    /userId          │  │   /customerId       │      │   │
│   │   │                     │  │                     │      │   │
│   │   │  ┌──────────────┐   │  │ ┌──────────────┐   │      │   │
│   │   │  │ ITEM (User1) │   │  │ │ITEM (Order1) │   │      │   │
│   │   │  │ {            │   │  │ │{             │   │      │   │
│   │   │  │  "userId":"1"│   │  │ │ "orderId":1, │   │      │   │
│   │   │  │  "name":"Jo" │   │  │ │ "customerId":│   │      │   │
│   │   │  │ }            │   │  │ │   "123"      │   │      │   │
│   │   │  └──────────────┘   │  │ │}             │   │      │   │
│   │   │                     │  │ └──────────────┘   │      │   │
│   │   └─────────────────────┘  └─────────────────────┘      │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Why Cosmos DB? (The Problem It Solves)

### Traditional Database Challenges

```
Problem 1: Users worldwide, database in one place
────────────────────────────────────────────────
User in USA     ───(fast)──→     Database in USA
User in Japan   ───(slow)──→     Database in USA  ← 200ms+ latency!
User in Europe  ───(slow)──→     Database in USA
```

```
Problem 2: Data grows, queries slow down
─────────────────────────────────────────
1,000 records:    Query takes 10ms   ✓
1,000,000 records: Query takes 2s    ✗
1,000,000,000:     Query times out   ✗✗✗
```

### Cosmos DB Solution

```
Solution 1: Global Distribution
──────────────────────────────
User in USA     ───(fast)──→     Cosmos DB replica in USA
User in Japan   ───(fast)──→     Cosmos DB replica in Japan
User in Europe  ───(fast)──→     Cosmos DB replica in Europe

(All replicas stay in sync automatically!)
```

```
Solution 2: Automatic Partitioning
──────────────────────────────────
1,000 records:       Query takes 10ms
1,000,000 records:   Query takes 10ms   ← Same speed!
1,000,000,000:       Query takes 10ms   ← Still the same!

(Cosmos DB spreads data across partitions automatically)
```

---

## The Partition Key: Most Important Decision

### What is a Partition Key?

It's the field Cosmos DB uses to decide WHERE to store each item.

```
Example: Users container with partition key = /country

Partition "USA"          Partition "Japan"        Partition "UK"
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ {               │      │ {               │      │ {               │
│  "userId": "1", │      │  "userId": "2", │      │  "userId": "3", │
│  "country":"USA"│      │  "country":"JP" │      │  "country":"UK" │
│ }               │      │ }               │      │ }               │
│ {               │      │ {               │      └─────────────────┘
│  "userId": "4", │      │  "userId": "5", │
│  "country":"USA"│      │  "country":"JP" │
│ }               │      │ }               │
└─────────────────┘      └─────────────────┘
```

### How to Choose a Good Partition Key

**Good partition keys:**
- Have many different values (high cardinality)
- Spread data evenly
- Match your query patterns

```
Good Examples:
─────────────
/userId          ← Good for user-centric apps
/tenantId        ← Good for multi-tenant SaaS
/deviceId        ← Good for IoT
/customerId      ← Good for e-commerce

Bad Examples:
─────────────
/country         ← Only ~200 values, uneven distribution
/status          ← Only 3-5 values (active, inactive, etc.)
/createdDate     ← Creates "hot" partition for today's data
```

### Why Partition Key Matters

```
Query: "Find all orders for customer 123"

With good partition key (/customerId):
─────────────────────────────────────
Cosmos DB looks at ONE partition
→ Super fast! (~10ms)

With bad partition key (/country):
─────────────────────────────────────
Cosmos DB looks at ALL partitions
→ Slow! (~100-1000ms)
→ Costs more RUs!
```

---

## Request Units (RUs): Understanding Costs

### What are RUs?

RUs = "Request Units" = A measure of how much work Cosmos DB does.

Think of RUs like electricity:
- Reading a small document = 1 RU (like turning on a light)
- Complex query = 10-100 RUs (like running the dishwasher)
- Writing data = 5-10 RUs (like using the microwave)

### How RU Pricing Works

```
Provisioned Throughput (Predictable costs):
───────────────────────────────────────────
You pay for: 400 RU/s minimum (~$24/month)
You get: Up to 400 operations per second

Scale up when needed:
1000 RU/s = ~$58/month
10000 RU/s = ~$580/month
```

```
Serverless (Pay per request):
─────────────────────────────
You pay for: Exactly what you use
Good for: Unpredictable or low traffic
Price: ~$0.25 per million RUs
```

### Estimating RUs

| Operation | Approximate RUs |
|-----------|-----------------|
| Read 1KB document by ID | 1 RU |
| Read 1KB document by query | 2-3 RU |
| Write 1KB document | 5-10 RU |
| Delete 1KB document | 5-10 RU |
| Complex query (no index) | 100+ RU |

---

## How Data Flows: Reading and Writing

### Writing Data

```
Your App                           Cosmos DB
────────                           ─────────
    │
    │ "Save this order"
    │ POST { "orderId": "123", "customerId": "C1", ... }
    │
    │ ───────────────────────────────────────────────────────→
    │
    │                              1. Cosmos DB receives request
    │                              2. Looks at partition key (/customerId)
    │                              3. Routes to correct partition
    │                              4. Writes data
    │                              5. Replicates to other regions
    │
    │ ←───────────────────────────────────────────────────────
    │
    │ "Success! Here's the saved document"
    │
```

### Reading Data (Point Read - Fastest)

```
Your App                           Cosmos DB
────────                           ─────────
    │
    │ "Get order with ID 123 for customer C1"
    │ GET /orders/123?partitionKey=C1
    │
    │ ───────────────────────────────────────────────────────→
    │
    │                              1. Goes directly to partition "C1"
    │                              2. Finds item with ID "123"
    │                              3. Returns it (just 1 RU!)
    │
    │ ←───────────────────────────────────────────────────────
    │
    │ "Here's your order"
    │
```

### Reading Data (Query - Slower)

```
Your App                           Cosmos DB
────────                           ─────────
    │
    │ "Find all orders over $100"
    │ SELECT * FROM orders WHERE total > 100
    │
    │ ───────────────────────────────────────────────────────→
    │
    │                              1. Must scan MULTIPLE partitions
    │                              2. Check each document
    │                              3. Return matches (10-100+ RUs!)
    │
    │ ←───────────────────────────────────────────────────────
    │
    │ "Here are 47 orders (cost: 50 RUs)"
    │
```

---

## Connecting to Cosmos DB Securely

### The Problem with Connection Strings

```
Bad: Storing connection string in code
────────────────────────────────────
const connectionString = "AccountEndpoint=https://...;AccountKey=abc123..."

Problems:
- If code is leaked, database is compromised
- Hard to rotate keys
- Key in logs, error messages
```

### The Solution: Managed Identity

```
┌─────────────────────────────────────────────────────────────────┐
│                      YOUR APP (in AKS)                           │
│                                                                  │
│   // No connection string needed!                                │
│   const credential = new DefaultAzureCredential();              │
│   const client = new CosmosClient({ endpoint, credential });    │
│                                                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ "I'm App X, verified by Azure AD"
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                       COSMOS DB                                  │
│                                                                  │
│   Access Control (RBAC):                                        │
│   ✅ App X can read/write to "orders" container                │
│   ❌ App X cannot delete database                               │
│   ❌ App X cannot access "admin" container                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Benefits:**
- No secrets to manage
- Fine-grained permissions
- Automatic credential rotation
- Full audit trail

---

## Network Security: Private Access Only

### How We Secure Cosmos DB

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
│                                                                  │
│                    Can reach Cosmos DB?                          │
│                           ❌ NO                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    YOUR VNET (10.1.0.0/16)                       │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                   AKS SUBNET                             │   │
│   │                                                          │   │
│   │   Your App ──────────────────────────────────────────┐  │   │
│   │                                                       │  │   │
│   └───────────────────────────────────────────────────────┼──┘   │
│                                                           │      │
│                          Private Endpoint                 │      │
│                               │                           │      │
│   ┌───────────────────────────┼───────────────────────────┼──┐   │
│   │                DATA SUBNET│                           │  │   │
│   │                           ▼                           │  │   │
│   │              ┌─────────────────────────┐              │  │   │
│   │              │     COSMOS DB           │◄─────────────┘  │   │
│   │              │  (Private IP: 10.1.3.5) │                 │   │
│   │              │                         │                 │   │
│   │              │  Only accepts traffic   │                 │   │
│   │              │  from this VNet!        │                 │   │
│   │              └─────────────────────────┘                 │   │
│   │                                                          │   │
│   └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Using the Module

### Basic Example

```hcl
module "cosmosdb" {
  source = "../../modules/cosmosdb"

  account_name        = "myapp-cosmos-dev"
  location            = "eastus"
  resource_group_name = module.landing_zone.resource_group_name

  # Database and container
  database_name  = "myapp-db"
  container_name = "orders"
  partition_key  = "/customerId"  # Choose wisely!

  # Throughput
  throughput = 400  # Minimum, ~$24/month

  # Security: Only allow access from VNet
  virtual_network_rules = [
    module.landing_zone.subnet_ids["app-subnet"]
  ]

  tags = module.global_standards.common_tags
}
```

### With Multiple Containers

```hcl
module "cosmosdb" {
  source = "../../modules/cosmosdb"

  account_name = "myapp-cosmos-dev"
  # ...

  containers = {
    "users" = {
      partition_key = "/userId"
      throughput    = 400
    }
    "orders" = {
      partition_key = "/customerId"
      throughput    = 1000  # More traffic expected
    }
    "products" = {
      partition_key = "/categoryId"
      throughput    = 400
    }
  }
}
```

---

## Common Operations

### Insert a Document

```javascript
// JavaScript/Node.js
const { CosmosClient } = require("@azure/cosmos");

const client = new CosmosClient({ endpoint, credential });
const container = client.database("myapp-db").container("orders");

// Insert
const order = {
  id: "order-123",
  customerId: "customer-456",  // This is the partition key!
  items: [...],
  total: 99.99
};

const { resource } = await container.items.create(order);
console.log("Created:", resource.id);
```

### Read a Document (Point Read)

```javascript
// Fast read - provide both ID and partition key
const { resource } = await container.item("order-123", "customer-456").read();
console.log("Order:", resource);
// Cost: 1 RU
```

### Query Documents

```javascript
// Query (more expensive)
const query = "SELECT * FROM orders o WHERE o.total > 100";
const { resources } = await container.items.query(query).fetchAll();
console.log("Found:", resources.length, "orders");
// Cost: Depends on data scanned
```

---

## Troubleshooting

### "Request rate too large" (429 Error)

```
Problem: You're exceeding your provisioned RUs

Solutions:
1. Increase throughput (more RUs)
2. Optimize queries (use partition key in WHERE clause)
3. Enable autoscale
4. Implement retry logic with backoff
```

### "Partition key not found"

```
Problem: You're querying without the partition key

Before (slow, expensive):
  SELECT * FROM c WHERE c.orderId = "123"

After (fast, cheap):
  SELECT * FROM c WHERE c.customerId = "C1" AND c.orderId = "123"
```

### "Cross-partition query"

```
Problem: Query spans multiple partitions

Solution: Include partition key in query or accept higher cost

// Bad - scans all partitions
SELECT * FROM c WHERE c.status = "pending"

// Good - only scans one partition  
SELECT * FROM c WHERE c.customerId = "C1" AND c.status = "pending"
```

---

## Cost Optimization Tips

### 1. Right-size your throughput

```
Development:     400 RU/s (~$24/month)
Small production: 1000 RU/s (~$58/month)
Medium:          4000 RU/s (~$232/month)

Use autoscale for variable workloads!
```

### 2. Use serverless for dev/test

```
Serverless pricing:
- $0.25 per million RU consumed
- No minimum cost

Good for: Dev environments, infrequent access
```

### 3. Optimize your partition key

```
Good partition key = Lower RU costs
- Queries stay in one partition
- No cross-partition queries
- Even data distribution
```

### 4. Use TTL for temporary data

```javascript
// Automatically delete after 30 days
const session = {
  id: "session-123",
  userId: "user-456",
  ttl: 2592000  // 30 days in seconds
};
```

---

## Summary

**Cosmos DB is:**
- A globally distributed NoSQL database
- Automatically scales and replicates
- Always fast, no matter how much data

**Key concepts:**
- Account → Database → Container → Item
- Partition key determines data location
- RUs measure and limit operations

**Best practices:**
- Choose partition key wisely (can't change later!)
- Use Managed Identity (no connection strings)
- Secure with VNet integration
- Monitor RU consumption

**Perfect for:**
- Global applications
- High-scale workloads
- Flexible schema requirements
- Real-time data access
