# Guayabita Roll - AI Coding Instructions

## 🎯 Project Overview

**Guayabita Roll** is a provably fair on-chain dice game using **Celo L2** and **EigenDA** for data availability. The architecture spans three components:

1. **Backend (Elixir/Phoenix)**: Game orchestration, entropy management, WebSocket servers for real-time gaming
2. **Smart Contracts (Solidity/Foundry)**: Bet settlement and commitment verification on Celo L2
3. **Frontend (Next.js 16 + React 19)**: Web UI with Tailwind CSS and React Compiler for optimized rendering

## 🏗️ Architecture & Data Flow

### Core Game Loop

```
Client Seed (User) + Server Seed (Backend) → Hash Commitment → EigenDA
                                           ↓
                                    Merkle Root Published
                                           ↓
                                    User Places Bet (MCOP)
                                           ↓
                                    Server Reveals Seed + Merkle Proof
                                           ↓
                                    Contract Verifies & Settles
```

**Key Insight**: Backend batches 1000 seeds into a Merkle Tree, publishes the root to EigenDA (not each seed). This reduces costs while maintaining security. For each bet, the contract receives `Server_Seed + Merkle_Proof` to verify against the sealed root.

### Module Organization

- **`lib/guayabita_roll/`**: Business logic (contexts, data operations)
  - `entropy.ex`: Seed generation and batching
  - `repo.ex`: Ecto repository
  - `application.ex`: OTP supervision tree
- **`lib/guayabita_roll_web/`**: Web layer
  - `router.ex`: Route definitions
  - `endpoint.ex`: Phoenix endpoint configuration
  - `controllers/`: Request handlers (JSON responses)

## 🔧 Developer Workflows

### Setup & Development

```bash
# Full setup (dependencies, database, contracts, frontend)
make setup

# Launch all services in parallel (Backend on port 4000, Frontend on 3000, Anvil on port 8545)
make dev

# Individual service commands
cd apps/backend && iex -S mix phx.server
cd apps/frontend && npm run dev
cd apps/contracts && anvil --block-time 2
```

### Testing & Quality

```bash
# Backend tests (runs `ecto.create --quiet`, `ecto.migrate --quiet`, then tests)
make test-backend
# Or targeted: cd apps/backend && mix test test/path/to/test.exs

# Contract tests
make test-contracts

# Pre-commit validation (compiles with warnings-as-errors, checks unused deps, formats, tests)
cd apps/backend && mix precommit
```

**Key Pattern**: Always use `mix precommit` before pushing. It catches formatting and unused dependency issues early.

## 📝 Elixir/Phoenix Conventions

### Language-Specific Rules

- **No index-based list access via `[]`**: Use `Enum.at(list, index)` or pattern matching
  ```elixir
  # ❌ Invalid
  items = ["a", "b"]
  items[0]  # error
  
  # ✅ Valid
  Enum.at(items, 0)
  ```

- **Variables are immutable**: Capture block expression results
  ```elixir
  # ❌ Invalid (rebinding inside block doesn't propagate)
  if condition do
    socket = assign(socket, :val, value)
  end
  
  # ✅ Valid
  socket = if condition do
    assign(socket, :val, value)
  else
    socket
  end
  ```

- **Map access on structs fails**: Use dot notation or Ecto helpers
  ```elixir
  # ❌ Invalid
  changeset[:field]
  
  # ✅ Valid
  changeset.field  # for structs
  Ecto.Changeset.get_field(changeset, :field)  # for changesets
  ```

### Phoenix 1.8.3 Requirements

- **LiveView templates**: Always begin with `<Layouts.app flash={@flash} ...>` wrapping content
- **Layouts alias**: Available in `guayabita_roll_web.ex`, no need to alias again
- **No `<.flash_group>` outside layouts**: It's now in `Layouts` module only
- **Form inputs**: Use `<.input>` component from `core_components.ex` for consistency
- **Icons**: Use `<.icon name="hero-{name}">` component, never Heroicons modules directly

### Ecto Patterns

- **Always preload associations** used in templates: `Repo.preload(query, :association)`
- **Use `Ecto.Schema` type `:string`** for all text fields (`:text` is same)
- **`validate_number/2` has no `:allow_nil`**: Validations skip nil by design
- **Programmatic fields (e.g., `user_id`)**: Don't include in `cast()`, set explicitly for security
- **Timestamps**: Use UTC datetime by default (configured in `config.exs`)

### Dependencies

- **HTTP Client**: Always use `Req` (included in deps), never `:httpoison`, `:tesla`, or `:httpc`
- **OTP Primitives** (`DynamicSupervisor`, `Registry`): Require `name:` in child spec
  ```elixir
  {DynamicSupervisor, name: GuayabitaRoll.MySupervisor}
  ```
- **Concurrent iteration**: Use `Task.async_stream(collection, fn x -> ... end, timeout: :infinity)`

### Testing Best Practices

- **Start supervised processes**: `start_supervised!(child_spec)` guarantees cleanup
- **Avoid `Process.sleep/1`**: Use `Process.monitor(pid)` and assert on `:DOWN` message
  ```elixir
  ref = Process.monitor(pid)
  assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
  ```
- **Sync before next call**: Use `:sys.get_state(pid)` instead of sleeping

## 🔐 Security & EigenDA Integration

### Commit-Reveal Mechanics

1. Backend generates batch of server seeds → hashes them → builds Merkle Tree → publishes root to EigenDA
2. User sends `Client_Seed` + places bet with MCOP token
3. Backend reveals corresponding `Server_Seed` via WebSocket
4. Contract receives `(Server_Seed, Merkle_Proof)` from backend or user
5. Contract verifies proof against sealed EigenDA root → calculates result → settles MCOP

**Result Formula**: Combine `Server_Seed` and `Client_Seed` deterministically (both parties needed, neither can predict the other's contribution).

### Liveness Protection

If server fails to reveal seed within timeout, contract allows user to claim a refund. This prevents "server withholds seed" attacks.

## 📦 Project Dependencies Snapshot

| Component | Key Dependencies |
|-----------|------------------|
| **Backend** | Phoenix 1.8.3, Ecto 3.13, PostreSQL adapter, Bandit (HTTP server), Swoosh (mailer), Req (HTTP client) |
| **Frontend** | Next.js 16.1.3, React 19 with React Compiler, Tailwind CSS 4, TypeScript 5 |
| **Contracts** | Foundry, OpenZeppelin contracts, forge-std |

## 🚀 Common Tasks

### Adding Backend Feature

1. **Create Ecto migration**: `cd apps/backend && mix ecto.gen.migration migration_name_using_underscores`
2. **Define schema** in `lib/guayabita_roll/` context
3. **Create context module** with CRUD operations
4. **Add controller** in `lib/guayabita_roll_web/controllers/`
5. **Route it** in `lib/guayabita_roll_web/router.ex`
6. **Test thoroughly**: `mix test` (runs migrations automatically)
7. **Validate**: `mix precommit`

### Modifying Smart Contracts

1. Edit contract in `apps/contracts/src/`
2. Update tests in `apps/contracts/test/`
3. Run `make test-contracts` (or `cd apps/contracts && forge test`)
4. Verify Merkle proof verification logic works with backend's seed batching

### Frontend Changes

- Use React Compiler (already configured in `babel-plugin-react-compiler`)
- Leverage Tailwind CSS 4 for styling
- ESLint config in `eslint.config.mjs`

## ⚠️ Critical Pitfalls

1. **Naming after refactor**: Module renamed from `backend` to `guayabita_roll`—use correct module names (`GuayabitaRoll.*`)
2. **EigenDA timing**: Merkle root must be published before any bets reference it
3. **Precommit discipline**: Always run `mix precommit` before pushing—catches errors early
4. **WebSocket state**: Phoenix Channels handle game state; ensure proper cleanup on disconnect
5. **Ecto migrations**: Never modify migrations after migration; create new ones for changes

## 📚 Where to Look

- **Architecture details**: [ARCHITECTURE.md](../ARCHITECTURE.md), [REAME.md](../REAME.md)
- **Backend guidelines**: [apps/backend/AGENTS.md](../apps/backend/AGENTS.md)
- **Game logic**: `apps/backend/lib/guayabita_roll/` (contexts)
- **Web routes**: `apps/backend/lib/guayabita_roll_web/router.ex`
- **Database schema**: `apps/backend/lib/guayabita_roll/` (schema files)
- **Contracts**: `apps/contracts/src/`
