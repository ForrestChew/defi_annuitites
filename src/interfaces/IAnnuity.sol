//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

interface IAnnuity {
    function initialize(
        address _lender,
        address _colToken,
        address _lendToken,
        address _oracle,
        address _swapperAddr,
        address _annuityTrackerAddr,
        uint48 _apr,
        uint48 _ltv
    ) external;

    function deposit(uint256 _amt) external;
}
