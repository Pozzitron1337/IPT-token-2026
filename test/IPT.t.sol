// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IPT} from "../src/IPT.sol";

contract IPTTest is Test {
    IPT public ipt;
    address public admin;
    address public tutor1;
    address public tutor2;
    address public user1;
    address public user2;

    function setUp() public {
        admin = address(this);
        tutor1 = address(0x1);
        tutor2 = address(0x2);
        user1 = address(0x3);
        user2 = address(0x4);
        
        ipt = new IPT();
        ipt.grantTutorRole(tutor1);
    }

    function test_InitialState() public view {
        assertEq(ipt.name(), "Institute of Physics and Technology. Introduction to Blockchain course points 2026");
        assertEq(ipt.symbol(), "IPT-2026");
        assertEq(ipt.decimals(), 18);
        assertEq(ipt.totalSupply(), 0);
        assertTrue(ipt.hasRole(ipt.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_Mint() public {
        uint256 amount = 1000 * 10 ** 18;
        vm.prank(tutor1);
        ipt.mint(user1, amount);
        
        assertEq(ipt.balanceOf(user1), amount);
        assertEq(ipt.totalSupply(), amount);
    }

    function test_MintOnlyTutor() public {
        vm.prank(user1);
        vm.expectRevert();
        ipt.mint(user2, 1000 * 10 ** 18);
    }

    function test_MintByMultipleTutors() public {
        uint256 amount1 = 500 * 10 ** 18;
        uint256 amount2 = 300 * 10 ** 18;
        
        ipt.grantTutorRole(tutor2);
        
        vm.prank(tutor1);
        ipt.mint(user1, amount1);
        
        vm.prank(tutor2);
        ipt.mint(user2, amount2);
        
        assertEq(ipt.balanceOf(user1), amount1);
        assertEq(ipt.balanceOf(user2), amount2);
        assertEq(ipt.totalSupply(), amount1 + amount2);
    }

    function test_Burn() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 burnAmount = 300 * 10 ** 18;
        
        vm.prank(tutor1);
        ipt.mint(user1, mintAmount);
        
        vm.prank(user1);
        ipt.burn(burnAmount);
        
        assertEq(ipt.balanceOf(user1), mintAmount - burnAmount);
        assertEq(ipt.totalSupply(), mintAmount - burnAmount);
    }

    function test_GrantTutorRole() public {
        assertFalse(ipt.hasRole(ipt.TUTOR_ROLE(), tutor2));
        
        ipt.grantTutorRole(tutor2);
        
        assertTrue(ipt.hasRole(ipt.TUTOR_ROLE(), tutor2));
        
        // Проверяем, что tutor2 теперь может минтить
        uint256 amount = 500 * 10 ** 18;
        vm.prank(tutor2);
        ipt.mint(user1, amount);
        
        assertEq(ipt.balanceOf(user1), amount);
    }

    function test_RevokeTutorRole() public {
        ipt.grantTutorRole(tutor2);
        assertTrue(ipt.hasRole(ipt.TUTOR_ROLE(), tutor2));
        
        ipt.revokeTutorRole(tutor2);
        assertFalse(ipt.hasRole(ipt.TUTOR_ROLE(), tutor2));
        
        // Проверяем, что tutor2 больше не может минтить
        vm.prank(tutor2);
        vm.expectRevert();
        ipt.mint(user1, 1000 * 10 ** 18);
    }

    function test_GrantTutorRoleOnlyAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        ipt.grantTutorRole(tutor2);
    }

    function test_RevokeTutorRoleOnlyAdmin() public {
        ipt.grantTutorRole(tutor2);
        
        vm.prank(user1);
        vm.expectRevert();
        ipt.revokeTutorRole(tutor2);
    }

    function test_Transfer() public {
        uint256 amount = 500 * 10 ** 18;
        vm.prank(tutor1);
        ipt.mint(user1, amount);
        
        vm.prank(user1);
        bool success = ipt.transfer(user2, amount);
        assertTrue(success);
        
        assertEq(ipt.balanceOf(user1), 0);
        assertEq(ipt.balanceOf(user2), amount);
    }
}
