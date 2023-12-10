//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap-v3-periphery/contracts/libraries/TransferHelper.sol";
import "forge-std/console.sol";

contract Swapper {
    string public identifier;
    ISwapRouter public swapRouter;

    constructor(ISwapRouter _routerAddress, string memory _identifier) {
        swapRouter = _routerAddress;
        identifier = _identifier;
    }

    /**
     * @notice                    - Swaps collateral for lend asset interest owed to lender on Uniswap.
     *                              Used in standard interest collections.
     * @param _lendAssetOut       - Amount of lend asset interest owed to lender.
     * @param _collateralInMax    - Max amount of collateral to be swapped for lend asset interest.
     * @param _lendToken          - Address of lend asset.
     * @param _colToken           - Address of collateral asset.
     * @param _lender             - Address of lender.
     * @return collateralInActual - Actual amount of collateral used in swap for lend asset interest.
     */
    function swapCollateralForLendAssetInterest(
        uint256 _lendAssetOut,
        uint256 _collateralInMax,
        address _lendToken,
        address _colToken,
        address _lender
    ) external returns (uint256 collateralInActual) {
        TransferHelper.safeTransferFrom(
            _colToken,
            msg.sender,
            address(this),
            _collateralInMax
        );
        TransferHelper.safeApprove(
            _colToken,
            address(swapRouter),
            _collateralInMax
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: _colToken,
                tokenOut: _lendToken,
                fee: 10000,
                recipient: _lender,
                amountOut: _lendAssetOut,
                amountInMaximum: _collateralInMax,
                sqrtPriceLimitX96: 0
            });

        collateralInActual = swapRouter.exactOutputSingle(params);

        if (collateralInActual < _collateralInMax) {
            TransferHelper.safeApprove(_colToken, address(swapRouter), 0);
            TransferHelper.safeTransfer(
                _colToken,
                msg.sender,
                _collateralInMax - collateralInActual
            );
        }
    }

    /**
     * @notice              - Swaps single borrower's position collateral entirely for lend assets.
     *                        Used in borrower initiated self-liquidations.
     * @param _lendToken    - Address of lend asset.
     * @param _colToken     - Address of collateral asset.
     * @return lendAssetOut - Amount of lend asset received from swap.
     */
    function swapPositionCollateralForLendAsset(
        uint256 _collateralAmtIn,
        address _lendToken,
        address _colToken
    ) external returns (uint256 lendAssetOut) {
        TransferHelper.safeTransferFrom(
            _colToken,
            msg.sender,
            address(this),
            _collateralAmtIn
        );
        TransferHelper.safeApprove(
            _colToken,
            address(swapRouter),
            _collateralAmtIn
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _colToken,
                tokenOut: _lendToken,
                fee: 10000,
                recipient: msg.sender,
                amountIn: _collateralAmtIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        lendAssetOut = swapRouter.exactInputSingle(params);
    }
}
