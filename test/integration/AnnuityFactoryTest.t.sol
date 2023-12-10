//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/interfaces/IAnnuityFactory.sol";
import "../utils/FullProtocolSetupLocal.t.sol";
import "../../src/AnnuityFactory.sol";
import "../../src/Annuity/Annuity.sol";

contract AnnuityFactoryTest is Test, FullProtocolSetupLocal {
    /// @dev Check "FullProtocolSetupLocal" For initial test setup

    function test_StateVariablesSetInConstructor() public {
        assertEq(annuityFactory.owner(), DEPLOYER);
        assertEq(annuityFactory.annuityImpl(), address(annuityImpl));
    }

    function test_WhitelistToken() public {
        assertEq(annuityFactory.isWhitelisted(address(weth)), false);
        assertEq(annuityFactory.isWhitelisted(address(usdc)), false);

        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(weth), true);
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(usdc), true);

        assertEq(annuityFactory.isWhitelisted(address(weth)), true);
        assertEq(annuityFactory.isWhitelisted(address(usdc)), true);
    }

    function test_CreateAnnuity() public {
        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(weth), true);
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(usdc), true);

        vm.prank(USER_A);
        address annuityAddr = annuityFactory.createAnnuity(
            address(weth),
            address(usdc),
            BPS500,
            BPS8000,
            ZERO
        );
        Annuity annuity = Annuity(annuityAddr);
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
        assertEq(ltv, BPS8000);
        assertEq(apr, BPS500);
    }

    function test_CreateAnnuityWithInitialDeposit() public {
        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(weth), true);
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(usdc), true);

        usdc.mint(USER_A, USDC_1000);

        assertEq(usdc.balanceOf(USER_A), USDC_1000);

        vm.prank(USER_A);
        usdc.approve(address(annuityFactory), USDC_1000);
        vm.prank(USER_A);
        address annuityAddr = annuityFactory.createAnnuity(
            address(weth),
            address(usdc),
            BPS500,
            BPS8000,
            USDC_1000
        );

        assertEq(usdc.balanceOf(annuityAddr), USDC_1000);
        assertEq(usdc.balanceOf(USER_A), ZERO);
    }

    function test_CreateMultipleAnnuitiesFromSameUser() public {
        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));
        address annuityAddr_1;
        address annuityAddr_2;
        address annuityAddr_3;

        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(weth), true);
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(usdc), true);
        {
            vm.prank(USER_A);
            annuityAddr_1 = annuityFactory.createAnnuity(
                address(weth),
                address(usdc),
                BPS500,
                BPS8000,
                ZERO
            );
            vm.prank(USER_A);
            annuityAddr_2 = annuityFactory.createAnnuity(
                address(weth),
                address(usdc),
                BPS500,
                BPS8000,
                ZERO
            );
            vm.prank(USER_A);
            annuityAddr_3 = annuityFactory.createAnnuity(
                address(weth),
                address(usdc),
                BPS500,
                BPS8000,
                ZERO
            );
        }
        Annuity annuity_1 = Annuity(annuityAddr_1);
        Annuity annuity_2 = Annuity(annuityAddr_2);
        Annuity annuity_3 = Annuity(annuityAddr_3);
        (address lender_1, , , , ) = annuity_1.getPoolOptions();
        (address lender_2, , , , ) = annuity_2.getPoolOptions();
        (address lender_3, , , , ) = annuity_3.getPoolOptions();
        assertEq(lender_1, USER_A);
        assertEq(lender_2, USER_A);
        assertEq(lender_3, USER_A);
    }

    function test_RevertWhenCallerIsNotOwner() public {
        vm.expectRevert(OnlyOwner.selector);
        annuityFactory.whitelistToken(address(weth), true);
        vm.expectRevert(OnlyOwner.selector);
        annuityFactory.whitelistToken(address(usdc), true);
    }

    function test_RevertWhenLtvIsZero() public {
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(weth), true);
        vm.prank(DEPLOYER);
        annuityFactory.whitelistToken(address(usdc), true);

        vm.prank(USER_A);
        vm.expectRevert(InvalidLtv.selector);
        annuityFactory.createAnnuity(
            address(weth),
            address(usdc),
            BPS500,
            ZERO,
            ZERO
        );
    }
}
