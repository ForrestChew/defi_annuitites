// SPDX-License-Identifier: -
pragma solidity 0.8.22;

import {OwnerIsCreator} from "@chainlink-ccip/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {CCIPReceiver} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "../../interfaces/IAnnuityFactory.sol";
import "../../interfaces/IERC20.sol";

event MintCallSuccessfull();

error SourceChainNotWhitelisted(uint64 sourceChainSelector);
error SenderNotWhitelisted(address sender);
error AnnuityFuncInvocationFailure();


contract CCIP_LiquidityReceiver is CCIPReceiver, OwnerIsCreator {
    mapping(uint64 => bool) public whitelistedSourceChains;
    mapping(address => bool) public whitelistedSenders;

    constructor(address router) 
        CCIPReceiver(router) {
    }

    /**
     * @notice        - Receives a CCIP message from a whitelisted source chain and invokes a target
     *                  function within the annuities protocol. 
     * @param message - CCIP message containing data to be used in target function invocation.
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    )
        internal
        override
    {
        _onlyWhitelistedSourceChain(message.sourceChainSelector);
        _onlyWhitelistedSenders(abi.decode(message.sender, (address)));

        (string memory funcSig, address annuity, address borrower) = 
            abi.decode(message.data, (string, address, address));
        IERC20(message.destTokenAmounts[0].token).approve(
            annuity, message.destTokenAmounts[0].amount
        );
        bytes memory annuityFuncInvocation = 
            abi.encodeWithSignature(funcSig, message.destTokenAmounts[0].amount, borrower);
        (bool success, ) = annuity.call(annuityFuncInvocation);
        if (!success) revert AnnuityFuncInvocationFailure();

        emit MintCallSuccessfull();
    }

    // --- Setters --- \\
    function setSenderAllowlist(address _sender, bool _enabled) external onlyOwner {
        whitelistedSenders[_sender] = _enabled;
    }

    function setChainAllowlist(
        uint64 _sourceChainSelector, bool _enabled
    ) external onlyOwner {
        whitelistedSourceChains[_sourceChainSelector] = _enabled;
    }

    // --- Modifiers --- \\
    function _onlyWhitelistedSourceChain(uint64 _sourceChainSelector) private view {
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
    }

    function _onlyWhitelistedSenders(address _sender) private view {
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
    }
}
