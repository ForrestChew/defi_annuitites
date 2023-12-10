//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../utils/FullProtocolSetupLocal.t.sol";
import {AnnuityPosTracker} from "../../src/AnnuityPosTracker.sol";

contract AnnuityPosTrackerTest is Test, FullProtocolSetupLocal {
    /// @dev Check "FullProtocolSetupLocal" For initial test setup

    function test_CreateSingleLendPostion() public {
        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));

        address annuityAddr = address(1);
        address startPosIdBeforePosCreation = annuityTracker
            .firstLendPosStartId(USER_A);
        assertEq(startPosIdBeforePosCreation, address(0));
        assertEq(annuityTracker.lendPosCount(USER_A), ZERO);

        vm.prank(address(annuityFactory));
        annuityTracker.createLendPosition(annuityAddr, USER_A);
        address startPosIdAfterPosCreation = annuityTracker.firstLendPosStartId(
            USER_A
        );
        (address pool, address next, address prev) = annuityTracker
            .lendPositions(startPosIdAfterPosCreation);
        assertEq(startPosIdAfterPosCreation, annuityAddr);
        assertEq(annuityTracker.lendPosCount(USER_A), 1);
        assertEq(pool, annuityAddr);
        assertEq(next, address(0));
        assertEq(prev, address(0));
    }

    function test_CreateMultipleLendPostions() public {
        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));
        address firstAnnuityAddr = address(1);
        address scndAnnuityAddr = address(2);

        vm.prank(address(annuityFactory));
        annuityTracker.createLendPosition(firstAnnuityAddr, USER_A);
        assertEq(annuityTracker.lendPosCount(USER_A), 1);
        address startPosIdAfter_FirstCreation = annuityTracker
            .firstLendPosStartId(USER_A);
        assertEq(startPosIdAfter_FirstCreation, firstAnnuityAddr);
        (
            address first_pool,
            address first_next,
            address first_prev
        ) = annuityTracker.lendPositions(startPosIdAfter_FirstCreation);
        assertEq(first_pool, firstAnnuityAddr);
        assertEq(first_next, address(0));
        assertEq(first_prev, address(0));

        vm.prank(address(annuityFactory));
        annuityTracker.createLendPosition(scndAnnuityAddr, USER_A);
        assertEq(annuityTracker.lendPosCount(USER_A), 2);
        address startPosIdAfter_ScndCreation = annuityTracker
            .firstLendPosStartId(USER_A);
        assertEq(startPosIdAfter_ScndCreation, scndAnnuityAddr);
        (
            address scnd_pool,
            address scnd_next,
            address scnd_prev
        ) = annuityTracker.lendPositions(startPosIdAfter_ScndCreation);
        assertEq(scnd_next, firstAnnuityAddr);
        assertEq(scnd_prev, address(0));
        assertEq(scnd_pool, scndAnnuityAddr);
        (
            address first_pool_check,
            address first_next_check,
            address first_prev_check
        ) = annuityTracker.lendPositions(startPosIdAfter_FirstCreation);
        assertEq(first_pool_check, firstAnnuityAddr);
        assertEq(first_next_check, address(0));
        assertEq(first_prev_check, scndAnnuityAddr);
    }
}
