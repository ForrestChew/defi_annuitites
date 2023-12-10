//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function decimals() external view returns (uint8);
}
