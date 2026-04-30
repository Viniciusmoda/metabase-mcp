.PHONY: help up down restart logs logs-metabase logs-postgres logs-ollama logs-webui \
        ps setup pull-model shell-postgres reset update

OLLAMA_MODEL ?= llama3.2

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Copy .env.example to .env (run once before first start)
	cp .env.example .env
	@echo "Edit .env before starting: nano .env"

up: ## Start all services in the background
	docker compose up -d

down: ## Stop all services (keeps data volumes)
	docker compose down

restart: ## Restart all services
	docker compose restart

ps: ## Show status of all containers
	docker compose ps

logs: ## Tail logs for all services
	docker compose logs -f

logs-metabase: ## Tail Metabase logs
	docker compose logs -f metabase

logs-postgres: ## Tail PostgreSQL logs
	docker compose logs -f postgres

logs-ollama: ## Tail Ollama logs
	docker compose logs -f ollama

logs-webui: ## Tail Open WebUI logs
	docker compose logs -f open-webui

pull-model: ## Pull an Ollama model (default: llama3.2). Override with: make pull-model OLLAMA_MODEL=mistral
	docker exec -it ollama ollama pull $(OLLAMA_MODEL)

list-models: ## List downloaded Ollama models
	docker exec -it ollama ollama list

shell-postgres: ## Open a psql shell on the PostgreSQL container
	docker exec -it metabase-postgres psql -U metabase_user -d metabase_db

reset: ## Destroy all containers AND data volumes, then restart fresh
	docker compose down -v
	docker compose up -d

update: ## Pull latest images and restart
	git pull
	docker compose pull
	docker compose up -d
# ONLY FOR TESTING DON"T USE IN PRODUCTION
# ---------------------------------------------------------------------------
# GCP helpers — values are auto-detected from the GCP metadata server when
# running on a GCP VM. Override on the command line if needed:
#   make gcp-ssh GCP_VM=my-vm GCP_ZONE=us-central1-a
# ---------------------------------------------------------------------------
GCP_VM   ?= $(shell curl -sf -H "Metadata-Flavor: Google" \
               http://metadata.google.internal/computeMetadata/v1/instance/name \
               2>/dev/null || echo "YOUR_VM_NAME")
GCP_ZONE ?= $(shell curl -sf -H "Metadata-Flavor: Google" \
               http://metadata.google.internal/computeMetadata/v1/instance/zone \
               2>/dev/null | awk -F/ '{print $$NF}' || echo "YOUR_ZONE")

gcp-firewall: ## Create GCP firewall rule to open ports 3000, 8080, 11434
	gcloud compute firewall-rules create metabase-mcp-allow \
	  --allow tcp:3000,tcp:8080,tcp:11434 \
	  --target-tags metabase-mcp \
	  --description "Metabase MCP stack ports"
	gcloud compute instances add-tags $(GCP_VM) \
	  --tags metabase-mcp \
	  --zone $(GCP_ZONE)

gcp-ssh: ## SSH into the GCP VM
	gcloud compute ssh $(GCP_VM) --zone $(GCP_ZONE)

gcp-ip: ## Print the external IP of the GCP VM
	@gcloud compute instances describe $(GCP_VM) \
	  --zone $(GCP_ZONE) \
	  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

gcp-install-docker: ## Install Docker and Docker Compose on the GCP VM via SSH
	gcloud compute ssh $(GCP_VM) --zone $(GCP_ZONE) --command \
	  "sudo apt-get update && sudo apt-get upgrade -y && \
	   curl -fsSL https://get.docker.com | sudo sh && \
	   sudo usermod -aG docker \$$USER && \
	   sudo apt-get install -y docker-compose-plugin"

gcp-deploy: ## Clone/update the repo and start the stack on the GCP VM
	gcloud compute ssh $(GCP_VM) --zone $(GCP_ZONE) --command \
	  "if [ -d metabase-mcp ]; then \
	     cd metabase-mcp && git pull && docker compose pull && docker compose up -d; \
	   else \
	     git clone https://github.com/Viniciusmoda/metabase-mcp.git && \
	     cd metabase-mcp && cp .env.example .env && docker compose up -d; \
	   fi"

gcp-ps: ## Show container status on the GCP VM
	gcloud compute ssh $(GCP_VM) --zone $(GCP_ZONE) --command \
	  "cd metabase-mcp && docker compose ps"

gcp-logs: ## Tail all logs on the GCP VM
	gcloud compute ssh $(GCP_VM) --zone $(GCP_ZONE) --command \
	  "cd metabase-mcp && docker compose logs -f"

gcp-pull-model: ## Pull an Ollama model on the GCP VM (default: llama3.2)
	gcloud compute ssh $(GCP_VM) --zone $(GCP_ZONE) --command \
	  "docker exec -it ollama ollama pull $(OLLAMA_MODEL)"
