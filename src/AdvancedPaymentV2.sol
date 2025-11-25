// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AdvancedPaymentSplitterV2
 * @author ZerosAndOnes
 * @notice Extended version with dynamic member updates, partial withdrawals,
 *         individual timelocks, emergency withdrawals, and optimized storage.
 */

contract AdvancedPaymentSplitterV2 {
    // Errors
    error NotAuthorized();
    error InvalidInputs();
    error MemberAlreadyExists(address member);
    error InvalidShare();
    error MemberNotFound(address member);
    error NotAMember();
    error FundsLocked(uint256 unlockTime);
    error ExceedsAllowed(uint256 requested, uint256 allowed);
    error NoFundsAvailable();
    error TransferFailed();

    // Events
    event MemberAdded(address indexed member, uint256 share, uint256 unlockTime);
    event MemberUpdated(address indexed member, uint256 oldShare, uint256 newShare);
    event MemberRemoved(address indexed member);
    event PartialWithdrawal(address indexed member, uint256 amount);
    event FullWithdrawal(address indexed member, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    // State Variables
    address public owner;
    uint256 public totalShares;
    uint256 public totalReceived; // Track total ETH received, never decreased

    // Mappings
    mapping(address => Member) public members;
    address[] public memberList;

    // Struct
    struct Member {
        uint256 share;
        uint256 released;
        uint256 unlockTime;
        bool exists;
    }

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyMember() {
        if (!members[msg.sender].exists) {
            revert NotAMember();
        }
        _;
    }

    // Constructor
    constructor(address[] memory _members, uint256[] memory _shares, uint256[] memory _unlockTimes) payable {
        if (_members.length != _shares.length || _shares.length != _unlockTimes.length) {
            revert InvalidInputs();
        }

        owner = msg.sender;

        for (uint256 i = 0; i < _members.length; i++) {
            _addMember(_members[i], _shares[i], _unlockTimes[i]);
        }

        if (msg.value > 0) {
            totalReceived += msg.value;
        }
    }

    // Receive ETH Function
    receive() external payable {
        totalReceived += msg.value;
    }

    // Internal Functions
    function _addMember(address _member, uint256 _share, uint256 _unlockTime) internal {
        if (members[_member].exists) {
            revert MemberAlreadyExists(_member);
        }
        if (_share == 0) {
            revert InvalidShare();
        }

        members[_member] = Member({
            share: _share,
            released: 0,
            unlockTime: _unlockTime,
            exists: true
        });

        totalShares += _share;
        memberList.push(_member);

        emit MemberAdded(_member, _share, _unlockTime);
    }

    function _removeFromMemberList(address _member) internal {
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // External Functions
    function addMember(address _member, uint256 _share, uint256 _unlockTime) external onlyOwner {
        _addMember(_member, _share, _unlockTime);
    }

    function updateMember(address _member, uint256 _newShare) external onlyOwner {
        if (!members[_member].exists) {
            revert MemberNotFound(_member);
        }
        if (_newShare == 0) {
            revert InvalidShare();
        }

        uint256 oldShare = members[_member].share;
        totalShares = totalShares - oldShare + _newShare;
        members[_member].share = _newShare;

        emit MemberUpdated(_member, oldShare, _newShare);
    }

    function removeMember(address _member) external onlyOwner {
        if (!members[_member].exists) {
            revert MemberNotFound(_member);
        }

        totalShares -= members[_member].share;
        delete members[_member];
        _removeFromMemberList(_member);

        emit MemberRemoved(_member);
    }

    function calculatePayment(address _member) public view returns (uint256) {
        if (!members[_member].exists) {
            revert NotAMember();
        }

        uint256 totalValue = totalReceived;
        uint256 totalPayment = (totalValue * members[_member].share) / totalShares;
        uint256 unreleased = totalPayment - members[_member].released;
        return unreleased;
    }

    function withdrawPartial(uint256 _amount) external onlyMember {
        if (block.timestamp < members[msg.sender].unlockTime) {
            revert FundsLocked(members[msg.sender].unlockTime);
        }

        uint256 available = calculatePayment(msg.sender);
        if (_amount > available) {
            revert ExceedsAllowed(_amount, available);
        }

        // Effects
        members[msg.sender].released += _amount;
        
        // Interactions
        _safeTransferETH(msg.sender, _amount);

        emit PartialWithdrawal(msg.sender, _amount);
    }

    function withdrawFull() external onlyMember {
        if (block.timestamp < members[msg.sender].unlockTime) {
            revert FundsLocked(members[msg.sender].unlockTime);
        }

        uint256 payment = calculatePayment(msg.sender);
        if (payment == 0) {
            revert NoFundsAvailable();
        }

        // Effects
        members[msg.sender].released += payment;
        
        // Interactions
        _safeTransferETH(msg.sender, payment);

        emit FullWithdrawal(msg.sender, payment);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        _safeTransferETH(owner, balance);
        emit EmergencyWithdrawal(owner, balance);
    }

    // View Functions
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    function getAllMembers() external view returns (address[] memory) {
        return memberList;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
