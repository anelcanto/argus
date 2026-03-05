.PHONY: setup server test lint format db.create db.migrate db.reset db.drop deps assets

setup: ## Install deps, create and migrate DB, setup assets
	mix setup

server: ## Start Phoenix dev server
	mix phx.server

test: ## Run tests
	mix test

lint: ## Run Credo static analysis
	mix credo

format: ## Format Elixir code
	mix format

db.create: ## Create the database
	mix ecto.create

db.migrate: ## Run migrations
	mix ecto.migrate

db.reset: ## Drop and recreate the database
	mix ecto.reset

db.drop: ## Drop the database
	mix ecto.drop

db.seed: ## Run seeds
	mix run priv/repo/seeds.exs

deps: ## Fetch dependencies
	mix deps.get

assets: ## Build assets (tailwind + esbuild)
	mix assets.build

assets.deploy: ## Build and digest assets for production
	mix assets.deploy

routes: ## List all routes
	mix phx.routes

iex: ## Start IEx with the app
	iex -S mix phx.server

help: ## Show this help
	@grep -E '^[a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
