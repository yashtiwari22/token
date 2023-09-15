const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const CGateV2 = await ethers.getContractFactory("CGateV2");
  const cGate = await upgrades.upgradeProxy(process.env.CGate_Address, CGateV2);
  console.log("Box upgraded");
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
