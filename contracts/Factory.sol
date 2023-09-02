// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./CustomToken.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Factory {
    CustomToken public token;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        address _uniswapRouter,
        address _liquidityPair
    ) public payable {
        token = new CustomToken(
            _name,
            _symbol,
            _decimals,
            _initialSupply,
            _uniswapRouter,
            _liquidityPair
        );

        (, , uint256 liquidity) = IUniswapV2Router02(_uniswapRouter)
            .addLiquidityETH{value: msg.value}(
            address(token),
            token.totalSupply(),
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}
