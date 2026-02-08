// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../../src/mocks/MockWETH.sol";

contract MintMockWETH is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mockWETHAddress = vm.envAddress("MOCK_WETH_ADDRESS");
        
        // Default mint amount: 10,000 WETH (with 18 decimals)
        uint256 mintAmount = 10000 * 10**18;
        
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

        MockWETH weth = MockWETH(payable(mockWETHAddress));
        
        console.log("Minting MockWETH...");
        console.log("MockWETH Address:", address(weth));
        console.log("Recipient:", recipient);
        console.log("Amount to mint:", mintAmount);
        console.log("Amount in WETH:", mintAmount / 10**18);

        // Check balance before
        uint256 balanceBefore = weth.balanceOf(recipient);
        console.log("Balance before:", balanceBefore / 10**18, "WETH");

        // Mint tokens
        weth.mint(recipient, mintAmount);

        // Check balance after
        uint256 balanceAfter = weth.balanceOf(recipient);
        console.log("Balance after:", balanceAfter / 10**18, "WETH");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Mint Summary ===");
        console.log("Minted:", mintAmount / 10**18, "WETH");
        console.log("Recipient:", recipient);
        console.log("New Balance:", balanceAfter / 10**18, "WETH");
    }
}
