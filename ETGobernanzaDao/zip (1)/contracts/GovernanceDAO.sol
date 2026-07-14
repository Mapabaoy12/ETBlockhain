// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GovernanceDAO {
    // Definimos el modelo de la propuesta
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount; 
        bool executed;
    }

    // Variables de estado
    address public owner;
    uint256 public quorum; 
    uint256 public proposalCount;

    // Mappings para gestionar los datos
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public balances; 
    mapping(uint256 => mapping(address => bool)) public hasVoted; 

    // Eventos para el registro (logs)
    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, uint256 weight);
    event ProposalExecuted(uint256 id);

    constructor(uint256 _quorum) {
        owner = msg.sender;
        quorum = _quorum;
    }

    // Función auxiliar para asignar tokens a las wallets y probar la plutocracia
    function mintTokens(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Solo el dueno puede mintear");
        balances[_to] += _amount;
    }

    // 1. Proponer iniciativas
    function createProposal(string memory _description) public {
        require(balances[msg.sender] > 0, "Debes tener tokens para proponer");
        
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _description,
            voteCount: 0,
            executed: false
        });

        emit ProposalCreated(proposalCount, _description);
    }

    // 2. Votar de manera distribuida 
    function vote(uint256 _proposalId) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Propuesta no existe");
        require(!hasVoted[_proposalId][msg.sender], "Doble voto detectado");
        
        uint256 voterWeight = balances[msg.sender];
        require(voterWeight > 0, "No tienes tokens para votar");

        // Registramos que ya votó para evitar el doble gasto
        hasVoted[_proposalId][msg.sender] = true;

        // Sumamos los votos basados en la cantidad de tokens
        proposals[_proposalId].voteCount += voterWeight;

        emit Voted(_proposalId, msg.sender, voterWeight);
    }

    // 3. Ejecutar propuesta si cumple el quorum
    function executeProposal(uint256 _proposalId) public {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Propuesta no existe");
        Proposal storage proposal = proposals[_proposalId];
        
        require(!proposal.executed, "La propuesta ya fue ejecutada");
        require(proposal.voteCount >= quorum, "No se alcanzo el quorum");

        // Ejecutamos la propuesta
        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }
}