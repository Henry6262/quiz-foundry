// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../src/QuizV2.sol";

contract QuizFactory {

  QuizV2[] public quizzes;
  event QuizzCreated(QuizV2 indexed quiz);

  string salt = "salt papi";

  constructor() payable {}

  modifier validQuestion(string memory question) {
    require(bytes(question).length > 10, "question should be atleast 10 characters long");
    _;
  }

  function createQuiz(string memory question, string memory answer) public payable validQuestion(question) {
    bytes32 hashedAnswer = keccak256(abi.encodePacked(answer, salt));
    QuizV2 newQuiz = new QuizV2 {value: msg.value} (question, hashedAnswer);
    quizzes.push(newQuiz);
    emit QuizzCreated(newQuiz);
  }

  function getQuizzes() public view returns(QuizV2[] memory allQuizzes){
    return quizzes;
  }


}