// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockWETH
 * @notice Mock Wrapped Ether token for testing on Unichain Sepolia
 * @dev Mintable ERC20 token with 18 decimals (same as real WETH)
 */
contract MockWETH is ERC20, Ownable {
    constructor() ERC20("Mock Wrapped Ether", "WETH") Ownable(msg.sender) {}

    /**
     * @notice Returns 18 decimals (same as real WETH)
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @notice Mint tokens to any address
     * @param to Recipient address
     * @param amount Amount to mint (in base units with 18 decimals)
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

    /**
     * @notice Deposit ETH and mint WETH (for testing convenience)
     */
    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH by burning WETH
     * @param amount Amount of WETH to burn and withdraw as ETH
     */
    function withdraw(uint256 amount) public {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Allow contract to receive ETH
     */
    receive() external payable {
        _mint(msg.sender, msg.value);
    }
}
