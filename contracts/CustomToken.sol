// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// import "./IPancakeswapV2Factory.sol";
// import "./IPancakeswapV2Pair.sol";
// import "./IPancakeswapV2Router02.sol";

contract CustomToken is ERC20, ERC20Burnable, Ownable, Pausable {
    using SafeMath for uint256;

    address public _owner;
    uint256 public minTransactionAmount; // Minimum transaction amount
    uint256 public maxTransactionAmount; // Maximum transaction amount
    uint256 public transferDelay; // Transfer delay period

    uint256 public lockedLiquidityAmount; // Amount of liquidity tokens locked
    bool public liquidityLocked; // Flag to track if liquidity is locked

    bool public isDeflationary = false; // Deflationary state flag
    uint256 public deflationRate; // 1000 means 10% deflation rate

    // Address to collect USDC tokens for liquidity
    address public usdcLiquidityAddress;

    uint256 public burnableTax; // Fixed tax for burning
    uint256 public graduallyDecreasingTax; // Gradually decreasing tax rate
    uint256 public decreasingTaxRate; // Rate at which gradually decreasing tax decreases
    uint256 public decreasingTaxInterval; // Time period after which gradually decreasing tax decreases
    uint256 public lastUpdatedTaxTimestamp; // Timestamp of the last tax update

    // // // PancakeSwap router address
    // IPancakeswapV2Router02 public immutable pancakeswapV2Router;
    // address public immutable pancakeswapV2Pair;

    // // Flag to enable/disable auto liquidity
    // bool public autoLiquidityEnabled = true;

    // // Whitelist to exclude addresses from sale tax
    // mapping(address => bool) public isExcludedFromTax;

    // // Tax rates for different transaction limits
    // uint256 public lowLimitTaxRate = 5; // 5% tax for transactions below low limit
    // uint256 public highLimitTaxRate = 10; // 10% tax for transactions above low limit

    // // Limits for different tax rates
    // uint256 public lowLimit = 1000 ether;
    // uint256 public highLimit = 5000 ether;

    struct VestingInfo {
        uint256 amount; // Total amount of tokens to vest
        address beneficiary; // Wallet address to receive tokens
        uint256 percentageOfTokensToBeReleased; // Percentage of tokens to release at each interval
        uint256 timeInterval; // Interval in seconds for releasing tokens
        uint256 lastWithdrawTimestamp; // Timestamp of the last token withdrawal
        uint256 vestingDuration; // Vesting duration in seconds
        uint256 startTime; // Vesting start time (timestamp)
    }

    mapping(address => bool) private isBlacklisted;
    mapping(address => uint256) private _transferAllowedAt;
    mapping(address => bool) private _frozenWallets;
    mapping(address => bool) private _whitelistedWallets;
    mapping(address => bool) public signers;
    mapping(address => VestingInfo) private vestingInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address[] memory _initialSigners,
        uint256 _deflationRate,
        uint256 _initialBurnableTax,
        uint256 _initialGraduallyDecreasingTax,
        uint256 _initialDecreasingTaxRate,
        uint256 _initialDecreasingTaxInterval
    )
        // address _usdcLiquidityAddress
        ERC20(_name, _symbol)
    {
        _owner = msg.sender;
        _mint(_owner, _initialSupply * (10 ** uint256(_decimals)));
        isBlacklisted[msg.sender] = false;
        _whitelistedWallets[msg.sender] = true;
        _transferAllowedAt[msg.sender] = block.timestamp;
        _frozenWallets[msg.sender] = false;
        deflationRate = _deflationRate;
        burnableTax = _initialBurnableTax;
        graduallyDecreasingTax = _initialGraduallyDecreasingTax;
        decreasingTaxRate = _initialDecreasingTaxRate;
        decreasingTaxInterval = _initialDecreasingTaxInterval;
        lastUpdatedTaxTimestamp = block.timestamp;
        // usdcLiquidityAddress = _usdcLiquidityAddress;
        // IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // );
        // pancakeswapV2Pair = IPancakeswapV2Factory(
        //     _pancakeswapV2Router.factory()
        // ).createPair(address(this), _pancakeswapV2Router.WETH());

        // // set the rest of the contract variables
        // pancakeswapV2Router = _pancakeswapV2Router;

        for (uint256 i = 0; i < _initialSigners.length; i++) {
            signers[_initialSigners[i]] = true;
        }
    }

    modifier onlySigner() {
        require(signers[msg.sender], "Sender is not a signer");
        _;
    }
    // Modifier to check if liquidity is locked
    modifier liquidityNotLocked() {
        require(!liquidityLocked, "Liquidity is locked");
        _;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function blackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "user already whitelisted");
        isBlacklisted[_user] = false;
    }

    function isBlackList(address _user) external view returns (bool) {
        return isBlacklisted[_user];
    }

    function setMinTransactionAmount(uint256 amount) external onlyOwner {
        minTransactionAmount = amount;
    }

    function setMaxTransferAmount(uint256 amount) external onlyOwner {
        maxTransactionAmount = amount;
    }

    function setTransferDelay(uint256 delay) external onlyOwner {
        transferDelay = delay;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function freezeWallet(address wallet) external onlyOwner {
        _frozenWallets[wallet] = true;
    }

    function unfreezeWallet(address wallet) external onlyOwner {
        _frozenWallets[wallet] = false;
    }

    function isFrozen(address wallet) external view returns (bool) {
        return _frozenWallets[wallet];
    }

    function addToWhitelist(address wallet) external onlyOwner {
        _whitelistedWallets[wallet] = true;
    }

    function removeFromWhitelist(address wallet) external onlyOwner {
        _whitelistedWallets[wallet] = false;
    }

    function transferAllowedAt() external view returns (uint256) {
        return _transferAllowedAt[msg.sender];
    }

    // Enable or disable deflationary mechanism
    function setDeflationary(bool _enabled) external onlyOwner {
        isDeflationary = _enabled;
    }

    // Set the deflation rate (e.g., 1000 means 10%)
    function setDeflationRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100, "Deflation rate must be between 0 and 100"); // Maximum 100% deflation
        deflationRate = _rate;
    }

    function isWhitelisted(address user) public view returns (bool) {
        return _whitelistedWallets[user];
    }

    // // Function to set the USDC liquidity address
    // function setUsdcLiquidityAddress(
    //     address _usdcLiquidityAddress
    // ) external onlyOwner {
    //     usdcLiquidityAddress = _usdcLiquidityAddress;
    // }

    // // Function to enable/disable auto liquidity
    // function toggleAutoLiquidity() external onlyOwner {
    //     autoLiquidityEnabled = !autoLiquidityEnabled;
    // }

    // // Function to set the tax rates and limits
    // function setTaxRatesAndLimits(
    //     uint256 _lowLimitTaxRate,
    //     uint256 _highLimitTaxRate,
    //     uint256 _lowLimit,
    //     uint256 _highLimit
    // ) external onlyOwner {
    //     lowLimitTaxRate = _lowLimitTaxRate;
    //     highLimitTaxRate = _highLimitTaxRate;
    //     lowLimit = _lowLimit;
    //     highLimit = _highLimit;
    // }

    // // Function to exclude an address from the sale tax
    // function excludeFromTax(address _address) external onlyOwner {
    //     isExcludedFromTax[_address] = true;
    // }

    // // Function to include an address in the sale tax
    // function includeInTax(address _address) external onlyOwner {
    //     isExcludedFromTax[_address] = false;
    // }

    // Function to update the gradually decreasing tax rate
    function updateGraduallyDecreasingTax() external {
        uint256 timeSinceLastUpdate = block.timestamp - lastUpdatedTaxTimestamp;
        require(
            timeSinceLastUpdate >= decreasingTaxInterval,
            "Tax update interval not reached"
        );

        // Calculate the new tax rate
        graduallyDecreasingTax =
            (graduallyDecreasingTax * (100 - decreasingTaxRate)) /
            100;

        lastUpdatedTaxTimestamp = block.timestamp;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        require(isBlacklisted[msg.sender], "Sender's wallet is blacklisted");
        require(!_frozenWallets[msg.sender], "Sender's wallet is frozen");
        require(amount >= minTransactionAmount, "Amount below minimum");
        require(amount <= maxTransactionAmount, "Amount exceeds maximum");
        require(
            _transferAllowedAt[msg.sender] <= block.timestamp,
            "Transfer not allowed yet"
        );
        _transferAllowedAt[msg.sender] = block.timestamp + transferDelay;

        if (isDeflationary) {
            uint256 burnAmount = (amount / 100) * burnableTax; // Calculate the amount to burn
            _burn(msg.sender, burnAmount); // Burn tokens

            uint256 afterBurn = amount - burnAmount;
            _transfer(_owner, recipient, afterBurn); // Transfer the remaining tokens
        } else {
            _transfer(_owner, recipient, amount); // Transfer without burning
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(isBlacklisted[msg.sender], "Sender's wallet is blacklisted");
        require(!_frozenWallets[msg.sender], "Sender's wallet is frozen");
        require(amount >= minTransactionAmount, "Amount below minimum");
        require(amount <= maxTransactionAmount, "Amount exceeds maximum");
        require(
            _transferAllowedAt[msg.sender] <= block.timestamp,
            "Transfer not allowed yet"
        );
        _transferAllowedAt[msg.sender] = block.timestamp + transferDelay;
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // Transfer function with auto liquidity and tax
    // function _transfer(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) internal override {
    //     require(from != address(0), "Transfer from the zero address");
    //     require(to != address(0), "Transfer to the zero address");
    //     require(amount > 0, "Transfer amount must be greater than zero");

    //     // Calculate the tax rate based on the transaction amount
    //     uint256 taxRate = calculateTaxRate(amount);

    //     // Calculate the tax amount
    //     uint256 taxAmount = (amount * taxRate) / 100;

    //     // Calculate the amount to send after tax
    //     uint256 amountAfterTax = amount - taxAmount;

    //     // Deduct the tax from the sender
    //     super._transfer(from, address(this), taxAmount);

    //     if (autoLiquidityEnabled && from != usdcLiquidityAddress) {
    //         // Add liquidity to PancakeSwap
    //         addLiquidity(taxAmount, amountAfterTax);
    //     }

    //     // Transfer the remaining amount to the recipient
    //     super._transfer(from, to, amountAfterTax);
    // }

    // // Calculate the tax rate based on the transaction amount
    // function calculateTaxRate(uint256 amount) internal view returns (uint256) {
    //     if (isExcludedFromTax[msg.sender] || msg.sender == owner()) {
    //         return 0; // No tax for excluded addresses or owner
    //     } else if (amount >= highLimit) {
    //         return highLimitTaxRate;
    //     } else if (amount >= lowLimit) {
    //         return lowLimitTaxRate;
    //     } else {
    //         return 0; // No tax if below low limit
    //     }
    // }

    // Function to add liquidity to PancakeSwap
    // function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal {
    //     // Approve the router to spend tokens
    //     _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    //     // Add liquidity to the pool
    //     pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
    //         address(this), // Your token address
    //         tokenAmount, // Amount of your token
    //         0, // Minimum amount of your token to receive
    //         0, // Minimum amount of BNB to receive
    //         address(this), // Address to receive LP tokens
    //         block.timestamp + 300 // Deadline (5 minutes from now)
    //     );

    //     // Check if there are any leftover tokens and send them back to the owner
    //     uint256 remainingTokens = super.balanceOf(address(this));
    //     if (remainingTokens > 0) {
    //         super.transfer(_owner, remainingTokens);
    //     }
    // }

    // Function to lock liquidity
    function lockLiquidity(
        uint256 amount
    ) external onlySigner liquidityNotLocked {
        require(amount <= balanceOf(address(this)), "Insufficient balance");

        // Transfer the liquidity tokens to the contract itself
        transfer(address(this), amount);

        lockedLiquidityAmount = lockedLiquidityAmount.add(amount);
        liquidityLocked = true;
    }

    // Function to unlock locked liquidity
    function unlockLiquidity(uint256 amount) external onlySigner {
        require(liquidityLocked, "Liquidity is not locked");
        require(lockedLiquidityAmount >= amount, "Not enough locked liquidity");

        // Transfer the locked liquidity tokens back to the contract owner
        transfer(_owner, amount);

        lockedLiquidityAmount = lockedLiquidityAmount.sub(amount);
        liquidityLocked = false;
    }

    // Function to add vesting for a wallet
    function addVesting(
        address wallet,
        uint256 amount,
        uint256 percentageOfTokensToBeReleased,
        uint256 timeInterval,
        uint256 vestingDuration
    ) external onlyOwner {
        require(!_whitelistedWallets[wallet], "Wallet is already whitelisted");
        require(vestingInfo[wallet].amount == 0, "Wallet already has vesting");

        // Ensure the vesting parameters are valid
        require(amount > 0, "Invalid vesting amount");
        require(
            percentageOfTokensToBeReleased > 0 &&
                percentageOfTokensToBeReleased <= 100,
            "Invalid percentage"
        );

        require(timeInterval > 0, "Invalid time interval");
        require(
            timeInterval <= vestingDuration,
            "Time interval should not exceed vesting duration"
        );

        vestingInfo[wallet] = VestingInfo({
            amount: amount,
            beneficiary: wallet,
            percentageOfTokensToBeReleased: percentageOfTokensToBeReleased,
            timeInterval: timeInterval,
            lastWithdrawTimestamp: block.timestamp,
            vestingDuration: vestingDuration,
            startTime: block.timestamp
        });

        _whitelistedWallets[wallet] = true;
    }

    // Function to claim vested tokens for a wallet
    function claimVestedTokens() external returns (uint256) {
        VestingInfo storage info = vestingInfo[msg.sender];

        require(info.amount > 0, "No vesting found for the wallet");
        require(
            block.timestamp >= info.startTime,
            "Vesting has not started yet"
        );

        uint256 vestedAmount = calculateVestedAmount(info);
        require(vestedAmount > 0, "No tokens are currently vested");

        // Calculate the amount to release based on the percentage
        uint256 amountToRelease = (vestedAmount *
            info.percentageOfTokensToBeReleased) / 100;

        // Calculate the time since the last withdrawal
        uint256 timeSinceLastWithdraw = block.timestamp -
            info.lastWithdrawTimestamp;

        // Ensure that the time interval has passed since the last withdrawal
        require(
            timeSinceLastWithdraw >= info.timeInterval,
            "Time interval not reached"
        );

        // Transfer the vested tokens to the wallet
        _transfer(address(this), info.beneficiary, amountToRelease);

        // Update the last withdrawal timestamp
        info.lastWithdrawTimestamp = block.timestamp;

        return amountToRelease;
    }

    // Function to calculate the currently vested amount for a wallet
    function calculateVestedAmount(
        VestingInfo storage info
    ) internal view returns (uint256) {
        if (block.timestamp >= info.startTime.add(info.vestingDuration)) {
            return info.amount; // All tokens are vested
        }

        // Calculate the vested amount linearly
        uint256 elapsedTime = block.timestamp.sub(info.startTime);
        uint256 vestedPercentage = elapsedTime.mul(1e18).div(
            info.vestingDuration
        );
        uint256 vestedAmount = info.amount.mul(vestedPercentage).div(1e18);

        return vestedAmount;
    }
}
