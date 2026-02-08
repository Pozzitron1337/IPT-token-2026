// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IIPT} from "./interfaces/IIPT.sol";
import {IExcell} from "./interfaces/IExcell.sol";

/// @title Excell
/// @dev Contract for managing labs and points requests
contract Excell is IExcell {
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
    mapping(string => uint256) public iptTokensReward;

    /// @dev Constructor that sets up the contract
    /// @param iptTokenAddress Address of the IPT token contract
    constructor(address iptTokenAddress) {
        require(iptTokenAddress != address(0));
        iptToken = IIPT(iptTokenAddress);
        
        uint8 iptTokenDecimals = iptToken.decimals();
        /// TODO initial distribution
        iptTokensReward["lab_wallet_creation"] = 10 * 10 ** iptTokenDecimals;
        iptTokensReward["lab_smart_contract"] = 20 * 10 ** iptTokenDecimals; 
        iptTokensReward["lab_erc20"] = 30 * 10 ** iptTokenDecimals;
        iptTokensReward["lab_nft"] = 40 * 10 ** iptTokenDecimals;
    }

    /// @dev Internal: creates points request with optional lab name
    function _requestPoints(uint256 amount, string memory description, string memory labName) internal returns (uint256) {
        address studentAddress = msg.sender;
        require(amount > 0, "Excell: Amount must be greater than zero");
        require(bytes(description).length > 0, "Excell: Description cannot be empty");

        _pointsRequestCounter++;
        uint256 requestId = _pointsRequestCounter;

        pointsRequests[requestId] = PointsRequest({
            requestId: requestId,
            studentAddress: studentAddress,
            amount: amount,
            description: description,
            labName: labName,
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
    function fulfillPointsRequest(uint256 requestId) public {
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

        require(iptToken.transferFrom(msg.sender, request.studentAddress, request.amount), "Excell: Transfer failed");

        emit PointsRequestApproved(
            requestId,
            request.studentAddress,
            msg.sender,
            request.amount,
            block.timestamp
        );
    }

    /// @dev Tutor batch-approves points requests (only for tutors from IPT token)
    /// @param requestIds Array of request IDs to approve
    function batchFulfillPointsRequest(uint256[] calldata requestIds) public {
        for (uint256 i = 0; i < requestIds.length; i++) {
            fulfillPointsRequest(requestIds[i]);
        }
    }

    /// @dev Tutor rejects points request (only for tutors from IPT token)
    /// @param requestId ID of the request to reject
    function rejectPointsRequest(uint256 requestId) public {
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

        if (bytes(request.labName).length > 0) {
            completedLabs[request.studentAddress][request.labName] = false;
        }

        emit PointsRequestRejected(
            requestId,
            request.studentAddress,
            msg.sender,
            block.timestamp
        );
    }

    /// @dev Tutor can batch reject multiple points requests (only for tutors from IPT token)
    /// @param requestIds Array of request IDs to reject
    function batchRejectPointsRequest(uint256[] calldata requestIds) external {
        for (uint256 i = 0; i < requestIds.length; i++) {
            rejectPointsRequest(requestIds[i]);
        }
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

    /// @dev Gets all pending points requests for a specific student
    /// @param studentAddress Address of the student
    /// @return Array of PointsRequest structs, Array of corresponding request IDs
    function getStudentPendingPointsRequests(address studentAddress) external view returns (PointsRequest[] memory, uint256[] memory) {
        uint256[] memory requestIds = studentRequestIds[studentAddress];
        uint256 pendingCount = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            if (pointsRequests[requestIds[i]].status == IExcell.RequestStatus.Pending) {
                pendingCount++;
            }
        }

        PointsRequest[] memory pending = new PointsRequest[](pendingCount);
        uint256[] memory pendingIds = new uint256[](pendingCount);
        uint256 index = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 reqId = requestIds[i];
            if (pointsRequests[reqId].status == IExcell.RequestStatus.Pending) {
                pending[index] = pointsRequests[reqId];
                pendingIds[index] = reqId;
                index++;
            }
        }

        return (pending, pendingIds);
    }

    /// @dev Gets points awarded for a lab for a student (0 if lab not completed)
    /// @param studentAddress Address of the student
    /// @param labName Name of the lab
    /// @return points Amount of IPT tokens awarded for the lab (0 if student hasn't completed)
    function getStudentLabStatus(address studentAddress, string memory labName) external view returns (uint256) {
        if (!completedLabs[studentAddress][labName]) {
            return 0;
        }
        return iptTokensReward[labName];
    }

    /// @dev Gets IPT tokens awarded for a specific lab (IExcell alias)
    function getLabReward(string memory labName) external view returns (uint256) {
        return iptTokensReward[labName];
    }

    /// @dev Sets IPT tokens for a lab (only tutors from IPT token)
    /// @param labName Name of the lab
    /// @param iptTokens IPT tokens to award for completing the lab
    function setLabReward(string memory labName, uint256 iptTokens) external {
        require(iptToken.isTutor(msg.sender), "Excell: Only tutors can set lab reward");
        require(bytes(labName).length > 0, "Excell: Lab name cannot be empty");
        iptTokensReward[labName] = iptTokens;
    }

    /// @dev Internal function to complete a lab and request points
    /// @param labName Name of the lab
    /// @param description Description for the points request
    /// @return requestId The ID of the created request
    function _completeLab(string memory labName, string memory description) internal returns (uint256) {
        address studentAddress = msg.sender;
        require(!completedLabs[studentAddress][labName], "Excell: Lab already completed");
        
        uint256 iptTokens = iptTokensReward[labName];
        require(iptTokens > 0, "Excell: Lab not found or has no IPT tokens assigned");

        completedLabs[studentAddress][labName] = true;
        uint256 requestId = _requestPoints(iptTokens, description, labName);

        emit LabCompleted(studentAddress, labName, requestId, iptTokens);

        return requestId;
    }

    /// STUDENT FUNCTIONS SPACE ///

    /// @dev Student completes lab_wallet_creation and requests points
    /// @return requestId The ID of the created request
    function labWalletCreation() external returns (uint256) {
        return _completeLab("lab_wallet_creation", "Lab: wallet creation completed");
    }

    /// @dev Student completes lab_smart_contract and requests points
    /// @return requestId The ID of the created request
    function labSmartContract() external returns (uint256) {
        return _completeLab("lab_smart_contract", "Lab: smart contract completed");
    }

    /// @dev Student completes lab_erc20 and requests points
    /// @return requestId The ID of the created request
    function labErc20() external returns (uint256) {
        return _completeLab("lab_erc20", "Lab: ERC20 completed");
    }

    /// @dev Student completes lab_nft and requests points
    /// @return requestId The ID of the created request
    function labNft() external returns (uint256) {
        return _completeLab("lab_nft", "Lab: NFT completed");
    }

}
