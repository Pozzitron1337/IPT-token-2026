// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Excell} from "../src/Excell.sol";
import {IPT} from "../src/IPT.sol";

/**
 * $ forge script script/DeployExcell.s.sol:DeployExcell --rpc-url $SEPOLIA_RPC_URL --slow --broadcast --chain sepolia --verify -vvvv
 */
contract DeployExcell is Script {
    function run() public returns (Excell) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        address iptAddress = 0x2D47F6302111AFEfD2f7B683d2a0b1EE42C9f57A;
        console.log("IPT Token deployed at:", iptAddress);
        
        // Deploy Excell contract
        Excell excell = new Excell(iptAddress);
        
        console.log("Excell contract deployed at:", address(excell));
        console.log("Deployer (Admin):", deployer);
        console.log("IPT Token address:", iptAddress);
        
        vm.stopBroadcast();
        
        return excell;
    }
}
