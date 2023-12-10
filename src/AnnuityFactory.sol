//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IAnnuityPosTracker.sol";
import "./interfaces/IAnnuity.sol";
import "./interfaces/IERC20.sol";

// --- Events --- \\
event CreateAnnuity(address creator, address annuity);

// --- Errors --- \\
error TokenNotWhitelisted();
error InvalidLtv();
error OnlyOwner();

contract AnnuityFactory {
    address public owner;
    address public swapper;
    address public annuityTracker;
    address public annuityImpl;
    address public oracle;

    mapping(address token => bool enabled) public isWhitelisted;
    mapping(address pool => bool exists) public isPool;


    /**
     * @notice                - Sets up initial contract storage variables.
     * @param _owner          - Admin for factory contract.
     * @param _annuityImpl    - Implementation address for annuity proxies.
     * @param _oracle         - Address of protocol oracle smart contract.
     * @param _swapper        - Address of protocol external DEX swapper.
     * @param _annuityTracker - Address of protocol tracker for lender and borrower positions.
     */
    constructor(
        address _owner, 
        address _annuityImpl, 
        address _oracle,
        address _swapper,
        address _annuityTracker
    ) {
        owner = _owner;
        annuityImpl = _annuityImpl;
        oracle = _oracle;
        swapper = _swapper;
        annuityTracker = _annuityTracker;
    }

    /**
     * @notice            - Deploys an annuity as a minimal proxy. The owner (lender) of the deployed annuity is the 
     *                      function invoker.
     * @param _colToken   - Address of token that borrowers are allowed to use as collateral.
     * @param _lendToken  - Address of token lender wishes to lend out to borrowers.
     * @param _apr        - Amount of interest lender wishes to charge borrowers on loan.
     * @param _ltv        - Max borrowing power on collateral.
     * @param _depositAmt - Amount of lend assets lender wishes to seed annuity with in same Tx as pool creation.
     *                      This number can be 0, as funds can always be added at a later time.
     */
    function createAnnuity(
        address _colToken, 
        address _lendToken,
        uint48 _apr,
        uint48 _ltv,
        uint256 _depositAmt
    ) external returns (address) {
        if (!isWhitelisted[_colToken] || !isWhitelisted[_lendToken]) 
            revert TokenNotWhitelisted();
        if (_ltv == 0) revert InvalidLtv();

        address annuityAddress = Clones.clone(annuityImpl);
        IAnnuity newAnnuity = IAnnuity(annuityAddress);

        newAnnuity.initialize(msg.sender, _colToken, _lendToken, oracle, swapper, annuityTracker, _apr, _ltv);
        
        isPool[annuityAddress] = true;
        IAnnuityPosTracker(annuityTracker).createLendPosition(annuityAddress, msg.sender);

        if (_depositAmt > 0) { 
            IERC20 lendToken = IERC20(_lendToken);
            uint256 initBal = lendToken.balanceOf(address(this));
            lendToken.transferFrom(msg.sender, address(this), _depositAmt);
            uint256 amtReceived = lendToken.balanceOf(address(this)) - initBal;
            lendToken.approve(address(newAnnuity), amtReceived);
            newAnnuity.deposit(amtReceived);
        }
        
        emit CreateAnnuity(msg.sender, annuityAddress);
        return annuityAddress;
    }

    /**
     * @notice               - Allows the factory contract owner to allow tokens to be used as 
     *                         lend or collateral assets.
     * @param _token         - Address of token to be allowed usage within protocol.
     * @param _isWhitelisted - Denotes whether provided token should be allowed or disallowed.
     */
    function whitelistToken(address _token, bool _isWhitelisted) external {
        _onlyOwner();
        isWhitelisted[_token] = _isWhitelisted;
    }

    /**
     * @notice - Allows the factory contract owner to set the protocol oracle address.
     * @param _oracle - Address of protocol oracle smart contract.
     */
    function setOracle(address _oracle) external {
        _onlyOwner();
        oracle = _oracle;
    }

    /**
     * @notice - Allows the factory contract owner to set the protocol external DEX swapper address.
     * @param _swapper - Address of protocol external DEX swapper.
     */
    function setSwapper(address _swapper) external {
        _onlyOwner();
        swapper = _swapper;
    }

    /**
     * @notice - Allows the factory contract owner to set the protocol tracker for lender and borrower positions.
     * @param _annuityTracker - Address of protocol tracker for lender and borrower positions.
     */
    function setAnnuityTracker(address _annuityTracker) external {
        _onlyOwner();
        annuityTracker = _annuityTracker;
    }

    /**
     * @notice - Allows the factory contract owner to set the protocol annuity implementation address.
     * @param _annuityImpl - Address of protocol annuity implementation.
     */
    function setAnnuityImpl(address _annuityImpl) external {
        _onlyOwner();
        annuityImpl = _annuityImpl;
    }

    /**
     * @notice - Modifier that validates function invoker is the factory contract owner.
     */
    function _onlyOwner() private view {
        if (msg.sender != owner) revert OnlyOwner();
    }
}