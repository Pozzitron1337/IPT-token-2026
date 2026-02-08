// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IIPT} from "./interfaces/IIPT.sol";

contract IPT is ERC20, AccessControl, IIPT {
    bytes32 public constant TUTOR_ROLE = keccak256("TUTOR_ROLE");

    mapping(address => bool) private _frozen;

    event Frozen(address indexed account);
    event Unfrozen(address indexed account);

    constructor() ERC20("Institute of Physics and Technology. Introduction to Blockchain course points 2026", "IPT-2026") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TUTOR_ROLE, msg.sender);
        uint256 initialSupply = 10_000 * 10 ** decimals();
        _mint(msg.sender, initialSupply);
    }

    /// @dev Mints new tokens (only for addresses with TUTOR_ROLE)
    /// @param to Address of the token recipient
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) public onlyRole(TUTOR_ROLE) {
        require(to != address(0));
        _mint(to, amount);
    }

    /// @dev Freezes an account - frozen addresses cannot transfer or receive tokens
    /// @param account Address to freeze
    function freeze(address account) public onlyRole(TUTOR_ROLE) {
        require(account != address(0), "IPT: Zero address");
        require(!_frozen[account], "IPT: Already frozen");
        _frozen[account] = true;
        emit Frozen(account);
    }

    /// @dev Unfreezes an account
    /// @param account Address to unfreeze
    function unfreeze(address account) public onlyRole(TUTOR_ROLE) {
        require(account != address(0), "IPT: Zero address");
        require(_frozen[account], "IPT: Not frozen");
        _frozen[account] = false;
        emit Unfrozen(account);
    }

    /// @dev Checks if an account is frozen
    function isFrozen(address account) public view returns (bool) {
        return _frozen[account];
    }

    /// @inheritdoc ERC20
    function _update(address from, address to, uint256 value) internal virtual override {
        require(from == address(0) || !_frozen[from], "IPT: Sender frozen");
        require(to == address(0) || !_frozen[to], "IPT: Receiver frozen");
        super._update(from, to, value);
    }

    /// @dev Burns tokens
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /// @dev Grants tutor role to a new address (only for administrator)
    /// @param tutor Address to be granted the tutor role
    function grantTutorRole(address tutor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tutor != address(0));
        _grantRole(TUTOR_ROLE, tutor);
    }

    /// @dev Revokes tutor role from an address (only for administrator)
    /// @param tutor Address from which the tutor role will be revoked
    function revokeTutorRole(address tutor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tutor != address(0));
        _revokeRole(TUTOR_ROLE, tutor);
    }

    /// @dev Checks if an address has the tutor role
    /// @param account Address to check
    /// @return true if the address has TUTOR_ROLE, false otherwise
    function isTutor(address account) public view returns (bool) {
        return hasRole(TUTOR_ROLE, account);
    }
}
