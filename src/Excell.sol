// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IIPT} from "./interfaces/IIPT.sol";
import {IExcell} from "./interfaces/IExcell.sol";

/// @title Excell
/// @dev Contract for managing student registration and records
contract Excell is AccessControl, IExcell {
    /// @dev Mapping from student address to student information
    mapping(address => StudentData) public students;

    /// @dev Array of all registered students
    StudentData[] public studentsArray;

    /// @dev Mapping from student address to index in studentsArray
    mapping(address => uint256) public studentIndex;

    /// @dev Reference to IPT token contract
    IIPT public iptToken;

    /// @dev Counter for points request IDs
    uint256 private _pointsRequestCounter;

    /// @dev Mapping from request ID to points request
    mapping(uint256 => PointsRequest) public pointsRequests;

    /// @dev Mapping from student address to array of request IDs
    mapping(address => uint256[]) public studentRequestIds;

    /// @dev Array of all request IDs
    uint256[] public allRequestIds;

    /// @dev Mapping from student address to completed labs
    mapping(address => mapping(string => bool)) public completedLabs;

    /// @dev Mapping from lab name to IPT tokens awarded
    mapping(string => uint256) public iptTokensAward;

    /// @dev Event emitted when a student submits registration request
    event RegistrationRequested(address indexed student, string name, uint256 registrationDate);

    /// @dev Event emitted when a student registration is approved
    event RegistrationApproved(address indexed student, address indexed tutor, uint256 approvalDate);

    /// @dev Event emitted when a student requests points
    event PointsRequested(
        uint256 indexed requestId,
        address indexed student,
        uint256 amount,
        string description,
        uint256 requestDate
    );

    /// @dev Event emitted when a points request is approved
    event PointsRequestApproved(
        uint256 indexed requestId,
        address indexed student,
        address indexed tutor,
        uint256 amount,
        uint256 approvalDate
    );

    /// @dev Event emitted when a points request is rejected
    event PointsRequestRejected(
        uint256 indexed requestId,
        address indexed student,
        address indexed tutor,
        uint256 rejectionDate
    );

    /// @dev Event emitted when a student completes a lab
    event LabCompleted(address indexed student, string labName, uint256 requestId, uint256 points);

    /// @dev Constructor that sets up the contract
    /// @param iptTokenAddress Address of the IPT token contract
    constructor(address iptTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        iptToken = IIPT(iptTokenAddress);
        
        uint8 iptTokenDecimals = iptToken.decimals();
        // Initialize lab IPT tokens mapping
        iptTokensAward["lab_introduction"] = 20 * 10 ** iptTokenDecimals; 
        iptTokensAward["lab_erc20"] = 40 * 10 ** iptTokenDecimals;
        iptTokensAward["lab_nft"] = 40 * 10 ** iptTokenDecimals;
    }

    /// @dev Student submits registration request
    /// @param name Name of the student
    function register(string memory name) external {
        address studentAddress = msg.sender;
        require(!students[studentAddress].isRegistered, "Excell: Student already registered");
        require(studentAddress != address(0), "Excell: Invalid student address");
        require(bytes(name).length > 0, "Excell: Name cannot be empty");

        StudentData memory newStudent = StudentData({
            studentAddress: studentAddress,
            name: name,
            registrationDate: block.timestamp,
            approvalDate: 0,
            isRegistered: true,
            isApproved: false
        });

        students[studentAddress] = newStudent;
        studentIndex[studentAddress] = studentsArray.length;
        studentsArray.push(newStudent);

        emit RegistrationRequested(studentAddress, name, block.timestamp);
    }

    /// @dev Tutor approves student registration (only for tutors from IPT token)
    /// @param studentAddress Address of the student to approve
    function approve(address studentAddress) external {
        require(iptToken.isTutor(msg.sender), "Excell: Only tutors can approve registration");
        require(students[studentAddress].isRegistered, "Excell: Student not registered");
        require(!students[studentAddress].isApproved, "Excell: Student already approved");

        students[studentAddress].isApproved = true;
        students[studentAddress].approvalDate = block.timestamp;

        // Update student in array
        uint256 index = studentIndex[studentAddress];
        studentsArray[index].isApproved = true;
        studentsArray[index].approvalDate = block.timestamp;

        emit RegistrationApproved(studentAddress, msg.sender, block.timestamp);
    }

    /// @dev Gets the total number of registered students
    /// @return The number of registered students
    function getStudentCount() external view returns (uint256) {
        return studentsArray.length;
    }

    /// @dev Gets all registered students
    /// @return Array of all StudentData structs
    function getAllStudents() external view returns (StudentData[] memory) {
        return studentsArray;
    }

    /// @dev Gets all approved students
    /// @return Array of approved StudentData structs
    function getApprovedStudents() external view returns (StudentData[] memory) {
        StudentData[] memory approved = new StudentData[](studentsArray.length);
        uint256 count = 0;
        for (uint256 i = 0; i < studentsArray.length; i++) {
            if (studentsArray[i].isApproved) {
                approved[count] = studentsArray[i];
                count++;
            }
        }
        // Resize array to actual count
        StudentData[] memory result = new StudentData[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = approved[i];
        }
        return result;
    }

    /// @dev Gets student information by address
    /// @param studentAddress Address of the student
    /// @return StudentData struct with all information
    function getStudent(address studentAddress) external view returns (StudentData memory) {
        require(students[studentAddress].isRegistered, "Excell: Student not registered");
        return students[studentAddress];
    }

    /// @dev Gets multiple students' information by their addresses
    /// @param addresses Array of student addresses
    /// @return Array of StudentData structs
    function getStudents(address[] memory addresses) external view returns (StudentData[] memory) {
        StudentData[] memory result = new StudentData[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            if (students[addresses[i]].isRegistered) {
                result[i] = students[addresses[i]];
            }
        }
        return result;
    }

    /// @dev Gets the count of approved students
    /// @return The number of approved students
    function getApprovedStudentCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < studentsArray.length; i++) {
            if (studentsArray[i].isApproved) {
                count++;
            }
        }
        return count;
    }

    /// @dev Checks if an address is a registered student
    /// @param studentAddress Address to check
    /// @return true if the address is registered as a student
    function isStudent(address studentAddress) external view returns (bool) {
        return students[studentAddress].isRegistered;
    }

    /// @dev Checks if an address is an approved student
    /// @param studentAddress Address to check
    /// @return true if the address is an approved student
    function isApprovedStudent(address studentAddress) external view returns (bool) {
        return students[studentAddress].isApproved;
    }

    /// @dev Student requests points
    /// @param amount Amount of points requested
    /// @param description Description of the request
    /// @return requestId The ID of the created request
    function requestPoints(uint256 amount, string memory description) public returns (uint256) {
        address studentAddress = msg.sender;
        require(students[studentAddress].isApproved, "Excell: Only approved students can request points");
        require(amount > 0, "Excell: Amount must be greater than zero");
        require(bytes(description).length > 0, "Excell: Description cannot be empty");

        _pointsRequestCounter++;
        uint256 requestId = _pointsRequestCounter;

        pointsRequests[requestId] = PointsRequest({
            requestId: requestId,
            studentAddress: studentAddress,
            amount: amount,
            description: description,
            requestDate: block.timestamp,
            approvalDate: 0,
            approvedBy: address(0),
            status: IExcell.RequestStatus.Pending,
            exists: true
        });

        studentRequestIds[studentAddress].push(requestId);
        allRequestIds.push(requestId);

        emit PointsRequested(requestId, studentAddress, amount, description, block.timestamp);

        return requestId;
    }

    /// @dev Tutor approves points request (only for tutors from IPT token)
    /// @param requestId ID of the request to approve
    function approvePointsRequest(uint256 requestId) external {
        require(iptToken.isTutor(msg.sender), "Excell: Only tutors can approve points requests");
        require(pointsRequests[requestId].exists, "Excell: Request does not exist");
        require(
            pointsRequests[requestId].status == IExcell.RequestStatus.Pending,
            "Excell: Request already processed"
        );

        PointsRequest storage request = pointsRequests[requestId];
        require(iptToken.balanceOf(msg.sender) >= request.amount, "Excell: Insufficient tutor balance");
        require(iptToken.allowance(msg.sender, address(this)) >= request.amount, "Excell: Insufficient allowance");

        request.status = IExcell.RequestStatus.Approved;
        request.approvalDate = block.timestamp;
        request.approvedBy = msg.sender;

        // Transfer tokens from tutor to student using transferFrom
        require(iptToken.transferFrom(msg.sender, request.studentAddress, request.amount), "Excell: Transfer failed");

        emit PointsRequestApproved(
            requestId,
            request.studentAddress,
            msg.sender,
            request.amount,
            block.timestamp
        );
    }

    /// @dev Tutor rejects points request (only for tutors from IPT token)
    /// @param requestId ID of the request to reject
    function rejectPointsRequest(uint256 requestId) external {
        require(iptToken.isTutor(msg.sender), "Excell: Only tutors can reject points requests");
        require(pointsRequests[requestId].exists, "Excell: Request does not exist");
        require(
            pointsRequests[requestId].status == IExcell.RequestStatus.Pending,
            "Excell: Request already processed"
        );

        PointsRequest storage request = pointsRequests[requestId];

        request.status = IExcell.RequestStatus.Rejected;
        request.approvalDate = block.timestamp;
        request.approvedBy = msg.sender;

        emit PointsRequestRejected(
            requestId,
            request.studentAddress,
            msg.sender,
            block.timestamp
        );
    }

    /// @dev Gets points request by ID
    /// @param requestId ID of the request
    /// @return PointsRequest struct with all information
    function getPointsRequest(uint256 requestId) external view returns (PointsRequest memory) {
        require(pointsRequests[requestId].exists, "Excell: Request does not exist");
        return pointsRequests[requestId];
    }

    /// @dev Gets all points requests for a student
    /// @param studentAddress Address of the student
    /// @return Array of PointsRequest structs
    function getStudentPointsRequests(address studentAddress) external view returns (PointsRequest[] memory) {
        uint256[] memory requestIds = studentRequestIds[studentAddress];
        PointsRequest[] memory requests = new PointsRequest[](requestIds.length);
        
        for (uint256 i = 0; i < requestIds.length; i++) {
            requests[i] = pointsRequests[requestIds[i]];
        }
        
        return requests;
    }

    /// @dev Gets all pending points requests
    /// @return Array of PointsRequest structs
    function getPendingPointsRequests() external view returns (PointsRequest[] memory) {
        uint256 pendingCount = 0;
        
        // Count pending requests
        for (uint256 i = 0; i < allRequestIds.length; i++) {
            if (pointsRequests[allRequestIds[i]].status == IExcell.RequestStatus.Pending) {
                pendingCount++;
            }
        }
        
        // Create array with exact size
        PointsRequest[] memory pending = new PointsRequest[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allRequestIds.length; i++) {
            if (pointsRequests[allRequestIds[i]].status == IExcell.RequestStatus.Pending) {
                pending[index] = pointsRequests[allRequestIds[i]];
                index++;
            }
        }
        
        return pending;
    }

    /// @dev Gets all approved points requests
    /// @return Array of PointsRequest structs
    function getApprovedPointsRequests() external view returns (PointsRequest[] memory) {
        uint256 approvedCount = 0;
        
        // Count approved requests
        for (uint256 i = 0; i < allRequestIds.length; i++) {
            if (pointsRequests[allRequestIds[i]].status == IExcell.RequestStatus.Approved) {
                approvedCount++;
            }
        }
        
        // Create array with exact size
        PointsRequest[] memory approved = new PointsRequest[](approvedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allRequestIds.length; i++) {
            if (pointsRequests[allRequestIds[i]].status == IExcell.RequestStatus.Approved) {
                approved[index] = pointsRequests[allRequestIds[i]];
                index++;
            }
        }
        
        return approved;
    }

    /// @dev Gets all rejected points requests
    /// @return Array of PointsRequest structs
    function getRejectedPointsRequests() external view returns (PointsRequest[] memory) {
        uint256 rejectedCount = 0;
        
        // Count rejected requests
        for (uint256 i = 0; i < allRequestIds.length; i++) {
            if (pointsRequests[allRequestIds[i]].status == IExcell.RequestStatus.Rejected) {
                rejectedCount++;
            }
        }
        
        // Create array with exact size
        PointsRequest[] memory rejected = new PointsRequest[](rejectedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allRequestIds.length; i++) {
            if (pointsRequests[allRequestIds[i]].status == IExcell.RequestStatus.Rejected) {
                rejected[index] = pointsRequests[allRequestIds[i]];
                index++;
            }
        }
        
        return rejected;
    }

    /// @dev Gets the total number of points requests
    /// @return The number of points requests
    function getPointsRequestCount() external view returns (uint256) {
        return allRequestIds.length;
    }

    /// @dev Checks if a student has completed a specific lab
    /// @param studentAddress Address of the student
    /// @param labName Name of the lab
    /// @return true if the student has completed the lab
    function hasCompletedLab(address studentAddress, string memory labName) external view returns (bool) {
        return completedLabs[studentAddress][labName];
    }

    /// @dev Gets IPT tokens awarded for a specific lab
    /// @param labName Name of the lab
    /// @return IPT tokens awarded for completing the lab (0 if lab doesn't exist)
    function getLabAward(string memory labName) external view returns (uint256) {
        return iptTokensAward[labName];
    }

    /// @dev Sets IPT tokens for a lab (only admin)
    /// @param labName Name of the lab
    /// @param iptTokens IPT tokens to award for completing the lab
    function setLabAward(string memory labName, uint256 iptTokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(labName).length > 0, "Excell: Lab name cannot be empty");
        iptTokensAward[labName] = iptTokens;
    }

    /// @dev Internal function to complete a lab and request points
    /// @param labName Name of the lab
    /// @param description Description for the points request
    /// @return requestId The ID of the created request
    function completeLab(string memory labName, string memory description) public returns (uint256) {
        address studentAddress = msg.sender;
        require(students[studentAddress].isApproved, "Excell: Only approved students can complete labs");
        require(!completedLabs[studentAddress][labName], "Excell: Lab already completed");
        
        uint256 iptTokens = iptTokensAward[labName];
        require(iptTokens > 0, "Excell: Lab not found or has no IPT tokens assigned");

        completedLabs[studentAddress][labName] = true;
        uint256 requestId = requestPoints(iptTokens, description);

        emit LabCompleted(studentAddress, labName, requestId, iptTokens);

        return requestId;
    }

    /// @dev Student completes lab_introduction and requests points
    /// @return requestId The ID of the created request
    function labIntroduction() external returns (uint256) {
        return completeLab("lab_introduction", "Lab: Introduction completed");
    }

    /// @dev Student completes lab_erc20 and requests points
    /// @return requestId The ID of the created request
    function labErc20() external returns (uint256) {
        return completeLab("lab_erc20", "Lab: ERC20 completed");
    }

    /// @dev Student completes lab_nft and requests points
    /// @return requestId The ID of the created request
    function labNft() external returns (uint256) {
        return completeLab("lab_nft", "Lab: NFT completed");
    }

}
