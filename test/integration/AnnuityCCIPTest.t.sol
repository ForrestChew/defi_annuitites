//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../utils/FullProtocolSetupLocal.t.sol";
import "../utils/AnnuityInteractionsSetup.t.sol";
import "../../src/interfaces/IAnnuity.sol";
import "../../src/Annuity/Annuity.sol";
import "../../src/Annuity/AnnuityUtils.sol";
import {Client} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract AnnuityTestLocal is
    Test,
    FullProtocolSetupLocal,
    AnnuityInteractionsSetup
{
    /// @dev Check "FullProtocolSetupLocal" For initial test setup

    Annuity annuity;

    function setUp() public {
        vm.prank(DEPLOYER);
        annuityTracker.setFactory(address(annuityFactory));
        whitelistDefaultTokens(
            annuityFactory,
            DEPLOYER,
            address(ccipBnm),
            address(ccipLnm)
        );
        oracle.setTokenPrice(address(ccipBnm), CCIP_BnM_PRICE_RAW_1);
        oracle.setTokenPrice(address(ccipLnm), CCIP_LnM_PRICE_RAW_100);
        ccipLnm.mint(address(ccipReceiver), CCIP_LnM_1);

        vm.prank(USER_A);
        address annuityAddr = annuityFactory.createAnnuity(
            address(ccipLnm),
            address(ccipBnm),
            BPS500,
            BPS8000,
            ZERO
        );
        annuity = Annuity(annuityAddr);
    }

    function test_CCIPBorrow() public {
        depositSetup(annuity, ccipBnm, CCIP_BnM_80);
        Client.Any2EVMMessage memory message = buildCCIPReceiverMessage(
            bytes32(0),
            AVAX_FUJI_CHAIN_SELECTOR,
            abi.encode(address(500)),
            abi.encode("borrow(uint256,address)", address(annuity), USER_B),
            address(ccipLnm)
        );
        assertEq(ccipBnm.balanceOf(USER_B), ZERO);
        assertEq(ccipLnm.balanceOf(USER_B), ZERO);
        assertEq(ccipLnm.balanceOf(address(ccipReceiver)), CCIP_LnM_1);
        assertEq(ccipLnm.balanceOf(address(annuity)), ZERO);
        assertEq(ccipBnm.balanceOf(address(annuity)), CCIP_BnM_80);

        ccipReceiver.ccipReceive(message);

        assertEq(ccipBnm.balanceOf(USER_B), CCIP_BnM_80);
        assertEq(ccipLnm.balanceOf(USER_B), ZERO);
        assertEq(ccipLnm.balanceOf(address(ccipReceiver)), ZERO);
        assertEq(ccipLnm.balanceOf(address(annuity)), CCIP_LnM_1);
        assertEq(ccipBnm.balanceOf(address(annuity)), ZERO);
    }
}
