//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAnnuityPosTracker.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IAnnuity.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IOracle.sol";
import {AnnuityUtils} from "./AnnuityUtils.sol";
import "forge-std/console.sol";

event Deposit(uint256 amtReceived);
event Withdrawl(uint256 amtWithdrawn);
event Borrow(address borrower, uint256 colDeposited, uint256 principal);
event InterestCollected(uint256 interestCollected, uint256 colAmtSwapped);
event Repay(address lender, uint256 colAmtReturned, uint256 principalRepaid);
event LiquidateSelf(address borrower, uint256 colLiquidated, uint256 lendAssetAmtForBorrower, uint256 lendAssetAmtForLender);

error OnlyLender();
error CannotBeZero();
error InsufficientLiquidity();
error InvalidRepayAmt();
error NoDebt();
error BorrowingPaused();

contract Annuity is Initializable, ReentrancyGuard {
    address lender;
    address colToken;
    address lendToken;
    uint48 ltv;
    uint48 apr;

    bool public isBorrowingPaused;
    uint256 public totalBorrowedAmt;
    uint256 public totalCollateralDeposited;
    uint256 private _interestAccumStart;

    IOracle public oracle; 
    ISwapper public swapper;
    IAnnuityPosTracker public annuityTracker;

    mapping(address borrower => uint256 principal) public principals;

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice                    - Initializes the annuity pool with the following parameters
     * @param _lender             - Address of lender.
     * @param _colToken           - Address of collateral token.
     * @param _lendToken          - Address of lend token.
     * @param _oracle             - Address of protocol oracle.
     * @param _swapperAddr        - Address of protocol external DEX swapper.
     * @param _annuityTrackerAddr - Address of protocol tracker for lender and borrower positions.
     * @param _apr                - Amount of interest lender wishes to charge borrowers on loan.
     * @param _ltv                - Max borrowing power on collateral.
     * @dev                       - This function is called by the AnnuityFactory contract when creating a new pool.
     */
    function initialize(
        address _lender,
        address _colToken,
        address _lendToken,
        address _oracle,
        address _swapperAddr,
        address _annuityTrackerAddr,
        uint48 _apr,
        uint48 _ltv
    ) external initializer {
        lender = _lender;
        colToken = _colToken;
        lendToken = _lendToken;
        oracle = IOracle(_oracle);
        swapper = ISwapper(_swapperAddr);
        annuityTracker = IAnnuityPosTracker(_annuityTrackerAddr);
        apr = _apr;
        ltv = _ltv;
    }

    /**
     * @notice     - Allows the lender to deposit lend assets into the annuity (pool).
     * @param _amt - Amount of lend assets the lender wishes to deposit.
     */
    function deposit(uint256 _amt) external {
        /// @dev "amtReceived" may be less than "_amt" in cases where taxable tokens are being used,
        ///       and so we would like to emit the actual amount of tokens the pool recieves.
        uint256 amtReceived = _safeTransferFrom(lendToken, msg.sender, _amt);

        emit Deposit(amtReceived);
    }

    /**
     * @notice     - Allows the lender to withdraw unborrowed lend assets from the annuity (pool).
     * @param _amt - Amount of lend assets the lender wishes to withdraw.
     */
    function withdraw(uint256 _amt) external {
        _onlyLender();
        _safeTransfer(lendToken, lender, _amt);

        emit Withdrawl(_amt);
    }

    /**
     * @notice          - Allows borrowers to deposit collateral into the pool and borrow lend assets.
     * @param _colAmt   - Amount of collateral the borrower wishes to deposit.
     * @param _borrower - Address that will recieve the lend asset.
     */
    function borrow(uint256 _colAmt, address _borrower) external nonReentrant {
        if (isBorrowingPaused) revert BorrowingPaused();
        if (_colAmt == 0) revert CannotBeZero();

        uint256 colAmtReceived = _safeTransferFrom(
            colToken,
            msg.sender,
            _colAmt
        );
        uint256 principalLoanAmt = AnnuityUtils.calculatePrincipal(
            colAmtReceived,
            ltv,
            IERC20(colToken),
            IERC20(lendToken),
            oracle
        );

        if (principalLoanAmt > IERC20(lendToken).balanceOf(address(this)))
            revert InsufficientLiquidity();
        if (principals[_borrower] == 0)
            annuityTracker.createBorrowPosition(address(this), _borrower);
        if (_interestAccumStart == 0) _interestAccumStart = block.timestamp;

        principals[_borrower] += principalLoanAmt;
        totalBorrowedAmt += principalLoanAmt;
        totalCollateralDeposited += colAmtReceived;

        _safeTransfer(lendToken, _borrower, principalLoanAmt);
        
        emit Borrow(_borrower, colAmtReceived, principalLoanAmt);
    }

    /**
     * @notice - Allows lender to collect interest from deposited collateral as a linear function
     *           of time - from block.timestamp. The amount of collateral needed will 
     *           be swapped on an external DEX for the pools lend asset. That amount is then
     *           sent to the lender.
     */
    function collectInterest() external {
        _onlyLender();

        (uint256 exactLendInterestAmt, uint256 maxColToSpend) = _calculateInterestSwapDetails();
        uint256 colAmtSwappedForLendInterest = _swapCollateralForInterest(
            exactLendInterestAmt,
            maxColToSpend
        );

        totalCollateralDeposited -= colAmtSwappedForLendInterest;
        _interestAccumStart = block.timestamp;

        emit InterestCollected(
            exactLendInterestAmt,
            colAmtSwappedForLendInterest
        );
    }

    /**
     * @notice              - Allows borrower to repay their principal loan. The amount of interest owed
     *                        to pool lender will be automatically claimed at this moment in time, 
     *                        and the borrower's position will be destroyed.
     * @param _principalAmt - The exact principal loan amount that the borrower owes. 
     */
    function repay(uint256 _principalAmt) external nonReentrant {
        uint256 borrowerPrincipal = principals[msg.sender];

        if (borrowerPrincipal == 0) revert NoDebt();
        if (_principalAmt != borrowerPrincipal) revert InvalidRepayAmt();
       
        (uint256 exactLendInterestAmt, uint256 maxColToSpend) = _calculateInterestSwapDetails();
        uint256 colUsedForSwap = _swapCollateralForInterest(
            exactLendInterestAmt,
            maxColToSpend
        );
        uint256 borrowersColShareAmt = ((totalCollateralDeposited - colUsedForSwap) * _principalAmt) / totalBorrowedAmt;
        
        totalCollateralDeposited -= borrowersColShareAmt + colUsedForSwap;
        totalBorrowedAmt -= _principalAmt;
        _interestAccumStart = block.timestamp;
        delete principals[msg.sender];

        annuityTracker.destroyBorrowPosition(address(this), msg.sender);

        _safeTransferFrom(lendToken, msg.sender, _principalAmt);
        _safeTransfer(colToken, msg.sender, borrowersColShareAmt);
      
        emit Repay(msg.sender, borrowersColShareAmt, _principalAmt);
        emit InterestCollected(
            exactLendInterestAmt,
            colUsedForSwap
        );
    }

    /**
     * @notice - Allows borrowers to initiate a liquidation on themselves. Correct usage of this function
     *           sees borrowers invoking it if and only if the value of their loan exceeds the value
     *           of their deposited collateral. In otherwords, the LTV of the pool has surpassed 100%. 
     *           Once called, the borrowers share in collateral will be swapped in its entirety for the 
     *           lend asset. 10% of that will be sent to the self liquidating borrower, with the rest 
     *           being sent to the lender. In essense, this function exists as a way for lenders to recoup 
     *           remaining assets when the loan is underwater.
     */
    function liquidateSelf() external {
        uint256 borrowerPrincipal = principals[msg.sender];

        if (borrowerPrincipal == 0) revert NoDebt();

        uint256 borrowersColShareAmt = (totalCollateralDeposited *
            borrowerPrincipal) / totalBorrowedAmt;

        IERC20(colToken).approve(address(swapper), borrowersColShareAmt);

        uint256 lendAssetOut = swapper.swapPositionCollateralForLendAsset(
            borrowersColShareAmt,
            lendToken,
            colToken
        );

        totalBorrowedAmt -= borrowerPrincipal; 
        totalCollateralDeposited -= borrowersColShareAmt;
        delete principals[msg.sender];

        uint256 borrowerLendAssetShare = (lendAssetOut * 100_000) /
            AnnuityUtils.HUNDRED_PERCENT;
        uint256 lenderLendAssetShare = lendAssetOut - borrowerLendAssetShare;

        annuityTracker.destroyBorrowPosition(address(this), msg.sender);

        _safeTransfer(lendToken, msg.sender, borrowerLendAssetShare);
        _safeTransfer(lendToken, lender, lenderLendAssetShare);

        emit LiquidateSelf(
            msg.sender,
            borrowersColShareAmt,
            borrowerLendAssetShare,
            lenderLendAssetShare
        );
    }

    /**
     * @notice                          - Initiates a call to the Swapper smart contract that swaps 
     *                                    required amount of collateral for exact lend interest owed
     *                                    to the lender.
     * @param _lendAssetAmtToSwapFor    - The exact amount of lend interest owed to the lender  
     *                                    in the lend asset.
     * @param _maxColAmtIn              - The max amount of collateral to be used to swap for the
     *                                    required amount of lend assets.
     * @return collateralAmtUsedForSwap - The Actual amount of collateral used in swap.
     */
    function _swapCollateralForInterest(
        uint256 _lendAssetAmtToSwapFor,
        uint256 _maxColAmtIn
    ) private returns (uint256 collateralAmtUsedForSwap) {
        uint256 maxSpend = _maxColAmtIn * 3 + 100e9;

        IERC20(colToken).approve(address(swapper), maxSpend);
        
        return
            swapper.swapCollateralForLendAssetInterest(
                _lendAssetAmtToSwapFor,
                maxSpend, 
                lendToken,
                colToken,
                lender
            );
    }

    /**
     * @notice - Calculates the exact amount of interest owed to a lender and the maximum
     *           amount of collateral to be used for the swap to lend assets at the
     *           present moment in time.
     * @return exactLendInterestAmt - Exact amount of interest owed to lender in lend assets.
     * @return maxColToSpend - The max amount of collateral to spend on swap. 
     */
    function _calculateInterestSwapDetails() private returns (
        uint256 exactLendInterestAmt, 
        uint256 maxColToSpend
    ) {
        exactLendInterestAmt = AnnuityUtils
            .calculateLendInterestAmt(
            totalBorrowedAmt,
            _interestAccumStart,
            apr
        );
        maxColToSpend = AnnuityUtils.calculateMaxColForInterest(
            exactLendInterestAmt,
            IERC20(colToken),
            IERC20(lendToken),
            oracle
        );

        return (exactLendInterestAmt, maxColToSpend);
    }

    /// @notice - Returns the actual amount transfered. Required when taxable tokens are being used.
    function _safeTransferFrom(
        address _token,
        address _from,
        uint256 _amt
    ) private returns (uint256 amtReceived) {
        if (_amt == 0) revert CannotBeZero();
        IERC20 token = IERC20(_token);
        uint256 initBal = token.balanceOf(address(this));
        token.transferFrom(_from, address(this), _amt);
        amtReceived = token.balanceOf(address(this)) - initBal;
    }

    function _safeTransfer(address _token, address _to, uint256 _amt) private {
        if (_amt == 0) revert CannotBeZero();
        IERC20 token = IERC20(_token);
        token.transfer(_to, _amt);
    }

    function setPauseBorrowing(bool _isPaused) external {
        _onlyLender();
        isBorrowingPaused = _isPaused;
    }

    function getPoolOptions()
        external
        view
        returns (address, address, address, uint48, uint48)
    {
        return (lender, address(colToken), address(lendToken), apr, ltv);
    }

    function _onlyLender() private view {
        if (msg.sender != lender) revert OnlyLender();
    }
}
