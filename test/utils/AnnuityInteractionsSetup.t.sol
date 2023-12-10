//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "../utils/GlobalTestVariables.t.sol";
import "../mocks/MockToken.sol";
import "../../src/Annuity/Annuity.sol";
import "../../src/AnnuityFactory.sol";
import {Client} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract AnnuityInteractionsSetup is Test, GlobalTestVariables {
    function depositSetup(
        Annuity annuity,
        MockToken lendToken,
        uint256 lendAmount
    ) internal {
        mintAndApprove(annuity, USER_A, lendToken, lendAmount);
        vm.prank(USER_A);
        annuity.deposit(lendAmount);
    }

    function borrowSetup(
        Annuity annuity,
        MockToken colToken,
        MockToken lendToken,
        uint256 colAmount,
        uint256 lendAmount
    ) internal {
        depositSetup(annuity, lendToken, lendAmount);
        mintAndApprove(annuity, USER_B, colToken, colAmount);
        vm.prank(USER_B);
        annuity.borrow(colAmount, USER_B);
    }

    function mintAndApprove(
        Annuity annuity,
        address user,
        MockToken token,
        uint256 amount
    ) internal {
        token.mint(user, amount);
        vm.prank(user);
        token.approve(address(annuity), amount);
    }

    function whitelistDefaultTokens(
        AnnuityFactory annuityFactory,
        address factoryOwner,
        address lendToken,
        address colToken
    ) internal {
        vm.prank(factoryOwner);
        annuityFactory.whitelistToken(address(lendToken), true);
        vm.prank(factoryOwner);
        annuityFactory.whitelistToken(address(colToken), true);
    }

    function buildCCIPReceiverMessage(
        bytes32 _msgId,
        uint64 _chainSelector,
        bytes memory _sender,
        bytes memory _data,
        address _token
    ) public pure returns (Client.Any2EVMMessage memory) {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: _token,
            amount: CCIP_LnM_1
        });
        tokenAmounts[0] = tokenAmount;
        return
            Client.Any2EVMMessage({
                messageId: _msgId,
                sourceChainSelector: _chainSelector,
                sender: _sender,
                data: _data,
                destTokenAmounts: tokenAmounts
            });
    }
}
