# Subasta de Smart Contract - Trabajo Final Módulo 2

Este repositorio contiene el código fuente y la documentación de un Smart Contract de Subasta avanzado, desarrollado como parte del Trabajo Final del Módulo 2. El contrato ha sido desplegado en la red de pruebas **Sepolia** y su código fuente ha sido verificado en Etherscan.

-   **URL del Contrato en Sepolia:** `
-   **URL de este Repositorio:** `

## 📜 Descripción General

El proyecto implementa una subasta inglesa on-chain con características avanzadas. A diferencia de una subasta simple, este contrato utiliza un **modelo de depósito (escrow)**, donde los participantes primero depositan fondos en el contrato y luego utilizan ese saldo para realizar sus ofertas.

Este enfoque proporciona una mayor flexibilidad y eficiencia de capital, permitiendo a los usuarios gestionar sus fondos de manera segura y retirar cualquier excedente que no esté comprometido en una oferta activa.

## ✨ Funcionalidades Implementadas

El contrato cumple con todos los requisitos solicitados, incluyendo funcionalidades básicas y avanzadas.

### 📦 **Constructor**
`constructor(address payable _beneficiary, uint _biddingTime)`
-   Inicializa la subasta estableciendo la dirección del **beneficiario** (quien recibe el dinero de la venta) y la **duración** inicial de la subasta en segundos.
-   El `owner` del contrato (quien lo despliega) es quien recibirá la comisión.

### 💸 **Manejo de Fondos (Modelo de Depósito)**
-   ✅ **`deposit()`**: Función `payable` que permite a cualquier usuario depositar ETH en el contrato, aumentando su saldo interno. Este es el primer paso para poder ofertar.
-   ✅ **`withdraw()`**: Permite a los usuarios retirar su saldo no comprometido. Esta función implementa de forma nativa dos escenarios:
    1.  **Reembolso para no ganadores**: Si un usuario ha sido superado, puede retirar el 100% de su saldo.
    2.  **Reembolso Parcial (Avanzado)**: Si un usuario es el ofertante más alto, puede retirar el saldo que **excede** el monto de su oferta actual. Por ejemplo, si depositó 5 ETH y su oferta es de 3 ETH, puede retirar 2 ETH en cualquier momento.

### 🏷️ **Función para Ofertar**
`bid(uint _amount)`
-   Permite a un participante realizar una oferta utilizando su saldo previamente depositado.
-   La oferta es válida si:
    -   El monto de la oferta es **mayor en al menos un 5%** que la oferta más alta actual.
    -   El usuario tiene **saldo depositado suficiente** para cubrir la oferta.
    -   La subasta está activa (`auctionIsActive`).

### 🚀 **Funcionalidades Avanzadas**
-   ✅ **Extensión de Tiempo**: Si se realiza una oferta válida dentro de los **últimos 10 minutos**, el tiempo de finalización de la subasta se extiende por 10 minutos adicionales para evitar el "sniping".
-   ✅ **Comisión del 2%**: Al finalizar la subasta, una comisión del 2% sobre la oferta ganadora se descuenta automáticamente y se envía al `owner` del contrato.
-   ✅ **Seguridad**: El contrato utiliza el patrón **Checks-Effects-Interactions** para mitigar ataques de reentrada, especialmente en la función `endAuction()`. El retiro de fondos sigue el patrón **Pull-over-Push** a través de la función `withdraw()`.

### 🔍 **Funciones de Vista**
-   🥇 **`getWinner()`**: Devuelve la dirección del ganador y el monto final una vez que la subasta ha sido formalmente cerrada con `endAuction()`.
-   📜 **`getAllBids()`**: Devuelve un array con el historial completo de todas las ofertas realizadas.
-   💰 **`getWithdrawableAmount(address _user)`**: Devuelve el monto exacto que un usuario específico puede retirar en ese momento.

### 📢 **Eventos**
El contrato emite eventos para notificar a las aplicaciones externas sobre acciones importantes:
-   `Deposit(address user, uint amount)`: Al depositar fondos.
-   `Withdrawal(address user, uint amount)`: Al retirar fondos.
-   `NewHighestBid(address bidder, uint amount)`: Al registrar una nueva oferta máxima.
-   `AuctionEnded(address winner, uint amount)`: Cuando la subasta finaliza.

## ⚙️ Cómo Interactuar con el Contrato

Para participar en la subasta (por ejemplo, a través de [Remix](https://remix.ethereum.org/) o Etherscan), sigue estos pasos:

1.  **Depositar Fondos**:
    -   Llama a la función `deposit()`.
    -   Envía la cantidad de ETH que deseas usar como saldo en el campo `VALUE` o `amount` de la transacción.

2.  **Realizar una Oferta**:
    -   Consulta `highestBid` para ver la oferta actual.
    -   Calcula el monto de tu nueva oferta (al menos un 5% más alta).
    -   Llama a la función `bid(uint _amount)` pasando tu monto de oferta como parámetro. Asegúrate de tener suficiente saldo depositado.

3.  **Retirar Saldo Excedente (Reembolso Parcial)**:
    -   Si eres el ofertante más alto pero depositaste más de lo que ofertaste, puedes llamar a `withdraw()` para retirar la diferencia.
    -   Si tu oferta fue superada, puedes llamar a `withdraw()` para retirar todo tu saldo.

4.  **Finalizar la Subasta**:
    -   Una vez que el tiempo de la subasta (`auctionEndTime`) haya pasado, cualquiera puede llamar a la función `endAuction()` para cerrar la subasta y transferir los fondos.

## 🛠️ Detalles Técnicos

-   **Lenguaje**: Solidity `^0.8.20`
-   **Red**: Sepolia Testnet
-   **Patrones de Diseño**:
    -   **Pull-over-Push**: Para el retiro de fondos, promoviendo la seguridad.
    -   **Checks-Effects-Interactions**: Para prevenir vulnerabilidades de reentrada.
    -   **Escrow (Depósito)**: Para un manejo de fondos flexible y para implementar la funcionalidad de reembolso parcial.
