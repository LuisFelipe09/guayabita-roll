# 🎲 Guayabita Roll

**Guayabita Roll** es un juego de dados on-chain de "Justicia Demostrable" (Provably Fair) construido sobre **Celo L2** y asegurado por **EigenDA**. El proyecto implementa un protocolo de entropía híbrida que garantiza que ni el servidor ni el jugador puedan predecir o manipular el resultado de los dados.

## 🚀 Arquitectura del Proyecto

El proyecto está organizado como un monorepo para facilitar la orquestación entre el backend de alta performance, los smart contracts y la interfaz de usuario.

* **`apps/backend`**: Desarrollado en **Elixir/Phoenix**. Gestiona la generación de entropía, la comunicación gRPC con el Disperser de **EigenDA** y el motor de juegos en tiempo real mediante WebSockets.
* **`apps/contracts`**: Smart Contracts en **Solidity** (usando **Foundry**). Maneja las apuestas en **MCOP** y la verificación on-chain de los compromisos de azar.
* **`apps/frontend`**: Aplicación **Next.js** con React Compiler para una UI de baja latencia y conexión con Web3 (Wagmi/Viem).

## 🛡️ Justicia Demostrable (Provably Fair)

Utilizamos un sistema de **Commit-Reveal** optimizado con **Data Availability (DA)**:

1. **Commitment**: El servidor genera un lote de semillas secretas (`Server_Seeds`), calcula sus hashes y publica la raíz de un Árbol de Merkle en **EigenDA**.
2. **Aportación del Jugador**: Al lanzar, el jugador provee su propia semilla (`Client_Seed`).
3. **Revelación**: El servidor revela la `Server_Seed` correspondiente.
4. **Cálculo**: El resultado se deriva de:

5. **Verificación**: Cualquier usuario puede verificar contra EigenDA que el servidor no cambió su semilla después de ver la apuesta.

## 🛠️ Requisitos previos

* [Elixir](https://elixir-lang.org/) & Erlang/OTP
* [Foundry](https://book.getfoundry.sh/getting-started/installation) (para contratos)
* [Node.js](https://nodejs.org/) (v18+ para el frontend)
* [Docker](https://www.docker.com/) (opcional, para dependencias como PostgreSQL)

## 🏁 Inicio Rápido

El proyecto utiliza un `Makefile` central para simplificar el flujo de trabajo:

```bash
# 1. Clonar e instalar dependencias
make setup

# 2. Iniciar el entorno de desarrollo (Backend, Frontend y Anvil)
make dev

# 3. Ejecutar pruebas
make test-backend
make test-contracts

```

## 🌐 Tecnologías Clave

| Componente | Tecnología |
| --- | --- |
| **Blockchain** | Celo L2 |
| **Data Availability** | EigenDA |
| **Backend** | Elixir + Phoenix + gRPC |
| **Frontend** | Next.js + React Compiler + Tailwind |
| **Asset** | MCOP Stablecoin |
