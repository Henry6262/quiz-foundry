// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import "../src/QuizV2.sol";
import "../src/QuizFactory.sol";

contract QuizFactoryTest is Test {

    QuizFactory public factory;
    address public owner = address(1);

    string public question = "Who is the co-founder of Ethereum?";
    string public answer = "Vitalik Buterin";
    bytes32 public hashedAnswer;

    string private salt = "salt papi";

    function setUp() public {
        hashedAnswer = keccak256(abi.encodePacked(answer, salt));
        vm.deal(owner, 1 ether);
        factory = new QuizFactory{value: 1 ether}();
    }

    function test_validate_questionLenght() public {
        string memory shortQuestion = "size MTRS";
        vm.expectRevert("question should be atleast 10 characters long");
        factory.createQuiz(shortQuestion, answer);
    }

    function test_create_quizWithEther() public {
        vm.prank(owner);
        factory.createQuiz{value: 0.5 ether}(question, answer);

        QuizV2 createdQuiz = factory.getQuizzes()[0];

        assertEq(address(owner).balance, 0.5 ether);
        assertEq(address(createdQuiz).balance, 0.5 ether);
    }

    function test_create_MultipleQuizzes() public {
        vm.prank(owner);
        factory.createQuiz{value: 0.5 ether}(question, answer);
        factory.createQuiz{value: 0.5 ether}("What is Solidity?", "A programming language");

        QuizV2[] memory quizzes = factory.getQuizzes();
        assertEq(quizzes.length, 2);
    }

    function test_create_quizWithoutEther() public {
        vm.prank(owner);
        factory.createQuiz(question, answer);

        QuizV2 createdQuiz = factory.getQuizzes()[0];
        assertEq(address(createdQuiz).balance, 0);
    }

}