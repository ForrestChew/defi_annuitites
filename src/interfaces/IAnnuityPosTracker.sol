//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

interface IAnnuityPosTracker {
    function createLendPosition(address _pool, address _lender) external;

    function createBorrowPosition(address _pool, address _borrower) external;

    function destroyBorrowPosition(address _pool, address _borrower) external;
}
