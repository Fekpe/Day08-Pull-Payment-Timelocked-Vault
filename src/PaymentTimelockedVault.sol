// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title PaymentTimelockedVault
 * @author ZerosAndOnes
 * @notice A secure vault where ETH is locked for a beneficiary until a specific timestamp.
 * @dev Implements pull-payment pattern for gas efficiency and safety.
 */

contract PaymentTimelockedVault {

    // Errors
    error NotBeneficiary();
    error WithdrawalTooEarly(uint256 currentTime, uint256 releaseTime);
    error NoFundsToWithdraw();
    error WithdrawalFailed();

    // Events
    event Deposited(address indexed depositor, uint256 amount);
    event Withdrawn(address indexed beneficiary, uint256 amount);

    // State Variables
    address public immutable i_beneficiary;
    uint256 public immutable i_releaseTime; // timestamp
    uint256 public totalDeposited;

    // Modifiers
    modifier onlyBeneficiary() {
        if (msg.sender != i_beneficiary) {
            revert NotBeneficiary();
        }
        _;
    }

    // Constructor
    /**
     * @param _beneficiary Address allowed to withdraw after unlock
     * @param _releaseTime Unix timestamp when withdrawal is allowed
     */
    constructor(address _beneficiary, uint256 _releaseTime) payable {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_releaseTime > block.timestamp, "Unlock time must be in the future");

        i_beneficiary = _beneficiary;
        i_releaseTime = _releaseTime;
    }

    // External Functions
     /**
     * @notice Deposit ETH to lock until unlockTime.
     * @dev Any address can deposit for the beneficiary.
     */

    function deposit() external payable {
        if (msg.value == 0) {
            revert NoFundsToWithdraw();
        }

        totalDeposited += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Beneficiary withdraws ETH after unlockTime.
     * @dev Uses pull payment for security; no reentrancy risk.
     */
    function withdraw() external onlyBeneficiary {
        if (block.timestamp < i_releaseTime) {
            revert WithdrawalTooEarly(block.timestamp, i_releaseTime);
        }

        uint256 amount = totalDeposited;
        if (amount == 0) {
            revert NoFundsToWithdraw();
        }

        totalDeposited = 0;

        (bool success, ) = i_beneficiary.call{value: amount}("");
        if (!success) {
            revert WithdrawalFailed();
        }

        emit Withdrawn(i_beneficiary, amount);
    }

    // View Functions
    function timeLeft() external view returns (uint256) {
        return block.timestamp >= i_releaseTime 
        ? 0 
        : i_releaseTime - block.timestamp;
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
