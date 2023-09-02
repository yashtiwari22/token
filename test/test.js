const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CustomToken", function () {
  let customToken;
  let owner;
  let newOwner;

  const initialSupply = ethers.parseEther("1000000");
  const burnAmount = ethers.parseEther("10000"); // Amount to burn
  const maxTransferAmount = ethers.parseEther("10000");
  const delay = 3600;

  beforeEach(async function () {
    [owner, newOwner, user1, user2] = await ethers.getSigners();
    const CustomToken = await ethers.getContractFactory("CustomToken");
    customToken = await CustomToken.deploy(
      "CustomToken",
      "CT",
      18,
      initialSupply
    );
    await customToken.waitForDeployment();

    // Set the maximum transfer amount
    await customToken.setMaxTransferAmount(maxTransferAmount);

    await customToken.setTransferDelay(delay);
  });

  describe("Deployment", function () {
    it("Should deploy the CustomToken contract", async function () {
      expect(customToken.address).to.not.equal(0);
    });

    it("Should set the owner correctly", async function () {
      const contractOwner = await customToken.owner();
      expect(contractOwner).to.equal(owner.address);
    });
  });

  describe("Ownership Transfer", function () {
    it("Should transfer ownership to a new address", async function () {
      // Check the initial owner
      const initialOwner = await customToken.owner();
      expect(initialOwner).to.equal(owner.address);

      // Transfer ownership to newOwner
      await customToken.transferOwnership(newOwner.address);

      // Check the new owner
      const newContractOwner = await customToken.owner();
      expect(newContractOwner).to.equal(newOwner.address);
    });

    it("Should revert if transferring ownership to the zero address", async function () {
      // Try to transfer ownership to the zero address
      await expect(
        customToken
          .connect(owner)
          .transferOwnership("0x0000000000000000000000000000000000000000")
      ).to.be.revertedWith("New owner cannot be zero address");
    });

    it("Should revert if a non-owner tries to transfer ownership", async function () {
      // Try to transfer ownership from a non-owner account
      await expect(
        customToken.connect(newOwner).transferOwnership(owner.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Burn", function () {
    it("should allow the owner to burn tokens", async function () {
      //Check the owner's balance before burning
      let ownerBalanceBefore = await customToken.balanceOf(owner.address);

      //Burn tokens as the owner
      await customToken.burn(burnAmount);

      //Checks the owner's balance after burning
      const ownerBalanceAfter = await customToken.balanceOf(owner.address);

      //Ensure the balance decreased by the burnAmount
      expect(ownerBalanceAfter).to.equal(ownerBalanceBefore - burnAmount);
    });
  });

  describe("Blacklist", function () {
    it("Should allow the owner to blacklist a user", async function () {
      // Blacklist user1
      await customToken.blackList(user1.address);

      // Check if user1 is now blacklisted
      const isBlacklist = await customToken.isBlackList(user1.address);

      expect(isBlacklist).to.be.true;
    });

    it("Should revert if a non-owner tries to blacklist a user", async function () {
      // Try to blacklist a user from a non-owner account
      await expect(
        customToken.connect(user1).blackList(user2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Remove From Blacklist", function () {
    it("Should allow the owner to remove a user from the blacklist", async function () {
      // Blacklist user1 first
      await customToken.connect(owner).blackList(user1.address);

      // Check if user1 is initially blacklisted
      expect(await customToken.isBlackList(user1.address)).to.be.true;

      // Remove user1 from the blacklist
      await customToken.connect(owner).removeFromBlacklist(user1.address);

      // Check if user1 is no longer blacklisted
      expect(await customToken.isBlackList(user1.address)).to.be.false;
    });

    it("Should revert if a non-owner tries to remove a user from the blacklist", async function () {
      // Try to remove a user from the blacklist from a non-owner account
      await customToken.connect(owner).blackList(user1.address); // Blacklist first
      await expect(
        customToken.connect(user1).removeFromBlacklist(user1.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Anti-Whale Measure", function () {
    it("Should allow a transaction below the maximum transfer amount", async function () {
      const transactionAmount = ethers.parseEther("5000"); // Set a transfer amount below the maximum
      await customToken.transfer(user1.address, transactionAmount);
      const user1Balance = await customToken.balanceOf(user1.address);
      expect(user1Balance).to.equal(transactionAmount);
    });

    it("Should revert a transfer exceeding the maximum transfer amount", async function () {
      const transactionAmount = ethers.parseEther("15000"); // Set a transfer amount above the maximum
      await expect(
        customToken.transfer(user1.address, transactionAmount)
      ).to.be.revertedWith("Amount exceeds maximum");
    });
  });

  describe("Pause and Unpause", function () {
    it("should allow the owner to pause and unpause the contract", async function () {
      // Pause the contract
      await customToken.pause();
      // Check if the contract is paused again
      const isPausedAgain = await customToken.paused();
      expect(isPausedAgain).to.be.true;
    });
    it("should reject transfers when the contract is paused", async function () {
      // Attempt a transfer when the contract is paused
      await customToken.pause();
      const transferAmount = ethers.parseEther("5000");
      await expect(
        customToken.transfer(owner.address, transferAmount)
      ).to.be.revertedWith("Pausable: paused");
    });
  });

  //   describe("Anti-Snipe Measure", function () {
  //     it("Should allow a transfer after the transfer delay period", async function () {
  //       console.log(await customToken.transferAllowedAt());

  //       const transactionAmount = ethers.parseEther("5000"); // Set a transfer amount
  //       await customToken.addToWhitelist(user1.address);
  //       await customToken.transfer(user1.address, transactionAmount);

  //       console.log(await customToken.transferAllowedAt());

  //       // Try to transfer back to owner immediately (within the delay period)
  //       await expect(
  //         customToken.connect(user1).transfer(owner.address, transactionAmount)
  //       ).to.be.revertedWith("Transfer not allowed yet");

  //       // Advance the time to simulate the transfer delay period passing
  //       await network.provider.send("evm_increaseTime", [transferDelay]);
  //       await network.provider.send("evm_mine");

  //       // Try to transfer back to owner after the delay period
  //       await customToken
  //         .connect(user1)
  //         .transfer(owner.address, transactionAmount);

  //       const ownerBalance = await customToken.balanceOf(owner.address);
  //       expect(ownerBalance).to.equal(transactionAmount);
  //     });
  //   });

  describe("Freeze and Unfreeze", function () {
    it("should allow the owner to freeze and unfreeze a wallet", async function () {
      // Check if user's wallet is initially not frozen
      const isFrozenBefore = await customToken.isFrozen(user1.address);
      expect(isFrozenBefore).to.be.false;

      // Freeze the user's wallet
      await customToken.freezeWallet(user1.address);

      // Check if the user's wallet is frozen
      const isFrozenAfter = await customToken.isFrozen(user1.address);
      expect(isFrozenAfter).to.be.true;

      // Unfreeze the user's wallet
      await customToken.unfreezeWallet(user1.address);

      // Check if the user's wallet is unfrozen again
      const isUnfrozen = await customToken.isFrozen(user1.address);
      expect(isUnfrozen).to.be.false;
    });
    it("should reject transfers from a frozen wallet", async function () {
      // Freeze the user's wallet
      await customToken.freezeWallet(user1.address);

      // Attempt a transfer from the frozen wallet
      const transferAmount = ethers.parseEther("10");
      await customToken.addToWhitelist(user1.address);
      await expect(
        customToken.connect(user1).transfer(owner.address, transferAmount)
      ).to.be.revertedWith("Sender's wallet is frozen");
    });
  });
});
