//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

interface IOracle {
    function getTokenPriceInUsd(address _token) external returns (int256);
}
