// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IPT} from "../src/IPT.sol";

/**
 * $ 
 */
contract DeployIPT is Script {
    function run() public returns (IPT) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        IPT ipt = new IPT();
        
        console.log("IPT Token deployed at:", address(ipt));
        console.log("Deployer (Admin):", deployer);
        
        // Optional: grant tutor role and mint initial supply of tokens
        // ipt.grantTutorRole(deployer);
        // uint256 initialSupply = 1000000 * 10 ** 18;
        // ipt.mint(deployer, initialSupply);
        // console.log("Initial supply minted:", initialSupply);
        
        vm.stopBroadcast();
        
        return ipt;
    }
}
