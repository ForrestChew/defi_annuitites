//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import "../interfaces/IOracle.sol";
import "../interfaces/IAnnuity.sol";
import "../interfaces/IERC20.sol";

library AnnuityUtils {
    uint48 internal constant HUNDRED_PERCENT = 100_0000;
    uint48 private constant ONE_YEAR_IN_SECONDS = 31_536_000;

    /**
     * @notice               - Calculates the amount of lend tokens that can be borrowed based on 
     *                         deposited collateral.
     * @param _colDepositAmt - Amount of collateral deposited by borrower.
     * @param _ltv           - Max borrowing power on collateral.
     * @param _colToken      - Address of the collateral token.
     * @param _lendToken     - Address of the lend token.
     * @param _oracle        - Address of the protocol oracle.
     * @return               - Amount of lend tokens that can be borrowed.
     */
    function calculatePrincipal(
        uint256 _colDepositAmt,
        uint256 _ltv,
        IERC20 _colToken,
        IERC20 _lendToken,
        IOracle _oracle
    ) internal returns (uint256) {
        uint8 colDecimals = _colToken.decimals();
        uint8 lendDecimals = _lendToken.decimals();

        uint256 colTknPrice = uint256(
            _oracle.getTokenPriceInUsd(address(_colToken)) * 10 ** 10);
        uint256 lendTknPrice = uint256(
            _oracle.getTokenPriceInUsd(address(_lendToken)) * 10 ** 10);

        uint256 colLtvAdjustedPriceValue = (_colDepositAmt * _ltv) /
            HUNDRED_PERCENT;
        uint256 colLtvAdjustedAmountValue = colTknPrice *
            colLtvAdjustedPriceValue;
        uint256 lendTokenAmt = colLtvAdjustedAmountValue / lendTknPrice;

        if (colDecimals >= lendDecimals)
            return lendTokenAmt / (10 ** (colDecimals - lendDecimals));
        else return lendTokenAmt * (10 ** (lendDecimals - colDecimals));
    }

    /**
     * @notice                      - Calculates interest owed to a lender at the moment in time at which 
     *                                the function is called.
     * @param _totalBorrowedAmt     - Total amount of lend tokens borrowed from the annuity.
     * @param _accumStart           - Timestamp at which the interest accumulation began.
     * @param _apr                  - Amount of interest lender wishes to charge borrowers on loan.
     *                                Value hardcoded in annuity.
     * @return exactLendInterestAmt - Amount of interest in the lend asset owed to lender.
     */
    function calculateLendInterestAmt(
        uint256 _totalBorrowedAmt,
        uint256 _accumStart,
        uint48 _apr
    ) internal view returns (uint256 exactLendInterestAmt) {
        uint256 elapsedTime = block.timestamp - _accumStart;
        uint256 adjustedApr = (_apr * elapsedTime) / ONE_YEAR_IN_SECONDS;

        exactLendInterestAmt =
            (_totalBorrowedAmt * adjustedApr) /
            HUNDRED_PERCENT;
    }

    /**
     * @notice                  - Calculates the amount of collateral required to swap for the exact amount of 
     *                            lend token interest owed to a lender.
     * @param _exactInterestAmt - Amount of interest in the lend asset owed to lender.
     * @param _colToken         - Address of the collateral token.
     * @param _lendToken        - Address of the lend token.
     * @param _oracle           - Address of the protocol oracle.
     */
    function calculateMaxColForInterest(
        uint256 _exactInterestAmt,
        IERC20 _colToken,
        IERC20 _lendToken,
        IOracle _oracle
    ) internal returns (uint256) {
        uint8 colDecimals = _colToken.decimals();
        uint8 lendDecimals = _lendToken.decimals();

        uint256 colTknPrice = uint256(
            _oracle.getTokenPriceInUsd(address(_colToken)) * 10 ** 10);
        uint256 lendTknPrice = uint256(
            _oracle.getTokenPriceInUsd(address(_lendToken)) * 10 ** 10);

        uint256 totalInterestValue = _exactInterestAmt * lendTknPrice;
        uint256 maxColForSwap = totalInterestValue / colTknPrice;

        if (colDecimals >= lendDecimals)
            return maxColForSwap * (10 ** (colDecimals - lendDecimals));
        else return maxColForSwap / (10 ** (lendDecimals - colDecimals));
    }
}
