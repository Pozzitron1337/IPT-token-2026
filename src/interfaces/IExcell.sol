// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IIPT} from "./IIPT.sol";

/// @title IExcell
/// @dev Interface for Excell student management contract
interface IExcell is IAccessControl {
    /// @dev Status of a points request
    enum RequestStatus {
        Pending,    // Request is pending approval
        Approved,   // Request has been approved
        Rejected    // Request has been rejected
    }

    /// @dev Structure to store student information
    struct StudentData {
        address studentAddress;
        string name;
        uint256 registrationDate;
        uint256 approvalDate;
        bool isRegistered;
        bool isApproved;
    }

    /// @dev Structure to store points request information
    struct PointsRequest {
        uint256 requestId;
        address studentAddress;
        uint256 amount;
        string description;
        uint256 requestDate;
        uint256 approvalDate;
        address approvedBy;
        RequestStatus status;
        bool exists;
    }

    /// @dev Returns the IPT token contract address
    /// @return Address of the IPT token contract
    function iptToken() external view returns (IIPT);

    /// @dev Student submits registration request
    /// @param name Name of the student
    function register(string memory name) external;

    /// @dev Tutor approves student registration (only for tutors from IPT token)
    /// @param studentAddress Address of the student to approve
    function approve(address studentAddress) external;

    /// @dev Gets the total number of registered students
    /// @return The number of registered students
    function getStudentCount() external view returns (uint256);

    /// @dev Gets all registered students
    /// @return Array of all StudentData structs
    function getAllStudents() external view returns (StudentData[] memory);

    /// @dev Gets all approved students
    /// @return Array of approved StudentData structs
    function getApprovedStudents() external view returns (StudentData[] memory);

    /// @dev Gets the count of approved students
    /// @return The number of approved students
    function getApprovedStudentCount() external view returns (uint256);

    /// @dev Gets student information by address
    /// @param studentAddress Address of the student
    /// @return StudentData struct with all information
    function getStudent(address studentAddress) external view returns (StudentData memory);

    /// @dev Gets multiple students' information by their addresses
    /// @param addresses Array of student addresses
    /// @return Array of StudentData structs
    function getStudents(address[] memory addresses) external view returns (StudentData[] memory);

    /// @dev Checks if an address is a registered student
    /// @param studentAddress Address to check
    /// @return true if the address is registered as a student
    function isStudent(address studentAddress) external view returns (bool);

    /// @dev Checks if an address is an approved student
    /// @param studentAddress Address to check
    /// @return true if the address is an approved student
    function isApprovedStudent(address studentAddress) external view returns (bool);

    /// @dev Student requests points
    /// @param amount Amount of points requested
    /// @param description Description of the request
    /// @return requestId The ID of the created request
    function requestPoints(uint256 amount, string memory description) external returns (uint256);

    /// @dev Tutor approves points request (only for tutors from IPT token)
    /// @param requestId ID of the request to approve
    function approvePointsRequest(uint256 requestId) external;

    /// @dev Gets points request by ID
    /// @param requestId ID of the request
    /// @return PointsRequest struct with all information
    function getPointsRequest(uint256 requestId) external view returns (PointsRequest memory);

    /// @dev Gets all points requests for a student
    /// @param studentAddress Address of the student
    /// @return Array of PointsRequest structs
    function getStudentPointsRequests(address studentAddress) external view returns (PointsRequest[] memory);

    /// @dev Gets all pending points requests
    /// @return Array of PointsRequest structs
    function getPendingPointsRequests() external view returns (PointsRequest[] memory);

    /// @dev Gets all approved points requests
    /// @return Array of PointsRequest structs
    function getApprovedPointsRequests() external view returns (PointsRequest[] memory);

    /// @dev Gets all rejected points requests
    /// @return Array of PointsRequest structs
    function getRejectedPointsRequests() external view returns (PointsRequest[] memory);

    /// @dev Tutor rejects points request (only for tutors from IPT token)
    /// @param requestId ID of the request to reject
    function rejectPointsRequest(uint256 requestId) external;

    /// @dev Gets the total number of points requests
    /// @return The number of points requests
    function getPointsRequestCount() external view returns (uint256);

    /// @dev Student completes lab_introduction and requests points
    /// @return requestId The ID of the created request
    function labIntroduction() external returns (uint256);

    /// @dev Student completes lab_erc20 and requests points
    /// @return requestId The ID of the created request
    function labErc20() external returns (uint256);

    /// @dev Student completes lab_nft and requests points
    /// @return requestId The ID of the created request
    function labNft() external returns (uint256);

    /// @dev Checks if a student has completed a specific lab
    /// @param studentAddress Address of the student
    /// @param labName Name of the lab
    /// @return true if the student has completed the lab
    function hasCompletedLab(address studentAddress, string memory labName) external view returns (bool);

    /// @dev Gets IPT tokens awarded for a specific lab
    /// @param labName Name of the lab
    /// @return IPT tokens awarded for completing the lab (0 if lab doesn't exist)
    function getLabAward(string memory labName) external view returns (uint256);

    /// @dev Sets IPT tokens for a lab (only admin)
    /// @param labName Name of the lab
    /// @param iptTokens IPT tokens to award for completing the lab
    function setLabAward(string memory labName, uint256 iptTokens) external;
}
