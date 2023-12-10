//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../utils/FullProtocolSetupFork.t.sol";
import "../utils/AnnuityInteractionsSetup.t.sol";
import "../../src/interfaces/IAnnuity.sol";
import "../../src/Annuity/Annuity.sol";
import "../../src/Annuity/AnnuityUtils.sol";

// Test,
contract AnnuityTestFork is
    Test,
    FullProtocolSetupFork,
    AnnuityInteractionsSetup
{
    /// @dev Check "FullProtocolSetupFork" For initial test setup

    Annuity annuity;

    function setUp() public {
        deployProtocol();

        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));
        whitelistDefaultTokens(
            annuityFactory,
            DEPLOYER,
            address(usdc),
            address(weth)
        );

        vm.prank(USER_A);
        address annuityAddr = annuityFactory.createAnnuity(
            address(weth),
            address(usdc),
            BPS500,
            BPS8000,
            ZERO
        );
        annuity = Annuity(annuityAddr);

        vm.warp(NOV_13_2023);
    }

    function test_StateVariablesSetOnInitialize() public {
        (
            address lender,
            address colToken,
            address lendToken,
            uint48 apr,
            uint48 ltv
        ) = annuity.getPoolOptions();

        assertEq(lender, USER_A);
        assertEq(colToken, address(weth));
        assertEq(lendToken, address(usdc));
        assertEq(apr, BPS500);
        assertEq(ltv, BPS8000);
    }

    function test_Deposit() public {
        mintAndApprove(annuity, USER_A, usdc, USDC_1640);

        vm.prank(USER_A);
        annuity.deposit(USDC_1640);

        assertEq(usdc.balanceOf(address(annuity)), USDC_1640);
        assertEq(usdc.balanceOf(USER_A), ZERO);
    }

    function test_DepositWithNonLenderAddress() public {
        mintAndApprove(annuity, USER_B, usdc, USDC_1640);

        assertEq(usdc.balanceOf(address(annuity)), ZERO);
        assertEq(usdc.balanceOf(USER_B), USDC_1640);

        vm.prank(USER_B);
        annuity.deposit(USDC_1640);

        assertEq(usdc.balanceOf(address(annuity)), USDC_1640);
        assertEq(usdc.balanceOf(USER_B), ZERO);
    }

    function test_Withdraw() public {
        depositSetup(annuity, usdc, USDC_1640);

        assertEq(usdc.balanceOf(address(annuity)), USDC_1640);
        assertEq(usdc.balanceOf(USER_A), ZERO);

        vm.prank(USER_A);
        annuity.withdraw(USDC_1640);

        assertEq(usdc.balanceOf(address(annuity)), ZERO);
        assertEq(usdc.balanceOf(USER_A), USDC_1640);
    }

    function test_Borrow() public {
        depositSetup(annuity, usdc, USDC_1640); // 1640 is how much a borrower will recieve when they deposit 1 WETH worth $2050 and LTV is 80%
        mintAndApprove(annuity, USER_B, weth, WETH_1);

        assertEq(weth.balanceOf(USER_B), WETH_1);
        assertEq(weth.balanceOf(address(annuity)), ZERO);
        assertEq(usdc.balanceOf(USER_B), ZERO);
        assertEq(usdc.balanceOf(address(annuity)), USDC_1640);
        uint256 principalBeforeBorrow = annuity.principals(USER_B);
        assertEq(principalBeforeBorrow, ZERO);
        assertEq(annuity.totalBorrowedAmt(), ZERO);
        assertEq(annuity.totalCollateralDeposited(), ZERO);

        vm.prank(USER_B);
        annuity.borrow(WETH_1, USER_B);

        assertEq(weth.balanceOf(USER_B), ZERO);
        assertEq(weth.balanceOf(address(annuity)), WETH_1);
        assertEq(usdc.balanceOf(USER_B), USDC_1640);
        assertEq(usdc.balanceOf(address(annuity)), ZERO);
        assertEq(annuity.totalBorrowedAmt(), USDC_1640);
        assertEq(annuity.totalCollateralDeposited(), WETH_1);
        uint256 principalAfterBorrow = annuity.principals(USER_B);
        assertEq(principalAfterBorrow, USDC_1640);
    }

    function test_Repay() public {
        borrowSetup(annuity, weth, usdc, WETH_1, USDC_3280);
        mintAndApprove(annuity, USER_C, weth, WETH_1);
        uint256 userBPrincipalAmt = usdc.balanceOf(USER_B);

        vm.prank(USER_C);
        annuity.borrow(WETH_1, USER_C);
        uint256 userCPrincipalAmt = usdc.balanceOf(USER_C);

        vm.prank(USER_B);
        usdc.approve(address(annuity), userBPrincipalAmt);

        vm.prank(USER_C);
        usdc.approve(address(annuity), userCPrincipalAmt);

        assertEq(usdc.balanceOf(USER_B), USDC_1640);
        assertEq(weth.balanceOf(USER_B), ZERO);
        assertEq(usdc.balanceOf(address(annuity)), ZERO);
        assertEq(weth.balanceOf(address(annuity)), WETH_2);

        vm.warp(block.timestamp + ONE_YEAR_IN_SECONDS);
        vm.prank(USER_B);
        annuity.repay(userBPrincipalAmt); // Had loan for 1 yeah

        assertEq(annuity.totalBorrowedAmt(), USDC_1640);
        vm.warp(block.timestamp + ONE_YEAR_IN_SECONDS * 2);
        vm.prank(USER_C);
        annuity.repay(userCPrincipalAmt); // Had loan for 2 years

        uint256 userBWethBal = weth.balanceOf(USER_B);
        assertLt(userBWethBal, WETH_1);
        assertLt(weth.balanceOf(USER_C), userBWethBal);
        assertEq(weth.balanceOf(address(annuity)), ZERO);
        assertEq(usdc.balanceOf(address(annuity)), USDC_3280);
        assertEq(usdc.balanceOf(USER_B), ZERO);
        assertEq(usdc.balanceOf(USER_C), ZERO);
        assertEq(annuity.totalBorrowedAmt(), ZERO);
        assertEq(annuity.totalCollateralDeposited(), ZERO);
    }

    function test_LiquidateSelf() public {
        borrowSetup(annuity, weth, usdc, WETH_1, USDC_1640);

        address lender = USER_A;

        assertEq(usdc.balanceOf(lender), ZERO);
        assertEq(usdc.balanceOf(USER_B), USDC_1640);
        assertEq(usdc.balanceOf(address(annuity)), ZERO);
        assertEq(usdc.balanceOf(lender), ZERO);
        assertEq(annuity.totalBorrowedAmt(), USDC_1640);
        assertEq(annuity.totalCollateralDeposited(), WETH_1);

        vm.prank(USER_B);
        annuity.liquidateSelf();

        assertEq(annuity.totalCollateralDeposited(), ZERO);
        assertEq(annuity.totalBorrowedAmt(), ZERO);
        assertGt(usdc.balanceOf(lender), ZERO);
        assertGt(usdc.balanceOf(USER_B), USDC_1640);
        assertEq(usdc.balanceOf(address(annuity)), ZERO);
        assertEq(weth.balanceOf(address(annuity)), ZERO);
    }

    function test_RevertsWhenColAmtExceedsPoolLiquidityByALot() public {
        depositSetup(annuity, usdc, USDC_1000);
        mintAndApprove(annuity, USER_B, weth, WETH_5);

        vm.prank(USER_B);
        vm.expectRevert(InsufficientLiquidity.selector);
        annuity.borrow(WETH_5, USER_B);
    }

    function test_RevertsWhenColAmtExceedsPoolLiquidityByOneWei() public {
        depositSetup(annuity, usdc, USDC_1000);
        mintAndApprove(annuity, USER_B, weth, WETH_5 + 1);

        vm.prank(USER_B);
        vm.expectRevert(InsufficientLiquidity.selector);
        annuity.borrow(WETH_5 + 1, USER_B);
    }

    function test_RevertsWhenColAmtOnBorrowIsZero() public {
        depositSetup(annuity, usdc, USDC_1000);

        vm.prank(USER_B);
        vm.expectRevert(CannotBeZero.selector);
        annuity.borrow(ZERO, USER_B);
    }

    function test_RevertWhenCallerIsNotLender() public {
        depositSetup(annuity, usdc, USDC_1000);

        vm.prank(USER_B);
        vm.expectRevert(OnlyLender.selector);
        annuity.withdraw(USDC_1000);
    }

    /// @notice - Tests the private function "_safeTransferFrom" Zero xfer reversion
    function test_RevertWhenDepositAmtIsZero() public {
        usdc.mint(USER_A, USDC_1000);
        vm.prank(USER_A);
        usdc.approve(address(annuity), USDC_1000);

        vm.prank(USER_A);
        vm.expectRevert(CannotBeZero.selector);
        annuity.deposit(ZERO);
    }

    /// @notice - Tests the private function "_safeTransfer" Zero xfer reversion
    function test_RevertWhenWithdrawlAmtIsZero() public {
        depositSetup(annuity, usdc, USDC_1000);

        vm.prank(USER_A);
        vm.expectRevert(CannotBeZero.selector);
        annuity.withdraw(ZERO);
    }
}
