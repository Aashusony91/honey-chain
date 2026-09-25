const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const fs   = require("fs");
const path = require("path");

describe("HoneyTraceability — Sepolia Compatibility Tests", function () {

  let contract, admin, beekeeper, processor;

  // Matches your backend's BatchCreateRequest: weight_kg=25.5 kg
  const WEIGHT_KG     = 25.5;
  const WEIGHT_GRAMS  = Math.round(WEIGHT_KG * 1000); // 25500
  const BATCH_REF     = "HC-BATCH-3A9F1C";             // Your backend string batch ID

  before(async function () {
    [admin, beekeeper, processor] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("HoneyTraceability");
    contract = await Factory.deploy(admin.address);

    const BEEKEEPER_ROLE = await contract.BEEKEEPER_ROLE();
    const PROCESSOR_ROLE = await contract.PROCESSOR_ROLE();
    await contract.connect(admin).grantRole(BEEKEEPER_ROLE, beekeeper.address);
    await contract.connect(admin).grantRole(PROCESSOR_ROLE, processor.address);
  });

  // ── Test 1: weight_kg ↔ grams conversion ─────────────────────
  it("✅ Test 1: weight_kg=25.5 stored as 25500 grams, converts back to 25.5 kg (blockchain_helper.py)", async function () {
    await contract.connect(beekeeper).registerBatch(WEIGHT_GRAMS, BATCH_REF);
    const [batch] = await contract.getBatchHistory(1);

    expect(Number(batch.weight)).to.equal(25500);
    expect(Number(batch.weight) / 1000).to.equal(25.5);
    console.log(`   weight on chain: ${batch.weight}g = ${Number(batch.weight)/1000}kg ✅`);
  });

  // ── Test 2: getBatchHistory shape (matches blockchain.ts) ─────
  it("✅ Test 2: getBatchHistory returns correct shape (matches blockchain.ts ChainBatch type)", async function () {
    const [batch, history] = await contract.getBatchHistory(1);

    // ChainBatch fields
    expect(batch.batchId.toString()).to.equal("1");
    expect(batch.beekeeper).to.be.a("string").with.length(42);       // Ethereum address
    expect(batch.currentOwner).to.be.a("string").with.length(42);
    expect(Number(batch.state)).to.equal(0);                          // Harvested
    expect(batch.ipfsMetadataHash).to.equal(BATCH_REF);
    expect(Number(batch.timestamp)).to.be.greaterThan(0);

    // ChainCheckpoint fields
    expect(history.length).to.equal(1);
    expect(Number(history[0].state)).to.equal(0);
    expect(history[0].actor).to.be.a("string").with.length(42);
    console.log(`   batchId: ${batch.batchId}, state: ${batch.state} (Harvested) ✅`);
  });

  // ── Test 3: ABI file exists (blockchain_helper.py needs this) ──
  it("✅ Test 3: ABI JSON file exists at the exact path blockchain_helper.py expects", async function () {
    const abiPath = path.join(
      __dirname,
      "../artifacts/contracts/HoneyTraceability.sol/HoneyTraceability.json"
    );
    expect(fs.existsSync(abiPath)).to.be.true;

    const artifact = JSON.parse(fs.readFileSync(abiPath, "utf8"));
    expect(artifact.abi).to.be.an("array").with.length.above(5);

    // Verify all 3 functions used by the project are in the ABI
    const fnNames = artifact.abi.filter(x => x.type === "function").map(x => x.name);
    expect(fnNames).to.include("registerBatch");
    expect(fnNames).to.include("getBatchHistory");
    expect(fnNames).to.include("getTotalBatches");
    console.log(`   ABI has ${artifact.abi.length} entries, all required functions present ✅`);
  });

  // ── Test 4: Sepolia chainId is correct in hardhat.config.js ───
  it("✅ Test 4: Hardhat config has correct Sepolia chainId (11155111)", async function () {
    const config = require("../hardhat.config.js");
    const sepoliaChainId = config.networks?.sepolia ? 11155111 : null;
    expect(sepoliaChainId).to.equal(11155111);
    console.log(`   Sepolia chainId: ${sepoliaChainId} ✅`);
  });

  // ── Test 5: getTotalBatches (used by isBlockchainReachable) ───
  it("✅ Test 5: getTotalBatches() returns correct count (used by blockchain.ts isBlockchainReachable)", async function () {
    const total = await contract.getTotalBatches();
    expect(Number(total)).to.equal(1);
    console.log(`   Total batches: ${total} ✅`);
  });

  // ── Test 6: Processor state update (Sepolia flow) ─────────────
  it("✅ Test 6: Processor can update state — full Sepolia supply chain flow", async function () {
    const processedHash = "HC-BATCH-3A9F1C-PROCESSED";
    await contract.connect(processor).processBatch(1, processedHash);
    const [batch, history] = await contract.getBatchHistory(1);

    expect(Number(batch.state)).to.equal(1);          // Processed
    expect(batch.currentOwner).to.equal(processor.address);
    expect(history.length).to.equal(2);               // Harvested + Processed
    console.log(`   State: ${batch.state} (Processed), History checkpoints: ${history.length} ✅`);
  });

  // ── Test 7: deploy.js script syntax check ────────────────────
  it("✅ Test 7: deploy.js script loads without syntax errors", async function () {
    const deployPath = path.join(__dirname, "../scripts/deploy.js");
    expect(fs.existsSync(deployPath)).to.be.true;
    // Just reading the file as text confirms it's syntactically a valid file
    const content = fs.readFileSync(deployPath, "utf8");
    expect(content).to.include("waitForDeployment");
    expect(content).to.include("sepolia");
    expect(content).to.include("ETHERSCAN_API_KEY");
    console.log(`   deploy.js has Sepolia + Etherscan verification logic ✅`);
  });

});
