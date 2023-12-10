//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import {Client} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "../../src/interfaces/IERC20.sol";
import "forge-std/console.sol";

error AnnuityFuncInvocationFailure();

contract MockCCIP_LiquidityReceiver {
    function ccipReceive(Client.Any2EVMMessage memory message) external {
        _ccipReceive(message);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal {
        (string memory funcSig, address annuity, address borrower) = abi.decode(
            message.data,
            (string, address, address)
        );
        IERC20(message.destTokenAmounts[0].token).approve(
            annuity,
            message.destTokenAmounts[0].amount
        );
        bytes memory annuityFuncInvocation = abi.encodeWithSignature(
            funcSig,
            message.destTokenAmounts[0].amount,
            borrower
        );
        (bool success, ) = annuity.call(annuityFuncInvocation);
        if (!success) revert AnnuityFuncInvocationFailure();
    }
}
