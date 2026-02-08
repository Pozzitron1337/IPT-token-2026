// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IIPT} from "./IIPT.sol";

/// @title IExcell
/// @dev Interface for Excell contract managing labs and points requests
interface IExcell {
    /// @dev Status of a points request
    enum RequestStatus {
        Pending,
        Approved,
        Rejected
    }

    /// @dev Structure containing all information about a points request
    struct PointsRequest {
        uint256 requestId;
        address studentAddress;
        uint256 amount;
        string description;
        string labName;
        uint256 requestDate;
        uint256 approvalDate;
        address approvedBy;
        RequestStatus status;
        bool exists;
    }

    /// @dev Reference to IPT token contract
    function iptToken() external view returns (IIPT);

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

    /// @dev Tutor approves points request (only for tutors from IPT token)
    /// @param requestId ID of the request to approve
    function fulfillPointsRequest(uint256 requestId) external;

    /// @dev Tutor batch-approves points requests (only for tutors from IPT token)
    /// @param requestIds Array of request IDs to approve
    function batchFulfillPointsRequest(uint256[] calldata requestIds) external;

    /// @dev Tutor rejects points request (only for tutors from IPT token)
    /// @param requestId ID of the request to reject
    function rejectPointsRequest(uint256 requestId) external;

    /// @dev Tutor can batch reject multiple points requests (only for tutors from IPT token)
    /// @param requestIds Array of request IDs to reject
    function batchRejectPointsRequest(uint256[] calldata requestIds) external;

    /// @dev Gets points request by ID
    /// @param requestId ID of the request
    /// @return PointsRequest struct with all information
    function getPointsRequest(uint256 requestId) external view returns (PointsRequest memory);

    /// @dev Gets all points requests for a student
    /// @param studentAddress Address of the student
    /// @return Array of PointsRequest structs
    function getStudentPointsRequests(address studentAddress) external view returns (PointsRequest[] memory);

    /// @dev Gets all pending points requests for a specific student
    /// @param studentAddress Address of the student
    /// @return Array of PointsRequest structs, Array of corresponding request IDs
    function getStudentPendingPointsRequests(address studentAddress)
        external
        view
        returns (PointsRequest[] memory, uint256[] memory);

    /// @dev Gets points awarded for a lab for a student (0 if lab not completed)
    /// @param studentAddress Address of the student
    /// @param labName Name of the lab
    /// @return points Amount of IPT tokens awarded for the lab (0 if student hasn't completed)
    function getStudentLabStatus(address studentAddress, string calldata labName) external view returns (uint256);

    /// @dev Gets IPT tokens awarded for a specific lab
    /// @param labName Name of the lab
    /// @return IPT tokens awarded for completing the lab
    function getLabReward(string calldata labName) external view returns (uint256);

    /// @dev Sets IPT tokens for a lab (only tutors from IPT token)
    /// @param labName Name of the lab
    /// @param iptTokens IPT tokens to award for completing the lab
    function setLabReward(string calldata labName, uint256 iptTokens) external;

    /// @dev Student completes lab_wallet_creation and requests points
    /// @return requestId The ID of the created request
    function labWalletCreation() external returns (uint256);

    /// @dev Student completes lab_smart_contract and requests points
    /// @return requestId The ID of the created request
    function labSmartContract() external returns (uint256);

    /// @dev Student completes lab_erc20 and requests points
    /// @return requestId The ID of the created request
    function labErc20() external returns (uint256);

    /// @dev Student completes lab_nft and requests points
    /// @return requestId The ID of the created request
    function labNft() external returns (uint256);
}
