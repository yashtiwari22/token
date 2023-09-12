const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CustomToken", function () {
  let customToken;
  let owner;
  let newOwner;
  let vestingStartTime;

  const initialSupply = ethers.parseEther("10000");
  const burnAmount = ethers.parseEther("10"); // Amount to burn
  const maxTransferAmount = ethers.parseEther("100");
  const delay = 3600;
  const vestingAmount = 10; // Amount to vest (10,000 tokens)
  const vestingPercentage = 20; // 20% to be released at each interval
  const timeInterval = 60; // 60 seconds interval
  const vestingDuration = 300; // 300 seconds (5 minutes) vesting duration

  beforeEach(async function () {
    [owner, newOwner] = await ethers.getSigners();
    [owner, user1, user2] = await ethers.getSigners();
    console.log("hello");

    const CustomToken = await ethers.getContractFactory("CustomToken");
    customToken = await CustomToken.deploy(
      "CustomToken",
      "CT",
      18,
      initialSupply
    );

    await customToken.waitForDeployment();

    const balance = await customToken.balanceOf(owner.address);
    console.log(balance);

    // Set the maximum transfer amount
    await customToken.setMaxTransferAmount(maxTransferAmount);

    await customToken.setTransferDelay(delay);
  });

  // describe("Deployment", function () {
  //   it("Should deploy the CustomToken contract", async function () {
  //     expect(customToken.address).to.not.equal(0);
  //   });

  //   it("Should set the owner correctly", async function () {
  //     const contractOwner = await customToken.owner();
  //     expect(contractOwner).to.equal(owner.address);
  //   });
  // });

  // describe("Ownership Transfer", function () {
  //   it("Should transfer ownership to a new address", async function () {
  //     // Check the initial owner
  //     const initialOwner = await customToken.owner();
  //     expect(initialOwner).to.equal(owner.address);

  //     // Transfer ownership to newOwner
  //     await customToken.transferOwnership(newOwner.address);

  //     // Check the new owner
  //     const newContractOwner = await customToken.owner();
  //     expect(newContractOwner).to.equal(newOwner.address);
  //   });

  //   it("Should revert if transferring ownership to the zero address", async function () {
  //     // Try to transfer ownership to the zero address
  //     await expect(
  //       customToken
  //         .connect(owner)
  //         .transferOwnership("0x0000000000000000000000000000000000000000")
  //     ).to.be.revertedWith("Ownable: new owner is the zero address");
  //   });

  //   it("Should revert if a non-owner tries to transfer ownership", async function () {
  //     // Try to transfer ownership from a non-owner account
  //     await expect(
  //       customToken.connect(newOwner).transferOwnership(owner.address)
  //     ).to.be.revertedWith("Ownable: caller is not the owner");
  //   });
  // });

  // describe("Burn", function () {
  //   it("should allow the owner to burn tokens", async function () {
  //     //Check the owner's balance before burning
  //     let ownerBalanceBefore = await customToken.balanceOf(owner.address);

  //     //Burn tokens as the owner
  //     await customToken.burn(burnAmount);

  //     //Checks the owner's balance after burning
  //     const ownerBalanceAfter = await customToken.balanceOf(owner.address);

  //     //Ensure the balance decreased by the burnAmount
  //     expect(ownerBalanceAfter).to.equal(ownerBalanceBefore - burnAmount);
  //   });
  // });

  // describe("Blacklist", function () {
  //   it("Should allow the owner to blacklist a user", async function () {
  //     // Blacklist user1
  //     await customToken.blackList(user1.address);

  //     // Check if user1 is now blacklisted
  //     const isBlacklist = await customToken.isBlackList(user1.address);

  //     expect(isBlacklist).to.be.true;
  //   });

  //   it("Should revert if a non-owner tries to blacklist a user", async function () {
  //     // Try to blacklist a user from a non-owner account
  //     await expect(
  //       customToken.connect(user1).blackList(user2.address)
  //     ).to.be.revertedWith("Ownable: caller is not the owner");
  //   });
  // });

  // describe("Remove From Blacklist", function () {
  //   it("Should allow the owner to remove a user from the blacklist", async function () {
  //     // Blacklist user1 first
  //     await customToken.connect(owner).blackList(user1.address);

  //     // Check if user1 is initially blacklisted
  //     expect(await customToken.isBlackList(user1.address)).to.be.true;

  //     // Remove user1 from the blacklist
  //     await customToken.connect(owner).removeFromBlacklist(user1.address);

  //     // Check if user1 is no longer blacklisted
  //     expect(await customToken.isBlackList(user1.address)).to.be.false;
  //   });

  //   it("Should revert if a non-owner tries to remove a user from the blacklist", async function () {
  //     // Try to remove a user from the blacklist from a non-owner account
  //     await customToken.connect(owner).blackList(user1.address); // Blacklist first
  //     await expect(
  //       customToken.connect(user1).removeFromBlacklist(user1.address)
  //     ).to.be.revertedWith("Ownable: caller is not the owner");
  //   });
  // });

  // describe("Anti-Whale Measure", function () {
  //   it("Should allow a transaction below the maximum transfer amount", async function () {
  //     const transactionAmount = ethers.parseEther("50"); // Set a transfer amount below the maximum
  //     await customToken.transfer(user1.address, transactionAmount);
  //     const user1Balance = await customToken.balanceOf(user1.address);
  //     expect(user1Balance).to.equal(transactionAmount);
  //   });

  //   it("Should revert a transfer exceeding the maximum transfer amount", async function () {
  //     const transactionAmount = ethers.parseEther("1500"); // Set a transfer amount above the maximum
  //     await expect(
  //       customToken.transfer(user1.address, transactionAmount)
  //     ).to.be.revertedWith("Amount exceeds maximum");
  //   });
  // });

  // describe("Pause and Unpause", function () {
  //   it("should allow the owner to pause and unpause the contract", async function () {
  //     // Pause the contract
  //     await customToken.pause();
  //     // Check if the contract is paused again
  //     const isPausedAgain = await customToken.paused();
  //     expect(isPausedAgain).to.be.true;
  //   });
  //   it("should reject transfers when the contract is paused", async function () {
  //     // Attempt a transfer when the contract is paused
  //     await customToken.pause();
  //     const transferAmount = ethers.parseEther("5000");
  //     await expect(
  //       customToken.transfer(owner.address, transferAmount)
  //     ).to.be.revertedWith("Pausable: paused");
  //   });
  // });

  // describe("Freeze and Unfreeze", function () {
  //   it("should allow the owner to freeze and unfreeze a wallet", async function () {
  //     // Check if user's wallet is initially not frozen
  //     const isFrozenBefore = await customToken.isFrozen(user1.address);
  //     expect(isFrozenBefore).to.be.false;

  //     // Freeze the user's wallet
  //     await customToken.freezeWallet(user1.address);

  //     // Check if the user's wallet is frozen
  //     const isFrozenAfter = await customToken.isFrozen(user1.address);
  //     expect(isFrozenAfter).to.be.true;

  //     // Unfreeze the user's wallet
  //     await customToken.unfreezeWallet(user1.address);

  //     // Check if the user's wallet is unfrozen again
  //     const isUnfrozen = await customToken.isFrozen(user1.address);
  //     expect(isUnfrozen).to.be.false;
  //   });
  //   it("should reject transfers from a frozen wallet", async function () {
  //     // Freeze the user's wallet
  //     await customToken.freezeWallet(user1.address);

  //     // Attempt a transfer from the frozen wallet
  //     const transferAmount = ethers.parseEther("10");
  //     await customToken.addToWhitelist(user1.address);
  //     await expect(
  //       customToken.connect(user1).transfer(owner.address, transferAmount)
  //     ).to.be.revertedWith("Sender's wallet is frozen");
  //   });
  // });
  // describe("LiquidityLocking", function () {
  //   it("Should lock and unlock liquidity", async function () {
  //     const liquidityAmount = ethers.parseEther("10"); // Adjust the amount
  //     const amount = ethers.parseEther("10");
  //     await customToken.mint(customToken.target, amount);

  //     //   // Lock liquidity
  //     const bal = await customToken.balanceOf(customToken.target);
  //     await customToken.connect(owner).lockLiquidity(liquidityAmount);

  //     // Check if liquidity is locked
  //     expect(await customToken.liquidityLocked()).to.be.true;
  //     expect(await customToken.lockedLiquidityAmount()).to.equal(
  //       liquidityAmount
  //     );

  //     // Unlock liquidity
  //     //Advance the time to simulate the transfer delay period passing
  //     await network.provider.send("evm_increaseTime", [delay]);
  //     await network.provider.send("evm_mine");
  //     await customToken.connect(owner).unlockLiquidity(liquidityAmount);

  //     // Check if liquidity is unlocked
  //     expect(await customToken.liquidityLocked()).to.be.false;
  //     expect(await customToken.lockedLiquidityAmount()).to.equal(0);
  //   });
  // });
  describe("vesting", function () {
    it("should add a vesting schedule", async function () {
      const amount = ethers.parseEther("100"); // 100 tokens
      const percentageToRelease = 50; // 50%
      const timeInterval = 86400; // 1 day in seconds

      await customToken.addVestingSchedule(
        newOwner.address,
        amount,
        percentageToRelease,
        timeInterval
      );

      // Check if the vesting schedule has been added correctly
      const vestingInfo = await customToken.getVestingInfo(newOwner.address);
      expect(vestingInfo.amount).to.equal(amount);
      expect(vestingInfo.percentageOfTokensToBeReleased).to.equal(
        percentageToRelease
      );
      expect(vestingInfo.timeInterval).to.equal(timeInterval);
    });
    it("should allow beneficiary to claim tokens", async function () {
      const amount = ethers.parseEther("100"); // 100 tokens
      const percentageToRelease = 50; // 50%
      const timeInterval = 86400; // 1 day in seconds

      await customToken.addVestingSchedule(
        newOwner.address,
        amount,
        percentageToRelease,
        timeInterval
      );
      // Increase the timestamp to simulate the passage of time
      await ethers.provider.send("evm_increaseTime", [86401]); // 1 day + 1 second
      await ethers.provider.send("evm_mine"); // Mine a new block

      await customToken.connect(newOwner).claim();

      // Check if tokens have been claimed correctly
      const balance = await customToken.balanceOf(owner.address);
      console.log(balance);

      const beneficiaryBalance = await customToken.balanceOf(newOwner.address);
      expect(BigInt(beneficiaryBalance)).to.equal(
        (BigInt(amount) * BigInt(percentageToRelease)) / BigInt(100)
      );
    });
  });
  // describe("deflationary mechanims", function () {
  //   it("Should allow the owner to enable/disable deflationary mechanism", async function () {
  //     // Initially, deflationary mechanism should be disabled
  //     expect(await customToken.isDeflationary()).to.equal(false);

  //     // Enable deflationary mechanism
  //     await customToken.setDeflationary(true);
  //     expect(await customToken.isDeflationary()).to.equal(true);

  //     // Disable deflationary mechanism
  //     await customToken.setDeflationary(false);
  //     expect(await customToken.isDeflationary()).to.equal(false);
  //   });

  //   it("Should transfer tokens with deflation", async function () {
  //     // Enable deflationary mechanism
  //     await customToken.setDeflationary(true);

  //     // Transfer tokens from owner to user1
  //     const initialBalanceOwner = (
  //       await customToken.balanceOf(owner.address)
  //     ).toString();
  //     console.log(initialBalanceOwner);

  //     const initialBalanceUser1 = (
  //       await customToken.balanceOf(user1.address)
  //     ).toString();
  //     console.log(initialBalanceUser1);
  //     const transferAmount = 1000; // Transfer 100 tokens
  //     await customToken.transfer(user1.address, transferAmount);

  //     const finalBalanceOwner = (
  //       await customToken.balanceOf(owner.address)
  //     ).toString();
  //     console.log(finalBalanceOwner);
  //     const finalBalanceUser1 = (
  //       await customToken.balanceOf(user1.address)
  //     ).toString();
  //     console.log(finalBalanceUser1);

  //     //   // Check that the correct amount was burned
  //     //   const burnedAmount = (
  //     //     BigInt(initialBalanceOwner) - BigInt(finalBalanceOwner)
  //     //   ).toString();
  //     //   console.log(burnedAmount);
  //     //   expect(burnedAmount).to.equal(
  //     //     ((transferAmount / BigInt(100)) * BigInt(20)).toString()
  //     //   ); // 10% burned

  //     //   // Calculate the correct amount that was transferred to user1
  //     //   const transferredAmount = (
  //     //     BigInt(finalBalanceUser1) - BigInt(initialBalanceUser1)
  //     //   ).toString();
  //     //   console.log(transfer);
  //     //   expect(transferredAmount).to.equal(
  //     //     (
  //     //       BigInt(transferAmount) -
  //     //       (BigInt(transferAmount) / 100) * 20
  //     //     ).toString()
  //     //   );
  //   });
  //   it("Should transfer tokens without deflation", async function () {
  //     // Transfer tokens from owner to user1 without enabling deflationary mechanism
  //     const initialBalanceOwner = (
  //       await customToken.balanceOf(owner.address)
  //     ).toString();
  //     const initialBalanceUser1 = (
  //       await customToken.balanceOf(user1.address)
  //     ).toString();
  //     const transferAmount = ethers.parseEther("100"); // Transfer 100 tokens

  //     await customToken.connect(owner).transfer(user1.address, transferAmount);

  //     const finalBalanceOwner = (
  //       await customToken.balanceOf(owner.address)
  //     ).toString();
  //     const finalBalanceUser1 = (
  //       await customToken.balanceOf(user1.address)
  //     ).toString();

  //     // Check that no tokens were burned
  //     expect(finalBalanceOwner).to.equal(
  //       (BigInt(initialBalanceOwner) - BigInt(transferAmount)).toString()
  //     );
  //     expect(finalBalanceUser1).to.equal(
  //       (BigInt(initialBalanceUser1) + BigInt(transferAmount)).toString()
  //     );
  //   });
  // });

  // // describe("auto liquidity", function () {
  // //   it("should add liquidity to PancakeSwap when autoLiquidityEnabled is true", async function () {
  // //     // Enable auto liquidity
  // //     await customToken.toggleAutoLiquidity();

  // //     // Approve token transfer to the router
  // //     await customToken.approve(
  // //       customToken.pancakeswapV2Router.address,
  // //       ethers.parseEther("1000")
  // //     );

  // //     // Perform a transfer to trigger the auto liquidity mechanism
  // //     const initialBalance = await customToken.balanceOf(owner.address);
  // //     const tx = await customToken.transfer(
  // //       addr1.address,
  // //       ethers.parseEther("100")
  // //     );
  // //     const receipt = await tx.wait();

  // //     // Check if liquidity tokens were minted
  // //     const liquidityTokens = await customToken.balanceOf(customToken.address);
  // //     expect(liquidityTokens).to.be.above(initialBalance);

  // //     // Check if liquidity was added to PancakeSwap (you may need to adapt this to your contract's logic)
  // //     // You can interact with PancakeSwap contracts or use an Oracle to verify this
  // //     // For example: const pancakeSwapPair = await ethers.getContractAt("IPancakeswapV2Pair", customToken.pancakeswapV2Pair);
  // //     // Then check if liquidity was added to pancakeSwapPair.balanceOf(customToken.address) or other relevant metrics
  // //   });

  // //   it("should not add liquidity to PancakeSwap when autoLiquidityEnabled is false", async function () {
  // //     // Disable auto liquidity
  // //     await customToken.toggleAutoLiquidity();

  // //     // Approve token transfer to the router
  // //     await customToken.approve(
  // //       customToken.pancakeswapV2Router.address,
  // //       ethers.parseEther("1000")
  // //     );

  // //     // Perform a transfer to trigger the auto liquidity mechanism
  // //     const initialBalance = await customToken.balanceOf(owner.address);
  // //     const tx = await customToken.transfer(
  // //       addr1.address,
  // //       ethers.parseEther("100")
  // //     );
  // //     const receipt = await tx.wait();

  // //     // Check if liquidity tokens were not minted (contract balance remains the same)
  // //     const liquidityTokens = await customToken.balanceOf(customToken.address);
  // //     expect(liquidityTokens).to.equal(0);

  // //     // Check if liquidity was not added to PancakeSwap (you may need to adapt this to your contract's logic)
  // //     // You can interact with PancakeSwap contracts or use an Oracle to verify this
  // //     // For example: const pancakeSwapPair = await ethers.getContractAt("IPancakeswapV2Pair", customToken.pancakeswapV2Pair);
  // //     // Then check if liquidity was not added to pancakeSwapPair.balanceOf(customToken.address) or other relevant metrics
  // //   });
  // // });
});
