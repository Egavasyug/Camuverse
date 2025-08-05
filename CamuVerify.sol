
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CamuVerify
 * @notice Smart contract to manage identity verification and age validation for CammunityDAO.
 *         Supports phased admin evolution: DAO Multisig (Phase 1), Verifier Registry (Phase 2),
 *         and DID/ZKP support (Phase 3-ready).
 */
contract CamuVerify is Ownable {
    struct Member {
        uint16 birthYear;
        bool isVerified;
        bool isAdult;
    }

    mapping(address => Member) public members;
    mapping(address => bool) public verifiers; // Phase 2: Approved KYC providers

    event MemberVerified(address indexed user, uint16 birthYear, bool isAdult);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

    modifier onlyVerifier() {
        require(verifiers[msg.sender] || msg.sender == owner(), "Not authorized verifier");
        _;
    }

    constructor() {
        verifiers[msg.sender] = true; // Deployer is initial admin verifier
    }

    /// @notice DAO can add a verifier (Phase 2)
    function addVerifier(address _verifier) external onlyOwner {
        verifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /// @notice DAO can remove a verifier (Phase 2)
    function removeVerifier(address _verifier) external onlyOwner {
        verifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }

    /// @notice Verifier sets member's birth year and verification status
    function verifyMember(address _user, uint16 _birthYear) external onlyVerifier {
        require(_birthYear > 1900 && _birthYear <= 2100, "Invalid birth year");
        uint16 currentYear = uint16((block.timestamp / 365 days) + 1970);
        bool _isAdult = currentYear - _birthYear >= 18;
        members[_user] = Member(_birthYear, true, _isAdult);
        emit MemberVerified(_user, _birthYear, _isAdult);
    }

    /// @notice View function to get verification and adult flag
    function isVerified(address _user) external view returns (bool) {
        return members[_user].isVerified;
    }

    function isAdult(address _user) external view returns (bool) {
        return members[_user].isAdult;
    }

    /// @notice Phase 3 stub: interface for ZK / DID verification integration
    function verifyWithProof(bytes calldata /*proof*/) external pure returns (bool) {
        // Placeholder: will accept proofs from Polygon ID / Verite / other ZK systems
        return false;
    }
}
