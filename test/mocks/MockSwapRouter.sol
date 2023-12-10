//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../../src/interfaces/IERC20.sol";
import "forge-std/console.sol";

/**
 * @notice - Assumes a perfect swap where the exact max collateral
 * in is the exact amount used for the lend asset interest out.
 */
contract MockSwapRouter {
    function exactOutputSingle(
        ISwapRouter.ExactOutputSingleParams calldata params
    ) external returns (uint256 amountIn) {
        IERC20(params.tokenIn).transferFrom(
            msg.sender,
            address(this),
            params.amountInMaximum
        );
        IERC20(params.tokenOut).transfer(params.recipient, params.amountOut);
        IERC20(params.tokenIn).transfer(msg.sender, 100e9);
        return params.amountInMaximum - 100e9;
    }

    function exactInputSingle(
        ISwapRouter.ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut) {
        IERC20(params.tokenIn).transferFrom(
            msg.sender,
            address(this),
            params.amountIn
        );
        /// @dev - Hardcoded for testing purposes only
        IERC20(params.tokenOut).transfer(params.recipient, 800e6);
        return 800e6;
    }
}
