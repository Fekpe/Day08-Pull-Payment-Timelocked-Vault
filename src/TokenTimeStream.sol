// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title TokenTimeStream
 * @author ZerosAndOnes
 * @notice ERC20 + ETH streaming payment contract with automated linear payouts
 * @dev Allows users to claim based on time passed — pull payment model
 */

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenTimeStream {

    // Errors
    rror NotOwner();
    error InvalidAddress();
    error InvalidTime();
    error NothingToWithdraw();

    // Events
    event StreamCreated(uint256 indexed id, address indexed receiver, uint256 amount, address token);
    event Withdrawn(uint256 indexed id, address indexed receiver, uint256 amount);

    // State Variables
    address public immutable i_owner;
    uint256 public streamCounter;

    // Struct
    struct Stream {
        address token;
        address receiver;
        uint256 deposit;
        uint256 withdrawn;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Stream) public streams;

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // Constructor
    constructor() {
        i_owner = msg.sender;
    }

    // Functions
    function createStream(address _receiver, uint256 _amount, uint256 _duration, address _token
    ) external payable onlyOwner {
        if (_receiver == address(0)) {
            revert InvalidAddress();
        }
        if (_duration == 0) {
            revert InvalidTime();
        }

        uint256 streamId = ++streamCounter;

        if (_token == address(0)) {
            require(msg.value == _amount, "ETH amount mismatch");
        }

        streams[streamId] = Stream({
            token: _token,
            receiver: _receiver,
            deposit: _amount,
            withdrawn: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration
        });

        emit StreamCreated(streamId, _receiver, _amount, _token);
    }

    function withdraw(uint256 streamId) external {
        Stream storage stream = streams[streamId];
        
        uint256 withdrawable = calculateWithdrawable(streamId);
        if (withdrawable == 0) {
            revert NothingToWithdraw();
        }

        stream.withdrawn += withdrawable;

        if (stream.token == address(0)) {
            payable(stream.receiver).transfer(withdrawable);
        } else {
            IERC20(stream.token).transfer(stream.receiver, withdrawable);
        }

        emit Withdrawn(streamId, stream.receiver, withdrawable);
    }

    function calculateWithdrawable(uint256 streamId) public view returns(uint256) {
        Stream memory stream = streams[streamId];

        if (block.timestamp < stream.startTime) return 0;

        uint256 elapsed = block.timestamp >= stream.endTime
            ? stream.endTime - stream.startTime
            : block.timestamp - stream.startTime;

        uint256 totalStreamable = (stream.deposit * elapsed) /
            (stream.endTime - stream.startTime);

        return totalStreamable - stream.withdrawn;
    }
}