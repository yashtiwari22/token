const { ethers, upgrades } = require("hardhat");

async function main() {
  /*
    DeployContract in ethers.js is an abstraction used to deploy new smart contracts,
    so whitelistContract here is a factory for instances of our Whitelist contract.
    */
  // here we deploy the contract
  const CGate = await ethers.getContractFactory("CGate");
  const cGate = await upgrades.deployProxy(CGate, ["CGate", "CG", 18, 1000]);

  // wait for the contract to deploy
  await cGate.waitForDeployment();

  // print the address of the deployed contract
  console.log("CGate Contract Address:", await cGate.getAddress());
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
