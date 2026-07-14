const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GovernanceDAO", function () {
  let DAO, dao;
  let owner, addr1, addr2;

  beforeEach(async function () {
    // Obtenemos las cuentas de prueba (wallets)
    [owner, addr1, addr2] = await ethers.getSigners();

    // Desplegamos el contrato con un quorum de 1000 tokens
    DAO = await ethers.getContractFactory("GovernanceDAO");
    dao = await DAO.deploy(1000);
    await dao.waitForDeployment();

    // Distribuimos tokens: addr1 tiene 800 (mucho poder), addr2 tiene 300 (menos poder)
    await dao.mintTokens(addr1.address, 800);
    await dao.mintTokens(addr2.address, 300);
  });

  it("Debería permitir crear una propuesta", async function () {
    await dao.connect(addr1).createProposal("Invertir en nuevo protocolo");
    const proposal = await dao.proposals(1);
    expect(proposal.description).to.equal("Invertir en nuevo protocolo");
  });

  it("Debería ponderar el voto según los tokens (Plutocracia)", async function () {
    await dao.connect(addr1).createProposal("Propuesta A");
    
    // addr1 vota (peso = 800)
    await dao.connect(addr1).vote(1);
    let proposal = await dao.proposals(1);
    expect(proposal.voteCount).to.equal(800);
  });

  it("Debería bloquear el doble voto (Doble Gasto)", async function () {
    await dao.connect(addr1).createProposal("Propuesta B");
    await dao.connect(addr1).vote(1);
    
    // Intentar votar de nuevo debería fallar
    await expect(dao.connect(addr1).vote(1)).to.be.revertedWith("Doble voto detectado");
  });

  it("Debería ejecutar la propuesta solo si alcanza el quorum", async function () {
    await dao.connect(addr1).createProposal("Propuesta C");
    
    // Solo addr1 vota (800 votos). El quorum es 1000. Debería fallar.
    await dao.connect(addr1).vote(1);
    await expect(dao.connect(addr1).executeProposal(1)).to.be.revertedWith("No se alcanzo el quorum");

    // addr2 vota (300 votos). Total = 1100.
    await dao.connect(addr2).vote(1);
    
    // Ahora sí debería ejecutarse
    await dao.connect(addr1).executeProposal(1);
    const proposal = await dao.proposals(1);
    expect(proposal.executed).to.equal(true);
  });
});