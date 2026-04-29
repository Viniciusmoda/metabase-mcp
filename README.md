# Metabase with PostgreSQL - Docker Compose Setup

This project sets up a complete Metabase analytics environment with PostgreSQL as the database, including sample data for testing and exploration. It also includes **Open WebUI** as an AI chat client connected to Metabase via the **Model Context Protocol (MCP)**, enabling natural language queries against your data.

## What's Included

- **Metabase**: Open-source business intelligence tool with MCP server enabled
- **PostgreSQL**: Database with pre-loaded sample data
- **Ollama**: Local LLM runtime for running AI models
- **Open WebUI**: AI chat interface acting as an MCP client for Metabase
- **Sample Data**: E-commerce dataset with customers, products, orders, and analytics views

## Quick Start

1. **Clone or navigate to this directory**
   ```bash
   cd /path/to/metabase-ai
   ```

2. **Start the services**
   ```bash
   docker-compose up -d
   ```

3. **Access Metabase**
   - Open your browser and go to http://localhost:3000
   - Follow the setup wizard
   - When prompted for database connection, use the credentials below

## Database Connection Details

When setting up Metabase, use these connection details for the PostgreSQL database:

- **Database Type**: PostgreSQL
- **Host**: `postgres` (or `localhost` if connecting from outside Docker)
- **Port**: `5432`
- **Database Name**: `metabase_db`
- **Username**: `metabase_user`
- **Password**: `metabase_password_123`

## Sample Data Structure

### Sales Schema
- **customers**: Customer information (10 sample customers)
- **products**: Product catalog (10 sample products across different categories)
- **orders**: Order history (20 sample orders across Q1 2024)
- **order_items**: Individual items within each order

### Analytics Schema
- **daily_sales**: Daily sales aggregations
- **monthly_sales**: Monthly sales view
- **product_performance**: Product performance metrics
- **customer_analytics**: Customer behavior analytics

## Environment Variables

The `.env` file contains the following configurable variables:

```env
POSTGRES_DB=metabase_db
POSTGRES_USER=metabase_user
POSTGRES_PASSWORD=metabase_password_123
MB_ENCRYPTION_SECRET_KEY=your-secret-key-here-change-this-in-production
WEBUI_SECRET_KEY=your-open-webui-secret-key-change-this
```

## Open WebUI + Metabase MCP Setup

### Architecture

```
Open WebUI  ──► Ollama (port 11434)
(port 8080)         └── local LLM models
    │
    │  MCP Streamable HTTP  (x-api-key header)
    ▼
Metabase (port 3000)  ──►  PostgreSQL (port 5432)
    └── /api/mcp endpoint
```

---

### Step 1 – Access Ollama and pull a model

Ollama is available on **http://localhost:11434**.

Pull a model via the CLI (the model is stored in the `ollama_data` Docker volume):

```bash
docker exec -it ollama ollama pull llama3.2
```

Verify the model downloaded successfully:

```bash
docker exec -it ollama ollama list
```

You can also list or pull models later directly from the Open WebUI admin panel (Step 3 below).

> **macOS GPU note**: The Ollama Docker container runs on CPU only. For Metal/GPU acceleration, install the [Ollama native app](https://ollama.com/download), then change the `open-webui` service environment variable in `docker-compose.yml`:
> ```yaml
> OLLAMA_BASE_URL: http://host.docker.internal:11434
> ```
> Restart Open WebUI after: `docker-compose restart open-webui`

---

### Step 2 – Access Open WebUI and connect it to Ollama

1. Open **http://localhost:8080** in your browser.
2. On first launch, create your admin account (username + password).
3. Open WebUI automatically connects to Ollama at `http://ollama:11434` (pre-configured via `OLLAMA_BASE_URL`). You should see available models in the model selector at the top of the chat.

To verify the Ollama connection:
1. Click your profile icon → **Admin Panel**
2. Go to **Settings → Connections**
3. The Ollama API entry should show a green indicator at `http://ollama:11434`

If the connection shows red, click the refresh icon or re-enter the URL and save.

---

### Step 3 – Generate a Metabase API key

1. Open **http://localhost:3000** and log in to Metabase.
2. Click the gear icon → **Admin Settings** → **API Keys** tab.
3. Click **Create API Key**, give it a name (e.g. `open-webui`), and copy the generated key.

---

### Step 4 – Register Metabase as an MCP Tool Server in Open WebUI

1. In Open WebUI, click your profile icon → **Admin Panel**.
2. Go to **Settings → Tools**.
3. Click **Add Connection** (or the `+` button) and fill in:
   - **URL**: `http://metabase-app:3000/api/mcp`
   - **API Key**: paste the key from Step 3
4. Click **Save** — Open WebUI will contact the MCP endpoint and discover all available Metabase tools automatically.

> The URL uses the Docker service hostname `metabase-app` so the request stays inside the Docker network. Do **not** use `localhost:3000` here.

---

### Step 5 – Chat with your data

1. Open a new chat in Open WebUI and select the model you pulled in Step 1.
2. Click the **Tools** icon (wrench / plug) in the chat toolbar and enable the Metabase tools.
3. Ask natural-language questions:

   - *"How many customers do we have?"*
   - *"Show me the top 5 products by revenue this month"*
   - *"What was the total revenue in Q1 2024?"*
   - *"Which customers have spent the most overall?"*

The model will call Metabase MCP tools to execute queries and return results inline.

---


## Useful Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f metabase
docker-compose logs -f postgres
```

### Connect to PostgreSQL directly
```bash
docker exec -it metabase-postgres psql -U metabase_user -d metabase_db
```

### Reset everything (removes data)
```bash
docker-compose down -v
docker-compose up -d
```

## Sample Queries to Try in Metabase

Once you've connected Metabase to the database, try these queries:

1. **Total Revenue by Month**
   ```sql
   SELECT month, total_revenue 
   FROM analytics.monthly_sales 
   ORDER BY month;
   ```

2. **Top Selling Products**
   ```sql
   SELECT product_name, times_sold, total_revenue 
   FROM analytics.product_performance 
   WHERE times_sold > 0 
   ORDER BY total_revenue DESC;
   ```

3. **Customer Lifetime Value**
   ```sql
   SELECT first_name, last_name, total_orders, total_spent 
   FROM analytics.customer_analytics 
   WHERE total_orders > 0 
   ORDER BY total_spent DESC;
   ```

## Troubleshooting

### Metabase won't start
- Check if port 3000 is already in use
- Ensure PostgreSQL is running and accessible
- Check logs: `docker-compose logs metabase`

### Can't connect to database
- Verify the database credentials in the `.env` file
- Ensure PostgreSQL container is running: `docker-compose ps`
- Check PostgreSQL logs: `docker-compose logs postgres`

### Ollama models not showing in Open WebUI
- Confirm a model has been pulled: `docker exec -it ollama ollama list`
- Check the Ollama connection in **Admin Panel → Settings → Connections** — it should point to `http://ollama:11434`
- Check Ollama logs: `docker-compose logs ollama`

### Open WebUI can't reach Metabase MCP
- Confirm Metabase is healthy: `docker-compose ps metabase`
- The MCP URL must use the Docker hostname `http://metabase-app:3000/api/mcp`, not `localhost`
- Verify the API key is valid by testing directly:
  ```bash
  curl -s -X POST http://localhost:3000/api/mcp \
    -H "Content-Type: application/json" \
    -H "x-api-key: <YOUR_API_KEY>" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
  ```

### Reset Metabase setup
If you need to restart the Metabase setup process:
```bash
docker-compose down -v
docker volume rm metabase-ai_metabase_data
docker-compose up -d
```

## Production Notes

Before using in production:
1. Change all passwords in the `.env` file
2. Generate a secure `MB_ENCRYPTION_SECRET_KEY`
3. Configure proper backup strategies
4. Set up SSL/TLS certificates
5. Configure proper network security

## Data Sources for Exploration

The sample data includes:
- **Electronics**: Laptops, smartphones, headphones, smart watches
- **Home & Garden**: Coffee makers, desk lamps
- **Furniture**: Office chairs
- **Sports**: Running shoes
- **Books**: Technology books
- **Fashion**: Backpacks

You can create dashboards showing:
- Sales trends over time
- Product category performance
- Customer segmentation
- Revenue analytics
- Order patterns

Happy exploring with Metabase! 🚀