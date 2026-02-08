// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../../../src/mocks/MockWETH.sol";

contract DeployMockWETH is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("============================================================");
        console.log("Deploying MockWETH to Unichain Sepolia");
        console.log("============================================================");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        MockWETH mockWETH = new MockWETH();

        vm.stopBroadcast();

        console.log("MockWETH deployed at:", address(mockWETH));
        console.log("Deployer (owner):", msg.sender);
        console.log("Decimals:", mockWETH.decimals());
        console.log("Name:", mockWETH.name());
        console.log("Symbol:", mockWETH.symbol());
        console.log("");
        console.log("============================================================");
        console.log("Deployment Complete!");
        console.log("============================================================");
        console.log("");
        console.log("Next steps:");
        console.log("1. Copy the address above");
        console.log("2. Add to .env: MOCK_WETH_ADDRESS=<address>");
        console.log("3. Run mint script to mint tokens");
    }
}
