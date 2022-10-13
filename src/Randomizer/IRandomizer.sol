// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/// @title Interface for Randomizer contract that gets and stores a random value in a range
/// @notice Interfaces with chainlink VRF
interface IRandomizer {
    /// @notice Get a random value in [0, maxValue]
    /// @dev Can only be called by the operator
    /// @param maxValue The upper end of the range
    /// @param round Marker to store successful requests
    /// @return randomValue A random value in [0, maxValue]
    function getRandomValueInRange(uint256 maxValue, uint256 round) external returns (uint256 randomValue);

    /// @notice Send a request to the coordinator for a randomUint
    /// @dev Can only be called by the operator
    /// @dev A fulfilled request populates rawRandomUint and sets readyWithAnswer as true
    function requestRandomUint() external;

    /// @notice The address of the chainlink VRF coordinator
    function coordinator() external view returns (address);

    /// @notice The operator of the contract
    /// @dev All non-view functions must be called by the operator
    function operator() external view returns (address);

    /// @notice Stores past answers returned by getRandomValueInRange
    /// @dev Unused round values return 0
    /// @param round The round to get data for
    /// @return The given rounds random value in range
    function pastRoundAnswers(uint256 round) external view returns (uint256);

    /// @notice The raw random value received from chainlink during
    /// the latest VRF request
    /// @dev This random uint is deleted every time getRandomValueInRange is
    /// called successfully
    /// @dev Returns 0 if no there is no current recorded random value
    /// @return The random uint from chainlink
    function rawRandomUint() external view returns (uint256);

    /// @notice Has the randomizer successfully received an answer from chainlink
    /// @dev Marks if we are ready for a getRandomValueInRange call
    /// @dev Reset every time getRandomValueInRange is called successfully
    function readyWithAnswer() external view returns (bool);
}
