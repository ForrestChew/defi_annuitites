//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error OnlyOwner();

contract Oracle {
    address public owner;

    mapping(address token => address feed) public usdFeeds;

    constructor(
        address[] memory _usdTokens,
        address[] memory _usdFeeds,
        address _owner
    ) {
        owner = _owner;
        for (uint256 i = 0; i < _usdTokens.length; i++) {
            usdFeeds[_usdTokens[i]] = _usdFeeds[i];
        }
    }

    function getTokenPriceInUsd(address _token) external view returns (int256) {
        address usdPriceFeed = usdFeeds[_token];
        AggregatorV3Interface dataFeed = AggregatorV3Interface(usdPriceFeed);
        (, int256 answer, , , ) = dataFeed.latestRoundData();
        return answer;
    }

    function addFeed(address _token, address _feed) external {
        if (msg.sender != owner) revert OnlyOwner();
        usdFeeds[_token] = _feed;
    }
}
