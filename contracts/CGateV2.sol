// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract CGateV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    address public _owner;
    uint256 public minTransactionAmount = 0; // Minimum transaction amount
    uint256 public maxTransactionAmount = 100 ether; // Maximum transaction amount
    uint256 public transferDelay; // Transfer delay period

    uint256 public lockedLiquidityAmount; // Amount of liquidity tokens locked
    bool public liquidityLocked; // Flag to track if liquidity is locked

    bool public isDeflationary = false; // Deflationary state flag
    uint256 public deflationRate; // 1000 means 10% deflation rate

    bool public autoLiquidityEnabled = true;
    mapping(address => bool) public isExcludedFromTax;

    uint256 public burnableTax = 5; // Fixed tax for burning
    uint256 public graduallyDecreasingTax = 2; // Gradually decreasing tax rate
    uint256 public liquidityTax = 200;
    uint256 public decreasingTaxRate; // Rate at which gradually decreasing tax decreases
    uint256 public decreasingTaxInterval = 3600; // Time period after which gradually decreasing tax decreases
    uint256 public lastUpdatedTaxTimestamp; // Timestamp of the last tax update

    // // PancakeSwap router address
    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address public usdt = 0x0285e1D847B88056ADd3823C456eE83D37cDD60a;
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

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) public initializer {
        _owner = msg.sender;
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __Ownable_init();
        __Pausable_init();
        _mint(_owner, _initialSupply * (10 ** uint256(_decimals)));
        isBlacklisted[msg.sender] = false;
        _whitelistedWallets[msg.sender] = true;
        _transferAllowedAt[msg.sender] = block.timestamp;
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );

        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            usdt
        );
        _approve(address(this), address(_pancakeRouter), type(uint256).max);
        IERC20Upgradeable(usdt).approve(
            address(_pancakeRouter),
            type(uint256).max
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

    function setFactoryContract(address newAddr) external onlyOwner {
        pancakeRouter = IPancakeRouter02(newAddr);
        _approve(address(this), address(newAddr), type(uint256).max);
        IERC20Upgradeable(usdt).approve(address(newAddr), type(uint256).max);
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
        require(_rate <= 10000, "Deflation rate must be between 0 and 100"); // Maximum 100% deflation
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
            10000;

        lastUpdatedTaxTimestamp = block.timestamp;
    }

    function setDecreasingTaxRate(uint256 _rate) external {
        decreasingTaxRate = _rate;
    }

    function setUSDTAddress(address _usdt) external onlyOwner {
        usdt = _usdt;
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
            uint256 burnAmount = (amount / 10000) * burnableTax; // Calculate the amount to burn
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
            recipient != pancakePair &&
            recipient != address(pancakeRouter) &&
            sender != address(pancakeRouter) &&
            sender != address(this) &&
            recipient != address(this) &&
            msg.sender != address(pancakeRouter) &&
            msg.sender != address(this)
        ) {
            taxAmount = (amount * liquidityTax) / 10000;
            uint256 liquidityAmount = taxAmount / 2;
            uint256 remainingAmount = amount - taxAmount;
            super._transfer(sender, address(this), amount);
            // Add liquidity
            _addLiquidity(liquidityAmount, remainingAmount);
        }

        // Transfer the remaining amount
        super._transfer(sender, recipient, amount - taxAmount);
    }

    // Function to add liquidity
    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) public {
        require(
            tokenAmount > 0 && bnbAmount > 0,
            "Insufficient liquidity amounts"
        );

        // Approve the PancakeSwap router to spend your tokens
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // Swap half of the collected BNB for your native tokens
        // address[] memory path = new address[](2);
        // path[1] = pancakeRouter.WETH(); // BNB
        // path[0] = address(this); // Your native token

        // pancakeRouter.swapExactTokensForETH(
        //     10000000,
        //     0, // Accept any amount of tokens
        //     path,
        //     address(this),
        //     block.timestamp + 300 // Set an appropriate deadline
        // );

        // IWETH(pancakeRouter.WETH()).withdraw(IERC20( pancakeRouter.WETH()).balanceOf(address(this)));

        _approve(address(this), address(pancakeRouter), tokenAmount / 2);
        _approve(address(usdt), address(pancakeRouter), tokenAmount / 2);
        // Add liquidity to the PancakeSwap pool
        pancakeRouter.addLiquidity(
            address(this), // Your token
            usdt,
            tokenAmount / 2,
            tokenAmount / 2, // Accept any amount of tokens
            0, // Accept any amount of BNB,
            0,
            _owner,
            block.timestamp + 300 // Set an appropriate deadline
        );
    }

    receive() external payable {}

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
