// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CustomToken is ERC20, Ownable, Pausable {
    using SafeMath for uint256;

    address public _owner;
    uint256 public minTransactionAmount = 100 * (10 ** decimals()); // Minimum transaction amount
    uint256 public maxTransactionAmount = 10000 * (10 ** decimals()); // Maximum transaction amount
    uint256 public transferDelay; // Transfer delay period

    mapping(address => bool) private isBlacklisted;
    mapping(address => uint256) private _transferAllowedAt;
    mapping(address => bool) private _frozenWallets;
    mapping(address => bool) private _whitelistedWallets;
    mapping(address => VestingSchedule) private _vestingSchedules;

    struct VestingSchedule {
        uint256 startTimestamp;
        uint256 cliffDuration;
        uint256 totalDuration;
        uint256 interval;
        uint256 totalAmount;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _owner = msg.sender;
        _mint(msg.sender, _initialSupply * (10 ** uint256(_decimals)));
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function blackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "user already whitelisted");
        isBlacklisted[_user] = false;
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

    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) public view {
        _beforeTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        if (from != address(0) && to != address(0)) {
            require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds max limit"
            );
        }
        _beforeTokenTransfer(from, to, amount);
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

    function addToWhitelist(address wallet) external onlyOwner {
        _whitelistedWallets[wallet] = true;
    }

    function removeFromWhitelist(address wallet) external onlyOwner {
        _whitelistedWallets[wallet] = false;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            _whitelistedWallets[msg.sender],
            "Sender's wallet is not whitelisted"
        );
        require(!_frozenWallets[msg.sender], "Sender's wallet is frozen");
        require(amount >= minTransactionAmount, "Amount below minimum");
        require(amount <= maxTransactionAmount, "Amount exceeds maximum");
        require(
            _transferAllowedAt[msg.sender] <= block.timestamp,
            "Transfer not allowed yet"
        );
        _transferAllowedAt[msg.sender] = block.timestamp + transferDelay;
        return super.transfer(recipient, amount);
    }
}
