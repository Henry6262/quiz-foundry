// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console, StdCheats} from "forge-std/Test.sol";

import "../src/QuizV2.sol";
import "../src/MockContract.sol";

contract QuizV2Test is Test {


    address public contractOwner = address(1);
    address public user = address(2);

    string public question = "who is daddy";
    string public answer = "big H" ;
    bytes32 public hashedAnswer;

    string public salt = "salt papi";
    uint8 public GUESS_MULTIPLIER = 2;

    QuizV2 public quiz;
    
    MockContract public mockContract;

    function setUp() public {
        hashedAnswer = keccak256(abi.encodePacked(answer, salt));
        vm.prank(contractOwner);
        quiz = new QuizV2(question, hashedAnswer);
        mockContract = new MockContract();
    }

    function testFuzz_fundContractOnDeply(uint256 amount) public {
        vm.assume(amount <= 100); 

        vm.prank(contractOwner);
        vm.deal(contractOwner,amount * 1 ether);

        QuizV2 newQuiz = new QuizV2{value: amount * 1 ether}(question, hashedAnswer);
        assertTrue(address(newQuiz).balance == (amount * 1 ether));
    }

    function test_OwnerIsContractDeployer() public {
        vm.prank(contractOwner);

        QuizV2 newQuiz = new QuizV2(question, hashedAnswer);
        assertEq(contractOwner, newQuiz.owner());
    }


    function test_constructor_ownerFundsAndDeploysContract() public {
        hoax(contractOwner, 1 ether);

        QuizV2 newQuiz = new QuizV2{value: contractOwner.balance}(question, hashedAnswer);
        assertEq(contractOwner, newQuiz.owner());
        assertEq(address(newQuiz).balance, 1 ether);
    }

    // HOW should I name this test ?
    //should I divide this into 3 separate tests ?
    function test_guess_correctAnswer() public {
        vm.deal(address(quiz), 5 ether);
        
        hoax(user, 2 ether);

        vm.expectEmit(true, true, false, true);
        emit QuizV2.AnswerGuessed(user, answer);

        quiz.guess{value: user.balance}(answer);

        assertTrue(quiz.correctAnswers(user));
        assertTrue(user.balance == 4 ether);
    }

    function testFuzz_guess_doesNotRewardWhenAnswerIncorrect(string calldata x) public {
        vm.assume(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(answer)));
        
        vm.deal(user, 2 ether);
        vm.prank(user);
        vm.deal(address(quiz), 5 ether);

        quiz.guess(x);

        assertTrue(user.balance <= 2 ether);
        assertTrue(address(quiz).balance >= 5 ether);
    }

    function test_guess_revertsWhenUserAlreadyAnswered() public {

        vm.deal(address(quiz), 0.1 ether);

        vm.startPrank(user);

            quiz.guess(answer);
            vm.expectRevert(QuizV2.HasGuessed.selector);
            quiz.guess(answer);

        vm.stopPrank();
    }

    function testFuzz_guess_revertsWhenContractHasNotEnoughFunds(uint256 x, uint256 y) public {
        x = bound(x, 1 ether, 100 ether);    
        y = bound(y, 0, x - 0.0011 ether );

        vm.deal(user, x);
        vm.prank(user);
        vm.deal(address(quiz), y);

        vm.expectRevert(QuizV2.NotEnoughCash.selector);

        quiz.guess{value: x}(answer);
    }

    function testFuzz_ownerWithdrawal_succeeds(uint256 amount) public {
    
        amount = bound(amount, 1, 100);
        vm.deal(address(quiz), amount * 2 ether);

        vm.prank(contractOwner);
        
        uint256 initialOwnerBalance = contractOwner.balance;
        uint256 initialContractBalance = address(quiz).balance;
        
        quiz.ownerWithdrawal(amount);
        
        assertEq(contractOwner.balance, initialOwnerBalance + (amount * 1 ether));
        assertEq(address(quiz).balance, initialContractBalance - (amount * 1 ether));
    }

    function test_ownerWithdrawal_revertsForNonOwner() public {
        vm.deal(address(quiz), 5 ether);
        
        // Try to withdraw as non-owner
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(QuizV2.NotOwner.selector, user));
        
        quiz.ownerWithdrawal(1);
    }

    function testFuzz_ownerWithdrawal_revertsWhenNotEnoughFunds(uint256 amount) public {
        amount = bound(amount, 1, type(uint256).max / 1 ether);
        
        vm.deal(address(quiz), amount * 1 ether - 1);
        
        vm.prank(contractOwner);
        vm.expectRevert(QuizV2.PayFailed.selector);
        
        quiz.ownerWithdrawal(amount);
    }

    function testFuzz_getContractBalance_returnsCorrectBalance(uint256 amount) public {
        amount = bound(amount, 0, 1000 ether);
        
        vm.deal(address(quiz), amount);
        
        assertEq(quiz.getContractBalance(), amount);
    }

    function testFuzz_receive_acceptsEtherAndEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        vm.deal(user, amount);
        
        vm.prank(user);
        
        vm.expectEmit(true, true, false, true);
        emit QuizV2.ContractFunded(user, amount);
        
        (bool success,) = address(quiz).call{value: amount}("");
        assertTrue(success);
        assertEq(address(quiz).balance, amount);
    }

    function testFuzz_fallback_acceptsEtherAndEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        vm.deal(user, amount);
        
        vm.prank(user);
        
        vm.expectEmit(true, true, false, true);
        emit QuizV2.ContractFunded(user, amount);
        
        (bool success,) = address(quiz).call{value: amount}(abi.encodeWithSignature("transformers()"));
        assertTrue(success);
        assertEq(address(quiz).balance, amount);
    }

    function test_guess_revertsWhenPaymentFails() public {
        vm.deal(address(mockContract), 2 ether);
        vm.deal(address(quiz), 5 ether);
        
        vm.prank(address(mockContract));
        vm.expectRevert(QuizV2.PayFailed.selector);
        
        quiz.guess{value: 2 ether}(answer);
    }
}