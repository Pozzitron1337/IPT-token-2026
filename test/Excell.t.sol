// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Excell} from "../src/Excell.sol";
import {IExcell} from "../src/interfaces/IExcell.sol";
import {IPT} from "../src/IPT.sol";

contract ExcellTest is Test {
    Excell public excell;
    IPT public ipt;
    address public admin;
    address public tutor1;
    address public tutor2;
    address public student1;
    address public student2;
    address public student3;

    function setUp() public {
        admin = address(this);
        tutor1 = address(0x1);
        tutor2 = address(0x2);
        student1 = address(0x3);
        student2 = address(0x4);
        student3 = address(0x5);

        // Deploy IPT token first
        ipt = new IPT();
        
        // Grant tutor roles in IPT token
        ipt.grantTutorRole(tutor1);
        ipt.grantTutorRole(tutor2);
        
        // Deploy Excell contract
        excell = new Excell(address(ipt));
    }

    function test_InitialState() public view {
        assertEq(address(excell.iptToken()), address(ipt));
    }

    // Points Request Tests (via lab completion)
    function test_LabCompletionCreatesPointsRequest() public {
        // Student completes lab and requests points
        uint256 labReward = excell.getLabReward("lab_wallet_creation");
        
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        assertEq(requestId, 1);
        assertEq(excell.getStudentPointsRequests(student1).length, 1);
        
        IExcell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.requestId, requestId);
        assertEq(request.studentAddress, student1);
        assertEq(request.amount, labReward);
        assertEq(request.description, "Lab: wallet creation completed");
        assertEq(request.labName, "lab_wallet_creation");
        assertEq(uint256(request.status), uint256(IExcell.RequestStatus.Pending));
        assertGt(request.requestDate, 0);
    }

    function test_TutorApprovesPointsRequest() public {
        // Setup
        uint256 labReward = excell.getLabReward("lab_wallet_creation");
        
        // Mint tokens to tutor so they can transfer them
        vm.prank(admin);
        ipt.mint(tutor1, labReward);
        
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        uint256 studentBalanceBefore = ipt.balanceOf(student1);
        uint256 tutorBalanceBefore = ipt.balanceOf(tutor1);
        
        // Tutor approves token transfer to Excell contract
        vm.prank(tutor1);
        ipt.approve(address(excell), labReward);
        
        // Tutor approves points request
        vm.prank(tutor1);
        excell.fulfillPointsRequest(requestId);
        
        IExcell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(uint256(request.status), uint256(IExcell.RequestStatus.Approved));
        assertGt(request.approvalDate, 0);
        assertEq(request.approvedBy, tutor1);
        
        // Check tokens were transferred from tutor to student
        uint256 studentBalanceAfter = ipt.balanceOf(student1);
        uint256 tutorBalanceAfter = ipt.balanceOf(tutor1);
        assertEq(studentBalanceAfter - studentBalanceBefore, labReward);
        assertEq(tutorBalanceBefore - tutorBalanceAfter, labReward);
    }

    function test_ApprovePointsRequestOnlyTutor() public {
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        // Non-tutor tries to approve
        vm.prank(student2);
        vm.expectRevert("Excell: Only tutors can approve points requests");
        excell.fulfillPointsRequest(requestId);
    }

    function test_ApproveNonExistentRequest() public {
        vm.prank(tutor1);
        vm.expectRevert("Excell: Request does not exist");
        excell.fulfillPointsRequest(999);
    }

    function test_ApprovePointsRequestInsufficientBalance() public {
        // Don't mint tokens to tutor - they won't have enough balance
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        // Tutor tries to approve but doesn't have enough tokens
        vm.prank(tutor1);
        vm.expectRevert("Excell: Insufficient tutor balance");
        excell.fulfillPointsRequest(requestId);
    }

    function test_ApprovePointsRequestInsufficientAllowance() public {
        uint256 labReward = excell.getLabReward("lab_wallet_creation");
        
        // Mint tokens to tutor
        vm.prank(admin);
        ipt.mint(tutor1, labReward);
        
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        // Tutor doesn't approve token transfer - insufficient allowance
        vm.prank(tutor1);
        vm.expectRevert("Excell: Insufficient allowance");
        excell.fulfillPointsRequest(requestId);
    }

    function test_ApproveAlreadyApprovedRequest() public {
        uint256 labReward = excell.getLabReward("lab_wallet_creation");
        vm.prank(admin);
        ipt.mint(tutor1, labReward);
        
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        // Tutor approves token transfer
        vm.prank(tutor1);
        ipt.approve(address(excell), labReward);
        
        vm.prank(tutor1);
        excell.fulfillPointsRequest(requestId);
        
        vm.prank(tutor2);
        vm.expectRevert("Excell: Request already processed");
        excell.fulfillPointsRequest(requestId);
    }

    function test_GetStudentPointsRequests() public {
        vm.prank(student1);
        excell.labWalletCreation();
        
        vm.prank(student1);
        excell.labSmartContract();
        
        IExcell.PointsRequest[] memory requests = excell.getStudentPointsRequests(student1);
        assertEq(requests.length, 2);
        assertEq(requests[0].amount, excell.getLabReward("lab_wallet_creation"));
        assertEq(requests[1].amount, excell.getLabReward("lab_smart_contract"));
    }

    function test_GetStudentPendingPointsRequests() public {
        uint256 lab1Reward = excell.getLabReward("lab_wallet_creation");
        uint256 lab2Reward = excell.getLabReward("lab_smart_contract");
        vm.prank(admin);
        ipt.mint(tutor1, lab1Reward + lab2Reward);

        vm.prank(student1);
        excell.labWalletCreation();
        vm.prank(student1);
        excell.labSmartContract();

        vm.prank(student2);
        excell.labWalletCreation();

        // Approve one of student1's requests
        vm.prank(tutor1);
        ipt.approve(address(excell), lab1Reward);
        vm.prank(tutor1);
        excell.fulfillPointsRequest(1);

        // student1: 1 approved, 1 pending
        (IExcell.PointsRequest[] memory student1Pending, uint256[] memory student1Ids) = excell.getStudentPendingPointsRequests(student1);
        assertEq(student1Pending.length, 1);
        assertEq(student1Ids.length, 1);
        assertEq(student1Pending[0].requestId, 2);
        assertEq(student1Pending[0].amount, lab2Reward);
        assertEq(uint256(student1Pending[0].status), uint256(IExcell.RequestStatus.Pending));

        // student2: 1 pending
        (IExcell.PointsRequest[] memory student2Pending, uint256[] memory student2Ids) = excell.getStudentPendingPointsRequests(student2);
        assertEq(student2Pending.length, 1);
        assertEq(student2Ids.length, 1);
        assertEq(student2Pending[0].requestId, 3);
        assertEq(student2Pending[0].amount, lab1Reward);

        // student3: no requests
        (IExcell.PointsRequest[] memory student3Pending, uint256[] memory student3Ids) = excell.getStudentPendingPointsRequests(student3);
        assertEq(student3Pending.length, 0);
        assertEq(student3Ids.length, 0);
    }

    // Lab Functions Tests
    function test_LabIntroduction() public {
        // Student completes lab_wallet_creation
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        assertEq(requestId, 1);
        assertTrue(excell.completedLabs(student1, "lab_wallet_creation"));
        
        IExcell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.amount, excell.getLabReward("lab_wallet_creation"));
        assertEq(request.description, "Lab: wallet creation completed");
        assertEq(request.studentAddress, student1);
    }

    function test_LabErc20() public {
        // Student completes lab_erc20
        vm.prank(student1);
        uint256 requestId = excell.labErc20();
        
        assertEq(requestId, 1);
        assertTrue(excell.completedLabs(student1, "lab_erc20"));
        
        IExcell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.amount, excell.getLabReward("lab_erc20"));
        assertEq(request.description, "Lab: ERC20 completed");
    }

    function test_LabNft() public {
        // Student completes lab_nft
        vm.prank(student1);
        uint256 requestId = excell.labNft();
        
        assertEq(requestId, 1);
        assertTrue(excell.completedLabs(student1, "lab_nft"));
        
        IExcell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.amount, excell.getLabReward("lab_nft"));
        assertEq(request.description, "Lab: NFT completed");
    }

    function test_CompleteAllLabs() public {
        // Complete all labs
        vm.prank(student1);
        excell.labWalletCreation();
        
        vm.prank(student1);
        excell.labErc20();
        
        vm.prank(student1);
        excell.labNft();
        
        assertTrue(excell.completedLabs(student1, "lab_wallet_creation"));
        assertTrue(excell.completedLabs(student1, "lab_erc20"));
        assertTrue(excell.completedLabs(student1, "lab_nft"));
        
        assertEq(excell.getStudentPointsRequests(student1).length, 3);
    }

    function test_LabCannotCompleteTwice() public {
        // Complete lab once
        vm.prank(student1);
        excell.labWalletCreation();
        
        // Try to complete again
        vm.prank(student1);
        vm.expectRevert("Excell: Lab already completed");
        excell.labWalletCreation();
    }

    function test_RejectLabRequestResetsCompletedLab() public {
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        assertTrue(excell.completedLabs(student1, "lab_wallet_creation"));
        
        // Tutor rejects the request
        vm.prank(tutor1);
        excell.rejectPointsRequest(requestId);
        
        // completedLabs should be reset - student can retry
        assertFalse(excell.completedLabs(student1, "lab_wallet_creation"));
        
        // Student can complete the lab again
        vm.prank(student1);
        uint256 newRequestId = excell.labWalletCreation();
        assertEq(newRequestId, 2);
        assertTrue(excell.completedLabs(student1, "lab_wallet_creation"));
    }

    function test_LabApprovalTransfersTokens() public {
        uint256 labAward = excell.getLabReward("lab_wallet_creation");
        
        // Mint tokens to tutor so they can transfer them
        vm.prank(admin);
        ipt.mint(tutor1, labAward);
        
        // Complete lab
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        uint256 studentBalanceBefore = ipt.balanceOf(student1);
        uint256 tutorBalanceBefore = ipt.balanceOf(tutor1);
        
        // Tutor approves token transfer to Excell contract
        vm.prank(tutor1);
        ipt.approve(address(excell), labAward);
        
        // Tutor approves points request
        vm.prank(tutor1);
        excell.fulfillPointsRequest(requestId);
        
        uint256 studentBalanceAfter = ipt.balanceOf(student1);
        uint256 tutorBalanceAfter = ipt.balanceOf(tutor1);
        assertEq(studentBalanceAfter - studentBalanceBefore, labAward);
        assertEq(tutorBalanceBefore - tutorBalanceAfter, labAward);
    }

    function test_HasCompletedLab() public {
        assertFalse(excell.completedLabs(student1, "lab_wallet_creation"));
        assertFalse(excell.completedLabs(student1, "lab_erc20"));
        assertFalse(excell.completedLabs(student1, "lab_nft"));
        
        vm.prank(student1);
        excell.labWalletCreation();
        
        assertTrue(excell.completedLabs(student1, "lab_wallet_creation"));
        assertFalse(excell.completedLabs(student1, "lab_erc20"));
        assertFalse(excell.completedLabs(student1, "lab_nft"));
    }
}
