// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {Ownable} from '../dependencies/Ownable.sol';
import {IRandomizer} from '../IRandomizer.sol';

contract MockRandomizer is IRandomizer, Ownable {
    uint256 constant MAX_UINT = type(uint256).max;

    address public override coordinator = address(0);

    uint256 public override rawRandomUint;

    bool public override readyWithAnswer;

    bool revertOnRequest;

    // round => scaled random result
    mapping(uint256 => uint256) public override pastRoundAnswers;

    function operator() external view override returns (address) {
        return owner();
    }

    constructor(uint256 randomWord) {
        rawRandomUint = randomWord;
    }

    // converts randomizedWords from chainLink into the range [0, maxValue]
    function getRandomValueInRange(uint256 maxValue, uint256 round) external onlyOwner returns (uint256 randomValue) {
        require(readyWithAnswer, 'Randomizer: Not ready');

        uint256 randomUint = rawRandomUint;

        delete rawRandomUint;
        delete readyWithAnswer;

        // only answer can be 0
        if (maxValue == 0) {
            randomValue = 0;
        }
        // prevents overflow if chainlink returns MAX_UINT
        else if (randomUint == MAX_UINT) {
            randomValue = maxValue;
        }
        // normalize chainlink response into desired range
        else {
            // split uint range into slices
            uint256 denom = MAX_UINT / (maxValue + 1); // never overflows
            // check how many slices fit in the answer, scales range to [0, maxValue]
            randomValue = randomUint / denom; // never divides by 0
        }

        // record the value
        pastRoundAnswers[round] = randomValue;
    }

    // gets a uint from the range [0, maxValue]
    function requestRandomUint() external onlyOwner {
        if (revertOnRequest) revert();
        readyWithAnswer = true;
    }

    // mock setters

    function __setRawUint(uint256 randomWord) external {
        rawRandomUint = randomWord;
    }

    function __reset() external {
        delete rawRandomUint;
        // delete requestId;
        delete readyWithAnswer;
    }

    function __setRevertOnRequest(bool rev) external {
        revertOnRequest = rev;
    }
}
