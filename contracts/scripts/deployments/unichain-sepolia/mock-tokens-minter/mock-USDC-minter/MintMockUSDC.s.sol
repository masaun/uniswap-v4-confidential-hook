// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../../src/mocks/MockUSDC.sol";

contract MintMockUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mockUSDCAddress = vm.envAddress("MOCK_USDC_ADDRESS");
        
        // Default mint amount: 1,000,000 USDC (with 6 decimals)
        uint256 mintAmount = 1000000 * 10**6;
        
        // You can also read a custom amount from env if needed
        try vm.envUint("MINT_AMOUNT") returns (uint256 customAmount) {
            mintAmount = customAmount;
        } catch {
            // Use default amount
        }

        // Get recipient address - default to deployer, but can be overridden
        address recipient;
        try vm.envAddress("MINT_RECIPIENT") returns (address customRecipient) {
            recipient = customRecipient;
        } catch {
            recipient = vm.addr(deployerPrivateKey);
        }

        vm.startBroadcast(deployerPrivateKey);

        MockUSDC usdc = MockUSDC(mockUSDCAddress);
        
        console.log("Minting MockUSDC...");
        console.log("MockUSDC Address:", address(usdc));
        console.log("Recipient:", recipient);
        console.log("Amount to mint:", mintAmount);
        console.log("Amount in USDC:", mintAmount / 10**6);

        // Check balance before
        uint256 balanceBefore = usdc.balanceOf(recipient);
        console.log("Balance before:", balanceBefore / 10**6, "USDC");

        // Mint tokens
        usdc.mint(recipient, mintAmount);

        // Check balance after
        uint256 balanceAfter = usdc.balanceOf(recipient);
        console.log("Balance after:", balanceAfter / 10**6, "USDC");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Mint Summary ===");
        console.log("Minted:", mintAmount / 10**6, "USDC");
        console.log("Recipient:", recipient);
        console.log("New Balance:", balanceAfter / 10**6, "USDC");
    }
}
