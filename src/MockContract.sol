// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface QuizGuessInterface {
    function guess(string memory answer) external;
}

contract MockContract {
    function callOtherContract(address _target, string memory answer) public {
        QuizGuessInterface(_target).guess(answer);
    }

    fallback() external payable {
        revert("fallback revert");
    }

    receive() external payable {
        revert("fallback revert");
    }

}