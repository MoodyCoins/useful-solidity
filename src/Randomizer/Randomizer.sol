// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {VRFConsumerBaseV2} from './dependencies/VRFConsumerBaseV2.sol';
import {VRFCoordinatorV2Interface} from './dependencies/VRFCoordinatorV2Interface.sol';
import {Ownable} from './dependencies/Ownable.sol';
import {IRandomizer} from './IRandomizer.sol';

/// @title Contract for getting a random value in a range
contract Randomizer is IRandomizer, VRFConsumerBaseV2, Ownable {
    /// @dev Max uint256
    uint256 constant MAX_UINT = type(uint256).max;

    /// @notice Number of confirmations for chainlink vrf requests
    /// @dev See VRFConsumerBaseV2 Security Considerations for why you may want more. Acceptable range is [3, 200]
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    /// @notice Gas limit for chainlink vrf response calls
    uint32 public constant CALLBACK_GAS_LIMIT = 1_000_000;

    /// @notice Determines amount of gas to use in chainlink vrf requests
    bytes32 public immutable gasLaneKeyHash;

    /// @inheritdoc IRandomizer
    address public immutable override coordinator;

    /// @notice Chainlink vrf subscription
    uint64 public subscriptionId;

    /// @dev Chainlink vrf request identifier
    uint256 internal requestId;

    /// @dev Chainlink vrf response
    uint256[] internal randomUints;

    /// @inheritdoc IRandomizer
    bool public override readyWithAnswer;

    /// @inheritdoc IRandomizer
    mapping(uint256 => uint256) public override pastRoundAnswers;

    /// @inheritdoc IRandomizer
    function rawRandomUint() external view override returns (uint256) {
        if (randomUints.length == 0) return 0;
        else return randomUints[0];
    }

    /// @inheritdoc IRandomizer
    function operator() external view override returns (address) {
        return owner();
    }

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _gasLaneKeyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        coordinator = _vrfCoordinator;
        gasLaneKeyHash = _gasLaneKeyHash;
        subscriptionId = _subscriptionId;
    }

    /// @inheritdoc IRandomizer
    function getRandomValueInRange(uint256 maxValue, uint256 round)
        external
        override
        onlyOwner
        returns (uint256 randomValue)
    {
        require(readyWithAnswer, 'Randomizer: Not ready');

        uint256 randomUint = randomUints[0];

        // reset state
        delete randomUints;
        delete requestId;
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

    /// @inheritdoc IRandomizer
    function requestRandomUint() external override onlyOwner {
        requestId = VRFCoordinatorV2Interface(coordinator).requestRandomWords(
            gasLaneKeyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1 // number of words to request
        );
    }

    /// @dev Chainlink vrf callback function
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomUints = randomWords;
        readyWithAnswer = true;
    }
}
