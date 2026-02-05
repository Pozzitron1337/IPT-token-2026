// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Excell} from "../src/Excell.sol";
import {IPT} from "../src/IPT.sol";

contract DeployExcell is Script {
    function run() public returns (Excell) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy IPT token first if not already deployed
        // For testing, you can deploy a new one or use existing address
        IPT ipt = new IPT();
        console.log("IPT Token deployed at:", address(ipt));
        
        // Deploy Excell contract
        Excell excell = new Excell(address(ipt));
        
        console.log("Excell contract deployed at:", address(excell));
        console.log("Deployer (Admin):", deployer);
        console.log("IPT Token address:", address(ipt));
        
        vm.stopBroadcast();
        
        return excell;
    }
}
