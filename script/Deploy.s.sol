// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IPT} from "../src/IPT.sol";
import {Excell} from "../src/Excell.sol";

/***
 * $ forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
 */
contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying all contracts to Sepolia...");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy IPT token
        console.log("\n=== Deploying IPT Token ===");
        IPT ipt = new IPT();
        console.log("IPT Token deployed at:", address(ipt));
        
        // Deploy Excell contract
        console.log("\n=== Deploying Excell Contract ===");
        Excell excell = new Excell(address(ipt));
        console.log("Excell contract deployed at:", address(excell));
        
        vm.stopBroadcast();
        
        // Verification instructions
        console.log("\n=== Verification Commands ===");
        console.log("Verify IPT Token:");
        console.log("forge verify-contract");
        console.log(address(ipt));
        console.log("src/IPT.sol:IPT --chain sepolia");
        console.log("\nVerify Excell Contract:");
        console.log("forge verify-contract");
        console.log(address(excell));
        console.log("src/Excell.sol:Excell --chain sepolia --constructor-args $(cast abi-encode 'constructor(address)'");
        console.log(address(ipt));
        console.log(")");
    }
}
