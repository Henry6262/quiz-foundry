// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract QuizV2 is Ownable {

    uint8 constant GUESS_MULTIPLIER = 2;
    string public question;
    bytes32 hashedAnswer;
    string salt = "salt papi";

    mapping (address => bool) public correctAnswers;

    event ContractFunded(address fundedBy, uint256 amount);
    event AnswerGuessed(address indexed guesser, string answer);

    constructor(string memory _question, bytes32 _hashedAsnwer) Ownable(msg.sender) payable {
        question = _question;
        hashedAnswer = _hashedAsnwer;
    }

    error NotOwner(address user);
    modifier OnlyOwner(address sender) {
        if(sender != owner()){
            revert NotOwner(sender);
        }
        _;
    }

    error HasGuessed();
    modifier IsNewGuesser(address user) {
        if (correctAnswers[user]) {
            revert HasGuessed();
        }
        _;
    } 

    error NotEnoughCash();

    // questionn -> should we revert is the questionn is not correct ?
    function guess(string calldata userAnswer) IsNewGuesser(msg.sender) external payable  {
        uint256 minimumBalance = 0.001 ether; // Set a minimum balance to retain for gas fees

        if (address(this).balance < msg.value * GUESS_MULTIPLIER + minimumBalance) {
            revert NotEnoughCash();
        }

        bytes32 hashedUserAnwser = keccak256(abi.encodePacked(userAnswer, salt));

        if (hashedUserAnwser == hashedAnswer) {
            emit AnswerGuessed(msg.sender, userAnswer);
            correctAnswers[msg.sender] = true;
            pay(msg.value * GUESS_MULTIPLIER, msg.sender); // reward - > double the bet
        } 
    }

    function ownerWithdrawal(uint256 amount) OnlyOwner(msg.sender) external {
           pay(amount * 1 ether, owner());
    }

    error PayFailed();
    function pay(uint256 amountToSend, address userAdress) private {
        (bool sent, ) = payable(userAdress).call{value: amountToSend}("");
        if (!sent) {
            revert PayFailed();
        }
    } 

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    receive() external payable  {
        emit ContractFunded(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ContractFunded(msg.sender, msg.value);
    }


}