# 🏗️ Arquitectura de Guayabita Roll

Este documento detalla el flujo de datos, la seguridad y la integración de componentes de Guayabita Roll.

## 1. Diagrama de Flujo de Datos

El sistema opera en tres capas: **Off-chain** (Frontend), **Soft-chain** (Backend Elixir + EigenDA) y **On-chain** (Celo L2).

## 2. Componentes del Sistema

### A. Backend (Elixir / Phoenix)

Es el orquestador del juego. Sus responsabilidades son:

* **Gestión de Entropía:** Genera y almacena las `Server_Seeds`.
* **Batching Service:** Agrupa hashes en Merkle Trees y los envía al Disperser de EigenDA mediante gRPC.
* **Game Engine:** Maneja las salas de juego y estados mediante WebSockets (Phoenix Channels) para una experiencia de baja latencia.

### B. EigenDA (Capa de Disponibilidad)

Actúa como nuestra "Notaría Digital".

* **Propósito:** Probar que el compromiso (hash) existía antes de que el jugador hiciera su apuesta.
* **Inmutabilidad:** Una vez que el `Blob ID` es generado por el Disperser, el servidor no puede alterar la semilla sin que sea detectado.

### C. Smart Contracts (Celo L2)

El árbitro final del dinero.

* **GuayabitaRollManager.sol:** Recibe la apuesta en **MCOP**, guarda el `Client_Seed` y, tras la revelación, verifica el hash y paga los premios.

## 3. El Ciclo de Vida de una Apuesta

| Fase | Acción | Actor | Tecnología |
| --- | --- | --- | --- |
| **1. Prep** | Generación de lote de 1000 seeds | Backend | Elixir + EigenDA |
| **2. Bet** | El usuario envía apuesta y `Client_Seed` | Usuario | Celo L2 |
| **3. Result** | Revelación de `Server_Seed` y cálculo | Backend | Elixir (Websocket) |
| **4. Settlement** | Liquidación de fondos | Contract | Celo (MCOP) |

## 4. Estrategia de Batching de Semillas

Para optimizar costos y velocidad, no subimos cada tiro a EigenDA.

1. El backend genera un lote de  semillas.
2. Crea un **Merkle Tree**.
3. Sube la **Merkle Root** a EigenDA.
4. Para cada jugada, se entrega al contrato: `Server_Seed` + `Merkle_Proof`. El contrato solo necesita verificar la prueba contra la raíz ya sellada.

## 5. Consideraciones de Seguridad

* **Ataque de Retención (Liveness):** Si el servidor no revela la semilla, el Smart Contract permite al jugador reclamar un "Refund" tras un tiempo de espera.
* **Predicción de Azar:** La combinación de `Server_Seed` (secreta hasta el final) y `Client_Seed` (desconocida por el servidor al crear el commit) hace que el resultado sea impredecible para ambas partes.
