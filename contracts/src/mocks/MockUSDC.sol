// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing on Unichain Sepolia
 * @dev Mintable ERC20 token with 6 decimals (same as real USDC)
 */
contract MockUSDC is ERC20, Ownable {
    constructor() ERC20("Mock USD Coin", "USDC") Ownable(msg.sender) {}

    /**
     * @notice Returns 6 decimals (same as real USDC)
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @notice Mint tokens to any address
     * @param to Recipient address
     * @param amount Amount to mint (in base units with 6 decimals)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens from caller
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
