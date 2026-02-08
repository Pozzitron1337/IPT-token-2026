// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title IIPT
/// @dev Interface for IPT token contract
interface IIPT is IERC20, IERC20Metadata, IAccessControl {

    /// @dev Returns the TUTOR_ROLE constant
    /// @return The bytes32 value of TUTOR_ROLE
    function TUTOR_ROLE() external view returns (bytes32);

    /// @dev Mints new tokens (only for addresses with TUTOR_ROLE)
    /// @param to Address of the token recipient
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @dev Burns tokens
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external;

    /// @dev Freezes an account - frozen addresses cannot transfer or receive tokens
    /// @param account Address to freeze
    function freeze(address account) external;

    /// @dev Unfreezes an account
    /// @param account Address to unfreeze
    function unfreeze(address account) external;

    /// @dev Checks if an account is frozen
    /// @param account Address to check
    /// @return true if the account is frozen
    function isFrozen(address account) external view returns (bool);

    /// @dev Grants tutor role to a new address (only for administrator)
    /// @param tutor Address to be granted the tutor role
    function grantTutorRole(address tutor) external;

    /// @dev Revokes tutor role from an address (only for administrator)
    /// @param tutor Address from which the tutor role will be revoked
    function revokeTutorRole(address tutor) external;

    /// @dev Checks if an address has the tutor role
    /// @param account Address to check
    /// @return true if the address has TUTOR_ROLE, false otherwise
    function isTutor(address account) external view returns (bool);
}
