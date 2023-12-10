//SPDX-License-Identifier: -
pragma solidity 0.8.22;

contract MockOracle {
    mapping(address token => int256 price) internal tokenPrices;

    function getTokenPriceInUsd(address _token) public view returns (int256) {
        return tokenPrices[_token];
    }

    function setTokenPrice(address _token, int256 _price) public {
        tokenPrices[_token] = _price;
    }
}
