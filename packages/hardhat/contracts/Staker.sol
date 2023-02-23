// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  event Stake(address, uint256);

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;

  uint256 totalStakedAmount = 0;
  uint256 public constant threshold = 0.1 ether;

  uint deadline = 72 hours;

  bool openForWithdraw = false;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline += block.timestamp;
  }

  modifier checkDeadline() {
    require(block.timestamp > deadline, "Not so fast bozzo");
    _;
  }

  modifier isPayValid() {
    require(msg.value > 0, "Your stake amount cannot be 0");
    _;
  }

  modifier notCompleted() {
    require(exampleExternalContract.completed() == false, "already completed");
    _;
  }

  modifier withdrawable() {
    require(openForWithdraw == true, "withdraws are not open yet");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable isPayValid {
    // require(msg.value > 0, "Your stake amount cannot be 0");
    balances[msg.sender] += msg.value;
    totalStakedAmount += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public checkDeadline notCompleted{
    if (address(this).balance >= threshold) {
    exampleExternalContract.complete{value: address(this).balance}();
    } else if (address(this).balance < threshold) {
      openForWithdraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public payable notCompleted withdrawable{
    payable(msg.sender).transfer(balances[msg.sender]);
    openForWithdraw = false;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    if (deadline >= block.timestamp) {
      return deadline - block.timestamp;
    }
    return 0;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}
