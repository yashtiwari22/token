const hre = require("hardhat");

async function main() {
  /*
    DeployContract in ethers.js is an abstraction used to deploy new smart contracts,
    so whitelistContract here is a factory for instances of our Whitelist contract.
    */
  // here we deploy the contract
  const CGate = await hre.ethers.deployContract("CGate", [
    "CGate",
    "CG",
    18,
    1000,
  ]);
  // 10 is the Maximum number of whitelisted addresses allowed

  // wait for the contract to deploy
  await CGate.waitForDeployment();

  // print the address of the deployed contract
  console.log("CGate Contract Address:", CGate.target);
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
