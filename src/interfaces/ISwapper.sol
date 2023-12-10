//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

interface ISwapper {
    function swapCollateralForLendAssetInterest(
        uint256 _amountOut,
        uint256 _amountInMaximum,
        address _lendToken,
        address _colToken,
        address _lender
    ) external returns (uint256);

    function swapPositionCollateralForLendAsset(
        uint256 _collateralAmtIn,
        address _lendToken,
        address _colToken
    ) external returns (uint256);
}
