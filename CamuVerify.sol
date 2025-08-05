// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CamuVerify is Ownable {
    struct Member {
        address memberAddress;
        uint256 birthYear;
        bool verified;
    }

    mapping(address => Member) public members;
    uint256 public verifiedCount;

    address public daoAddress;

    event MemberVerified(address member, uint256 birthYear);
    event MemberRevoked(address member);
    event DAOAddressUpdated(address daoAddress);

    constructor(address initialOwner) Ownable(initialOwner) {}

    modifier onlyDAOOrOwner() {
        require(msg.sender == daoAddress || msg.sender == owner(), "Not authorized");
        _;
    }

    function setDAO(address _daoAddress) external onlyOwner {
        require(_daoAddress != address(0), "Invalid DAO address");
        daoAddress = _daoAddress;
        emit DAOAddressUpdated(_daoAddress);
    }

    function getCurrentYear() internal view returns (uint256) {
        return 1970 + (block.timestamp / 31556926);
    }

    function verifyMember(address _member, uint256 _birthYear) external onlyDAOOrOwner {
        require(_birthYear < getCurrentYear(), "Invalid birth year");
        require(!members[_member].verified, "Already verified");

        members[_member] = Member(_member, _birthYear, true);
        verifiedCount++;
        emit MemberVerified(_member, _birthYear);
    }

    function revokeMember(address _member) external onlyDAOOrOwner {
        require(members[_member].verified, "Not verified");

        members[_member].verified = false;
        verifiedCount--;
        emit MemberRevoked(_member);
    }

    function isVerified(address _member) external view returns (bool) {
        return members[_member].verified;
    }
}


    function isAdult(address _member) external view returns (bool) {
        if (!members[_member].verified) return false;
        return (getCurrentYear() - members[_member].birthYear) >= 18;
    }
}
