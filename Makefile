# --- Configuración Guayabita Roll ---
BACKEND_DIR=apps/backend
CONTRACTS_DIR=apps/contracts
FRONTEND_DIR=apps/frontend

.PHONY: setup dev test-backend test-contracts

# Configuración inicial
setup:
	@echo "🎲 Configurando Guayabita Roll..."
	cd $(BACKEND_DIR) && mix deps.get && mix ecto.setup
	cd $(CONTRACTS_DIR) && forge install
	cd $(FRONTEND_DIR) && npm install
	@echo "✅ Proyecto listo para rodar."

# Ejecutar servicios en paralelo (Backend, Frontend y Nodo Local)
dev:
	@echo "🔥 Lanzando el ecosistema Guayabita Roll..."
	make -j 3 run-backend run-frontend run-contracts

run-backend:
	cd $(BACKEND_DIR) && iex -S mix phx.server

run-frontend:
	cd $(FRONTEND_DIR) && npm run dev

run-contracts:
	cd $(CONTRACTS_DIR) && anvil --block-time 2

# Tests específicos
test-backend:
	cd $(BACKEND_DIR) && mix test

test-contracts:
	cd $(CONTRACTS_DIR) && forge test

