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
        assertEq(excell.getStudentCount(), 0);
        assertEq(excell.getApprovedStudentCount(), 0);
    }

    function test_StudentRegisters() public {
        string memory name = "Alice";
        
        vm.prank(student1);
        excell.register(name);
        
        assertTrue(excell.isStudent(student1));
        assertFalse(excell.isApprovedStudent(student1));
        assertEq(excell.getStudentCount(), 1);
        assertEq(excell.getApprovedStudentCount(), 0);
        
        Excell.StudentData memory student = excell.getStudent(student1);
        assertEq(student.studentAddress, student1);
        assertEq(student.name, name);
        assertTrue(student.isRegistered);
        assertFalse(student.isApproved);
        assertEq(student.approvalDate, 0);
        assertGt(student.registrationDate, 0);
    }

    function test_TutorApprovesRegistration() public {
        string memory name = "Alice";
        
        // Student registers
        vm.prank(student1);
        excell.register(name);
        
        // Tutor approves
        vm.prank(tutor1);
        excell.approve(student1);
        
        assertTrue(excell.isStudent(student1));
        assertTrue(excell.isApprovedStudent(student1));
        assertEq(excell.getApprovedStudentCount(), 1);
        
        Excell.StudentData memory student = excell.getStudent(student1);
        assertTrue(student.isApproved);
        assertGt(student.approvalDate, 0);
    }

    function test_RegisterMultipleStudents() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student2);
        excell.register("Bob");
        
        vm.prank(student3);
        excell.register("Charlie");
        
        assertEq(excell.getStudentCount(), 3);
        assertTrue(excell.isStudent(student1));
        assertTrue(excell.isStudent(student2));
        assertTrue(excell.isStudent(student3));
        assertEq(excell.getApprovedStudentCount(), 0);
    }

    function test_RegisterStudentTwice() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student1);
        vm.expectRevert("Excell: Student already registered");
        excell.register("Alice Again");
    }

    function test_RegisterStudentEmptyName() public {
        vm.prank(student1);
        vm.expectRevert("Excell: Name cannot be empty");
        excell.register("");
    }

    function test_ApproveRegistrationOnlyTutor() public {
        vm.prank(student1);
        excell.register("Alice");
        
        // Non-tutor tries to approve
        vm.prank(student2);
        vm.expectRevert("Excell: Only tutors can approve registration");
        excell.approve(student1);
    }

    function test_ApproveNotRegisteredStudent() public {
        vm.prank(tutor1);
        vm.expectRevert("Excell: Student not registered");
        excell.approve(student1);
    }

    function test_ApproveAlreadyApprovedStudent() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(tutor2);
        vm.expectRevert("Excell: Student already approved");
        excell.approve(student1);
    }

    function test_GetAllStudents() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student2);
        excell.register("Bob");
        
        Excell.StudentData[] memory allStudents = excell.getAllStudents();
        assertEq(allStudents.length, 2);
        assertEq(allStudents[0].studentAddress, student1);
        assertEq(allStudents[0].name, "Alice");
        assertEq(allStudents[1].studentAddress, student2);
        assertEq(allStudents[1].name, "Bob");
    }

    function test_GetApprovedStudents() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student2);
        excell.register("Bob");
        
        vm.prank(student3);
        excell.register("Charlie");
        
        // Approve only student1 and student3
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(tutor2);
        excell.approve(student3);
        
        Excell.StudentData[] memory approvedStudents = excell.getApprovedStudents();
        assertEq(approvedStudents.length, 2);
        assertEq(approvedStudents[0].studentAddress, student1);
        assertEq(approvedStudents[0].name, "Alice");
        assertTrue(approvedStudents[0].isApproved);
        assertEq(approvedStudents[1].studentAddress, student3);
        assertEq(approvedStudents[1].name, "Charlie");
        assertTrue(approvedStudents[1].isApproved);
        assertEq(excell.getApprovedStudentCount(), 2);
    }

    function test_GetStudent() public {
        string memory name = "Alice";
        
        vm.prank(student1);
        excell.register(name);
        
        Excell.StudentData memory student = excell.getStudent(student1);
        assertEq(student.studentAddress, student1);
        assertEq(student.name, name);
        assertTrue(student.isRegistered);
        assertFalse(student.isApproved);
    }

    function test_GetStudentNotRegistered() public {
        vm.expectRevert("Excell: Student not registered");
        excell.getStudent(student1);
    }

    function test_GetStudents() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student2);
        excell.register("Bob");
        
        address[] memory addresses = new address[](2);
        addresses[0] = student1;
        addresses[1] = student2;
        
        Excell.StudentData[] memory students = excell.getStudents(addresses);
        assertEq(students.length, 2);
        assertEq(students[0].name, "Alice");
        assertEq(students[1].name, "Bob");
    }

    function test_IsStudent() public {
        assertFalse(excell.isStudent(student1));
        
        vm.prank(student1);
        excell.register("Alice");
        
        assertTrue(excell.isStudent(student1));
    }

    function test_IsApprovedStudent() public {
        assertFalse(excell.isApprovedStudent(student1));
        
        vm.prank(student1);
        excell.register("Alice");
        
        assertFalse(excell.isApprovedStudent(student1));
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        assertTrue(excell.isApprovedStudent(student1));
    }

    function test_MultipleTutorsCanApprove() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student2);
        excell.register("Bob");
        
        // Tutor1 approves student1
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Tutor2 approves student2
        vm.prank(tutor2);
        excell.approve(student2);
        
        assertTrue(excell.isApprovedStudent(student1));
        assertTrue(excell.isApprovedStudent(student2));
        assertEq(excell.getApprovedStudentCount(), 2);
    }

    // Points Request Tests
    function test_RequestPoints() public {
        // Register and approve student first
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Student requests points
        uint256 amount = 100 * 10 ** 18;
        string memory description = "Completed assignment";
        
        vm.prank(student1);
        uint256 requestId = excell.requestPoints(amount, description);
        
        assertEq(requestId, 1);
        assertEq(excell.getPointsRequestCount(), 1);
        
        Excell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.requestId, requestId);
        assertEq(request.studentAddress, student1);
        assertEq(request.amount, amount);
        assertEq(request.description, description);
        assertEq(uint256(request.status), uint256(IExcell.RequestStatus.Pending));
        assertGt(request.requestDate, 0);
    }

    function test_RequestPointsOnlyApprovedStudent() public {
        // Student registers but not approved
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student1);
        vm.expectRevert("Excell: Only approved students can request points");
        excell.requestPoints(100 * 10 ** 18, "Test");
    }

    function test_RequestPointsZeroAmount() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(student1);
        vm.expectRevert("Excell: Amount must be greater than zero");
        excell.requestPoints(0, "Test");
    }

    function test_RequestPointsEmptyDescription() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(student1);
        vm.expectRevert("Excell: Description cannot be empty");
        excell.requestPoints(100 * 10 ** 18, "");
    }

    function test_TutorApprovesPointsRequest() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        uint256 amount = 100 * 10 ** 18;
        
        // Mint tokens to tutor so they can transfer them
        vm.prank(admin);
        ipt.mint(tutor1, amount);
        
        vm.prank(student1);
        uint256 requestId = excell.requestPoints(amount, "Completed assignment");
        
        uint256 studentBalanceBefore = ipt.balanceOf(student1);
        uint256 tutorBalanceBefore = ipt.balanceOf(tutor1);
        
        // Tutor approves token transfer to Excell contract
        vm.prank(tutor1);
        ipt.approve(address(excell), amount);
        
        // Tutor approves points request
        vm.prank(tutor1);
        excell.approvePointsRequest(requestId);
        
        Excell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(uint256(request.status), uint256(IExcell.RequestStatus.Approved));
        assertGt(request.approvalDate, 0);
        assertEq(request.approvedBy, tutor1);
        
        // Check tokens were transferred from tutor to student
        uint256 studentBalanceAfter = ipt.balanceOf(student1);
        uint256 tutorBalanceAfter = ipt.balanceOf(tutor1);
        assertEq(studentBalanceAfter - studentBalanceBefore, amount);
        assertEq(tutorBalanceBefore - tutorBalanceAfter, amount);
    }

    function test_ApprovePointsRequestOnlyTutor() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(student1);
        uint256 requestId = excell.requestPoints(100 * 10 ** 18, "Test");
        
        // Non-tutor tries to approve
        vm.prank(student2);
        vm.expectRevert("Excell: Only tutors can approve points requests");
        excell.approvePointsRequest(requestId);
    }

    function test_ApproveNonExistentRequest() public {
        vm.prank(tutor1);
        vm.expectRevert("Excell: Request does not exist");
        excell.approvePointsRequest(999);
    }

    function test_ApprovePointsRequestInsufficientBalance() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        uint256 amount = 100 * 10 ** 18;
        
        // Don't mint tokens to tutor - they won't have enough balance
        vm.prank(student1);
        uint256 requestId = excell.requestPoints(amount, "Test");
        
        // Tutor tries to approve but doesn't have enough tokens
        vm.prank(tutor1);
        vm.expectRevert("Excell: Insufficient tutor balance");
        excell.approvePointsRequest(requestId);
    }

    function test_ApprovePointsRequestInsufficientAllowance() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        uint256 amount = 100 * 10 ** 18;
        
        // Mint tokens to tutor
        vm.prank(admin);
        ipt.mint(tutor1, amount);
        
        vm.prank(student1);
        uint256 requestId = excell.requestPoints(amount, "Test");
        
        // Tutor doesn't approve token transfer - insufficient allowance
        vm.prank(tutor1);
        vm.expectRevert("Excell: Insufficient allowance");
        excell.approvePointsRequest(requestId);
    }

    function test_ApproveAlreadyApprovedRequest() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        uint256 amount = 100 * 10 ** 18;
        vm.prank(admin);
        ipt.mint(tutor1, amount);
        
        vm.prank(student1);
        uint256 requestId = excell.requestPoints(amount, "Test");
        
        // Tutor approves token transfer
        vm.prank(tutor1);
        ipt.approve(address(excell), amount);
        
        vm.prank(tutor1);
        excell.approvePointsRequest(requestId);
        
        vm.prank(tutor2);
        vm.expectRevert("Excell: Request already processed");
        excell.approvePointsRequest(requestId);
    }

    function test_GetStudentPointsRequests() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(student1);
        excell.requestPoints(100 * 10 ** 18, "Request 1");
        
        vm.prank(student1);
        excell.requestPoints(200 * 10 ** 18, "Request 2");
        
        Excell.PointsRequest[] memory requests = excell.getStudentPointsRequests(student1);
        assertEq(requests.length, 2);
        assertEq(requests[0].amount, 100 * 10 ** 18);
        assertEq(requests[1].amount, 200 * 10 ** 18);
    }

    function test_GetPendingPointsRequests() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(admin);
        ipt.mint(tutor1, 300 * 10 ** 18);
        
        vm.prank(student1);
        excell.requestPoints(100 * 10 ** 18, "Request 1");
        
        vm.prank(student1);
        excell.requestPoints(200 * 10 ** 18, "Request 2");
        
        // Approve one request
        vm.prank(tutor1);
        ipt.approve(address(excell), 100 * 10 ** 18);
        vm.prank(tutor1);
        excell.approvePointsRequest(1);
        
        (Excell.PointsRequest[] memory pending, uint256[] memory pendingIds) = excell.getPendingPointsRequests();
        assertEq(pending.length, 1);
        assertEq(pendingIds.length, 1);
        assertEq(pending[0].requestId, 2);
    }

    function test_GetApprovedPointsRequests() public {
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        vm.prank(admin);
        ipt.mint(tutor1, 100 * 10 ** 18);
        vm.prank(admin);
        ipt.mint(tutor2, 200 * 10 ** 18);
        
        vm.prank(student1);
        excell.requestPoints(100 * 10 ** 18, "Request 1");
        
        vm.prank(student1);
        excell.requestPoints(200 * 10 ** 18, "Request 2");
        
        // Approve both requests
        vm.prank(tutor1);
        ipt.approve(address(excell), 100 * 10 ** 18);
        vm.prank(tutor1);
        excell.approvePointsRequest(1);
        
        vm.prank(tutor2);
        ipt.approve(address(excell), 200 * 10 ** 18);
        vm.prank(tutor2);
        excell.approvePointsRequest(2);
        
        (Excell.PointsRequest[] memory approved, uint256[] memory requestIds) = excell.getApprovedPointsRequests();
        assertEq(approved.length, 2);
        assertEq(requestIds.length, 2);
    }

    // Lab Functions Tests
    function test_LabIntroduction() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Student completes lab_wallet_creation
        vm.prank(student1);
        uint256 requestId = excell.labWalletCreation();
        
        assertEq(requestId, 1);
        assertTrue(excell.hasCompletedLab(student1, "lab_wallet_creation"));
        
        Excell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.amount, excell.getLabReward("lab_wallet_creation"));
        assertEq(request.description, "Lab: wallet creation completed");
        assertEq(request.studentAddress, student1);
    }

    function test_LabErc20() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Student completes lab_erc20
        vm.prank(student1);
        uint256 requestId = excell.labErc20();
        
        assertEq(requestId, 1);
        assertTrue(excell.hasCompletedLab(student1, "lab_erc20"));
        
        Excell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.amount, excell.getLabReward("lab_erc20"));
        assertEq(request.description, "Lab: ERC20 completed");
    }

    function test_LabNft() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Student completes lab_nft
        vm.prank(student1);
        uint256 requestId = excell.labNft();
        
        assertEq(requestId, 1);
        assertTrue(excell.hasCompletedLab(student1, "lab_nft"));
        
        Excell.PointsRequest memory request = excell.getPointsRequest(requestId);
        assertEq(request.amount, excell.getLabReward("lab_nft"));
        assertEq(request.description, "Lab: NFT completed");
    }

    function test_CompleteAllLabs() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Complete all labs
        vm.prank(student1);
        excell.labWalletCreation();
        
        vm.prank(student1);
        excell.labErc20();
        
        vm.prank(student1);
        excell.labNft();
        
        assertTrue(excell.hasCompletedLab(student1, "lab_wallet_creation"));
        assertTrue(excell.hasCompletedLab(student1, "lab_erc20"));
        assertTrue(excell.hasCompletedLab(student1, "lab_nft"));
        
        assertEq(excell.getPointsRequestCount(), 3);
    }

    function test_LabOnlyApprovedStudent() public {
        // Student registers but not approved
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(student1);
        vm.expectRevert("Excell: Only approved students can complete labs");
        excell.labWalletCreation();
    }

    function test_LabCannotCompleteTwice() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        // Complete lab once
        vm.prank(student1);
        excell.labWalletCreation();
        
        // Try to complete again
        vm.prank(student1);
        vm.expectRevert("Excell: Lab already completed");
        excell.labWalletCreation();
    }

    function test_LabApprovalTransfersTokens() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
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
        excell.approvePointsRequest(requestId);
        
        uint256 studentBalanceAfter = ipt.balanceOf(student1);
        uint256 tutorBalanceAfter = ipt.balanceOf(tutor1);
        assertEq(studentBalanceAfter - studentBalanceBefore, labAward);
        assertEq(tutorBalanceBefore - tutorBalanceAfter, labAward);
    }

    function test_HasCompletedLab() public {
        // Setup
        vm.prank(student1);
        excell.register("Alice");
        
        vm.prank(tutor1);
        excell.approve(student1);
        
        assertFalse(excell.hasCompletedLab(student1, "lab_wallet_creation"));
        assertFalse(excell.hasCompletedLab(student1, "lab_erc20"));
        assertFalse(excell.hasCompletedLab(student1, "lab_nft"));
        
        vm.prank(student1);
        excell.labWalletCreation();
        
        assertTrue(excell.hasCompletedLab(student1, "lab_wallet_creation"));
        assertFalse(excell.hasCompletedLab(student1, "lab_erc20"));
        assertFalse(excell.hasCompletedLab(student1, "lab_nft"));
    }
}
