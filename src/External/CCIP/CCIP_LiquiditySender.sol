//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import {OwnerIsCreator} from "@chainlink-ccip/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink-ccip/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "forge-std/console.sol";

error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); 
error DestinationChainNotWhitelisted(uint64 destinationChainSelector);
error NothingToWithdraw();
error OnlyOwner();

event TokensTransferred(
    bytes32 indexed messageId,
    uint64 indexed destinationChainSelector, 
    address receiver, 
    address token, 
    uint256 tokenAmount, 
    address feeToken,
    uint256 fees
);

contract CCIP_LiquiditySender {

    address public owner;

    IRouterClient router;
    LinkTokenInterface linkToken;
    
    mapping(uint64 => bool) public whitelistedChains;

    constructor(address _router, address _link, address _owner) {
        router = IRouterClient(_router);
        linkToken = LinkTokenInterface(_link);
        owner = _owner;
    }

    /**
     * @notice                          - Sends a CCIP message to a whitelisted destination chain and invokes a
     *                                    target function within the annuities protocol.
     * @param _destinationChainSelector - Chain ID of destination chain.
     * @param _receiver                 - Address of receiver on destination chain.
     * @param _token                    - Address of token to be sent to receiver.
     * @param _amount                   - Amount of token to be sent to receiver.
     * @param _fcInvocation             - Function selector of target function to be invoked on 
                                          destination chain receiver contract.
     * @param _annuity                  - Address of annuity contract on destination chain.
     */
    function crossChainAnnuityInvocation(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount,
        string memory _fcInvocation,
        address _annuity,
        uint256 _gasLimit
    ) 
        external
        returns (bytes32 messageId) 
    {
        _onlyWhitelistedChain(_destinationChainSelector);

        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(_fcInvocation, _annuity, msg.sender), // Call _fcInvocation selctor on destination liq connector which in turn should call mirrored fc sig on Annuity protocol
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _gasLimit})
            ),
            feeToken: address(linkToken)
        });
        
        uint256 fees = router.getFee(_destinationChainSelector, message);

        if (fees > linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);
        linkToken.approve(address(router), fees);

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        token.approve(address(router), _amount);
        
        messageId = router.ccipSend(_destinationChainSelector, message); 
        
        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(linkToken),
            fees
        );   
    }
    
    function withdrawToken(
        address _beneficiary,
        address _token
    ) public {
        _onlyOwner();
        uint256 amount = IERC20(_token).balanceOf(address(this));
        
        if (amount == 0) revert NothingToWithdraw();
        
        IERC20(_token).transfer(_beneficiary, amount);
    }

    function setChainAllowlist(
        uint64 _destinationChainSelector,
        bool _enabled
    ) external {
        _onlyOwner();
        whitelistedChains[_destinationChainSelector] = _enabled;
    }

    function _onlyWhitelistedChain(uint64 _destinationChainSelector) private view {
        if (!whitelistedChains[_destinationChainSelector])
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert OnlyOwner();
    }
}
