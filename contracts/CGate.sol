// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter02.sol";

contract CGate is ERC20, ERC20Burnable, Ownable, Pausable {
    using SafeMath for uint256;

    address public _owner;
    uint256 public minTransactionAmount; // Minimum transaction amount
    uint256 public maxTransactionAmount; // Maximum transaction amount
    uint256 public transferDelay; // Transfer delay period

    uint256 public lockedLiquidityAmount; // Amount of liquidity tokens locked
    bool public liquidityLocked; // Flag to track if liquidity is locked

    bool public isDeflationary = false; // Deflationary state flag
    uint256 public deflationRate; // 1000 means 10% deflation rate

    bool public autoLiquidityEnabled = true;
    mapping(address => bool) public isExcludedFromTax;

    uint256 public burnableTax; // Fixed tax for burning
    uint256 public graduallyDecreasingTax; // Gradually decreasing tax rate
    uint256 public liquidityTax;
    uint256 public decreasingTaxRate; // Rate at which gradually decreasing tax decreases
    uint256 public decreasingTaxInterval; // Time period after which gradually decreasing tax decreases
    uint256 public lastUpdatedTaxTimestamp; // Timestamp of the last tax update

    // // PancakeSwap router address
    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    struct Vesting {
        uint256 amount;
        address beneficiary;
        uint256 percentageOfTokensToBeReleased;
        uint256 timeInterval;
        uint256 lastWithdrawTimestamp;
        uint256 claimedTokens;
    }

    mapping(address => bool) private isBlacklisted;
    mapping(address => uint256) private _transferAllowedAt;
    mapping(address => uint256) private _frozenWallets;
    mapping(address => bool) private _whitelistedWallets;
    mapping(address => bool) public signers;
    mapping(address => Vesting) public vestingInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _owner = msg.sender;
        _mint(_owner, _initialSupply * (10 ** uint256(_decimals)));
        isBlacklisted[msg.sender] = false;
        _whitelistedWallets[msg.sender] = true;
        _transferAllowedAt[msg.sender] = block.timestamp;
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );

        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
    }

    // Modifier to check if liquidity is locked
    modifier liquidityNotLocked() {
        require(!liquidityLocked, "Liquidity is locked");
        _;
    }
    modifier whenNotFrozen(address wallet) {
        require(
            _frozenWallets[wallet] == 0 ||
                block.timestamp > _frozenWallets[wallet],
            "Wallet is frozen"
        );
        _;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function blackList(address _user) external onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) external onlyOwner {
        require(isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = false;
    }

    function isBlackList(address _user) public view returns (bool) {
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

    function setLiquidtyTax(uint256 _liquidityTax) external {
        liquidityTax = _liquidityTax;
    }

    function setBurnableTax(uint256 _burnableTax) external {
        burnableTax = _burnableTax;
    }

    function isWhitelisted(address user) public view returns (bool) {
        return _whitelistedWallets[user];
    }

    function freezeWallet(
        address wallet,
        uint256 freezeDuration
    ) external onlyOwner {
        require(wallet != address(0), "Invalid wallet address");
        _frozenWallets[wallet] = block.timestamp + freezeDuration;
    }

    function unfreezeWallet(address wallet) external onlyOwner {
        _frozenWallets[wallet] = 0;
    }

    // Function to enable/disable auto liquidity
    function toggleAutoLiquidity() external onlyOwner {
        autoLiquidityEnabled = !autoLiquidityEnabled;
    }

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

    function setDecreasingTaxRate(uint256 _rate) external {
        decreasingTaxRate = _rate;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused whenNotFrozen(msg.sender) returns (bool) {
        require(!isBlacklisted[msg.sender], "Sender's wallet is blacklisted");
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
    ) public override whenNotFrozen(from) returns (bool) {
        require(!isBlacklisted[msg.sender], "Sender's wallet is blacklisted");
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= maxTransactionAmount,
            "Exceeds max transaction amount"
        );

        // Apply taxes
        uint256 taxAmount = 0;
        if (
            autoLiquidityEnabled &&
            pancakePair != address(0) &&
            sender != pancakePair &&
            recipient != pancakePair
        ) {
            taxAmount = (amount * liquidityTax) / 100;
            uint256 liquidityAmount = taxAmount / 2;
            uint256 remainingAmount = amount - taxAmount;

            // Add liquidity
            _addLiquidity(liquidityAmount, remainingAmount);
        }

        // Transfer the remaining amount
        super._transfer(sender, recipient, amount - taxAmount);
    }

    // Function to add liquidity
    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal {
        require(
            tokenAmount > 0 && bnbAmount > 0,
            "Insufficient liquidity amounts"
        );

        // Approve the PancakeSwap router to spend your tokens
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // Swap half of the collected BNB for your native tokens
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH(); // BNB
        path[1] = address(this); // Your native token

        pancakeRouter.swapExactETHForTokens{value: bnbAmount / 2}(
            0, // Accept any amount of tokens
            path,
            address(this),
            block.timestamp + 300 // Set an appropriate deadline
        );

        // Approve the PancakeSwap router to spend half of your native tokens
        _approve(address(this), address(pancakeRouter), tokenAmount / 2);

        // Add liquidity to the PancakeSwap pool
        pancakeRouter.addLiquidityETH{value: bnbAmount / 2}(
            address(this), // Your token
            tokenAmount / 2,
            0, // Accept any amount of tokens
            0, // Accept any amount of BNB
            _owner,
            block.timestamp + 300 // Set an appropriate deadline
        );
    }

    // Function to lock liquidity
    function lockLiquidity(uint256 amount) external liquidityNotLocked {
        require(amount <= balanceOf(address(this)), "Insufficient balance");

        // Transfer the liquidity tokens to the contract itself
        transfer(address(this), amount);

        lockedLiquidityAmount = lockedLiquidityAmount.add(amount);
        liquidityLocked = true;
    }

    // Function to unlock locked liquidity
    function unlockLiquidity(uint256 amount) external {
        require(liquidityLocked, "Liquidity is not locked");
        require(lockedLiquidityAmount >= amount, "Not enough locked liquidity");

        // Transfer the locked liquidity tokens back to the contract owner
        transfer(_owner, amount);

        lockedLiquidityAmount = lockedLiquidityAmount.sub(amount);
        liquidityLocked = false;
    }

    // Function to add vesting for a wallet
    function addVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 percentageToRelease,
        uint256 timeInterval
    ) external onlyOwner {
        require(
            beneficiary != address(0),
            "Beneficiary address cannot be zero"
        );
        require(
            percentageToRelease > 0 && percentageToRelease <= 100,
            "Percentage must be between 1 and 100"
        );
        require(timeInterval > 0, "Time interval must be greater than zero");

        Vesting storage vesting = vestingInfo[beneficiary];
        vesting.amount = amount;
        vesting.beneficiary = beneficiary;
        vesting.percentageOfTokensToBeReleased = percentageToRelease;
        vesting.timeInterval = timeInterval;
        vesting.lastWithdrawTimestamp = block.timestamp;
        vesting.claimedTokens = 0;
    }

    function claim() external {
        Vesting storage vesting = vestingInfo[msg.sender];
        require(vesting.amount > 0, "No vesting schedule found for the sender");

        uint256 currentTime = block.timestamp;
        uint256 elapsedTime = currentTime - vesting.lastWithdrawTimestamp;
        uint256 totalVested = vesting.amount;

        require(
            elapsedTime >= vesting.timeInterval,
            "Tokens cannot be claimed yet"
        );

        // Calculate the tokens to release in this claim
        uint256 tokensToRelease = (totalVested *
            vesting.percentageOfTokensToBeReleased) / 100;
        vesting.claimedTokens += tokensToRelease;
        vesting.lastWithdrawTimestamp = currentTime;

        require(
            tokensToRelease <= totalVested,
            "Tokens to claim exceed total vested tokens"
        );
        require(
            vesting.claimedTokens <= vesting.amount,
            "Not enough tokens in the vesting schedule"
        );

        // Transfer the tokens to the beneficiary
        _transfer(_owner, msg.sender, tokensToRelease);
    }
}
