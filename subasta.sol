// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubastaAvanzada
 * @author Nicolas (Corregido por Gemini)
 * @notice Este contrato gestiona una subasta robusta con manejo de depósitos individuales.
 * Los usuarios depositan fondos y luego pujan con ese saldo, permitiendo reembolsos parciales
 * del excedente en cualquier momento.
 * @dev Implementa un sistema de depósito (escrow) y retiro para un manejo de fondos seguro y flexible.
 */
contract SubastaAvanzada {

    // --- Variables de Estado ---

    address public immutable owner;
    address payable public immutable beneficiary;

    uint public immutable auctionEndTimeInitial;
    uint public auctionEndTime;
    bool public auctionEnded;

    address public highestBidder;
    uint public highestBid;

    // Mapping para gestionar el saldo de cada participante.
    // Esta es la clave para el reembolso parcial.
    mapping(address => uint) public deposits;

    struct Bid {
        address bidder;
        uint amount;
    }

    Bid[] public bids;

    // --- Eventos ---

    event Deposit(address indexed user, uint amount);
    event Withdrawal(address indexed user, uint amount);
    event NewHighestBid(address indexed bidder, uint amount);
    event AuctionEnded(address indexed winner, uint amount);

    // --- Modificadores ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el dueno puede llamar a esta funcion.");
        _;
    }

    modifier auctionIsActive() {
        require(block.timestamp < auctionEndTime, "La subasta ya ha finalizado.");
        _;
    }

    modifier auctionHasEnded() {
        require(block.timestamp >= auctionEndTime, "La subasta aun no ha finalizado.");
        _;
    }

    // --- Constructor ---

    constructor(address payable _beneficiary, uint _biddingTime) {
        owner = msg.sender;
        beneficiary = _beneficiary;
        auctionEndTimeInitial = block.timestamp + _biddingTime;
        auctionEndTime = auctionEndTimeInitial;
    }

    // --- Funciones de Manejo de Fondos ---

    /**
     * @notice Deposita fondos en el contrato para poder ofertar.
     */
    function deposit() external payable {
        require(msg.value > 0, "El deposito debe ser mayor a cero.");
        deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Permite a los participantes retirar su saldo no comprometido en una oferta.
     * Esta función implementa el "Reembolso Parcial".
     */
    function withdraw() external {
        uint amountToWithdraw = deposits[msg.sender];
        
        if (msg.sender == highestBidder) {
            // Si es el ofertante más alto, solo puede retirar el excedente.
            amountToWithdraw -= highestBid;
        }

        require(amountToWithdraw > 0, "No tienes fondos disponibles para retirar.");

        deposits[msg.sender] -= amountToWithdraw;
        emit Withdrawal(msg.sender, amountToWithdraw);

        (bool sent, ) = msg.sender.call{value: amountToWithdraw}("");
        require(sent, "Fallo al retirar los fondos.");
    }


    // --- Funciones de la Subasta ---

    /**
     * @notice Realiza una oferta utilizando los fondos previamente depositados.
     * @param _amount El monto que se desea ofertar.
     */
    function bid(uint _amount) external auctionIsActive {
        require(deposits[msg.sender] >= _amount, "Fondos insuficientes. Deposita mas para poder ofertar este monto.");
        
        uint requiredAmount = (highestBid * 105) / 100;
        if (highestBid == 0) {
             // Para la primera oferta, solo se requiere que sea mayor a 0.
            require(_amount > 0, "La primera oferta debe ser mayor que cero.");
        } else {
            require(_amount > requiredAmount, "La oferta debe ser al menos 5% mayor que la oferta actual.");
        }

        // El ofertante anterior ahora puede retirar el 100% de su depósito si lo desea.
        highestBidder = msg.sender;
        highestBid = _amount;

        bids.push(Bid(msg.sender, _amount));

        if (block.timestamp > auctionEndTime - 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        emit NewHighestBid(msg.sender, _amount);
    }

    /**
     * @notice Finaliza la subasta, transfiere los fondos y marca el estado como finalizado.
     */
    function endAuction() external auctionHasEnded {
        require(!auctionEnded, "La subasta ya ha sido finalizada.");
        require(highestBidder != address(0), "La subasta finalizo sin ofertas.");

        auctionEnded = true;

        uint commission = (highestBid * 2) / 100;
        uint amountToBeneficiary = highestBid - commission;
        
        // El depósito del ganador se reduce por el monto de su oferta.
        // El excedente puede ser retirado por él más tarde.
        deposits[highestBidder] -= highestBid;

        // Transferencias
        (bool successOwner, ) = owner.call{value: commission}("");
        require(successOwner, "Fallo al transferir la comision al dueno.");

        (bool successBeneficiary, ) = beneficiary.call{value: amountToBeneficiary}("");
        require(successBeneficiary, "Fallo al transferir los fondos al beneficiario.");

        emit AuctionEnded(highestBidder, highestBid);
    }

    // --- Funciones de Vista ---
    
    /**
     * @notice Devuelve el saldo disponible para retirar de un usuario.
     * @param _user La dirección del usuario.
     * @return El monto que el usuario puede retirar.
     */
    function getWithdrawableAmount(address _user) external view returns (uint) {
        if (_user == highestBidder) {
            return deposits[_user] - highestBid;
        }
        return deposits[_user];
    }

    function getWinner() external view returns (address winner, uint winningBid) {
        require(auctionEnded, "La subasta aun no ha sido finalizada formalmente.");
        return (highestBidder, highestBid);
    }

    function getAllBids() external view returns (Bid[] memory) {
        return bids;
    }
}