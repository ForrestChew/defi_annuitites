//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

import "./interfaces/IAnnuityFactory.sol";

// --- Errors --- \\
error OnlyFactory();
error NotPool();
error OnlyOwner();

/**
 * @notice - This contract is used to track the positions of lenders and borrowers in the protocol. 
 *           Although an additional subgraph is being used to keep track of all pools to display on the UI,
 *           the existence of this contract is necessary for instant display upon pool deployment as 
 *           subgraphs often take several minutes to index the new events, ultimitly leading to poorer UX.
 * 
 *           This tracking contract is implemented as a doubly linked list (DLL) to allow for O(1) time 
 *           complexity for adding and removing positions. DLLs also make destroying positions cheaper
 *           than alternative array solutions when dealing with custom structs, as only node pointers
 *           need to be updated and target node deleted, rather than swapping an entire struct
 *           with the last element in the array and then popping the last element. Furthermore,
 *           the DLL implementation guarentees a sequencial order of nodes, which is why something
 *           like OpenZeppelin's EnumerableSet or Map is not used.
 */
contract AnnuityPosTracker {
    address immutable owner;
    IAnnuityFactory public factory;

    struct PositionNode {
        address pool;
        address next;
        address prev;
    }

    mapping(address lender => uint256) public lendPosCount;
    mapping(address lender => address poolAddress) public firstLendPosStartId; // The ID of the first Node in the DLL.
    mapping(address lendPositionId => PositionNode) public lendPositions; // Store of all Nodes in the DLL.

    mapping(address borrower => uint256) public borrowPosCount;
    mapping(address borrower => address poolAddress) public firstBorrowPosId;
    mapping(address borrower => PositionNode) public borrowPositions;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @notice        - Creates a new lend position node and adds it to the DLL.
     * @param _pool   - Address of the pool from which this Tx is initiated.
     * @param _lender - Address of the lender.
     */
    function createLendPosition(address _pool, address _lender) external {
        if (msg.sender != address(factory)) revert OnlyFactory();

        PositionNode memory newLendPos = _createPositionNode(_pool);

        address startPosId = firstLendPosStartId[_lender];

        if (startPosId == address(0)) {
            lendPositions[newLendPos.pool] = newLendPos;
            firstLendPosStartId[_lender] = newLendPos.pool;
            lendPosCount[_lender]++;
        } else {
            lendPositions[startPosId].prev = newLendPos.pool;
            lendPositions[newLendPos.pool] = newLendPos;
            lendPositions[newLendPos.pool].next = startPosId;
            firstLendPosStartId[_lender] = newLendPos.pool;
            lendPosCount[_lender]++;
        }
    }

    /**
     * @notice        - Destroys a lend position node and removes it from the DLL.
     * @param _pool   - Address of the pool from which this Tx is initiated.
     * @param _lender - Address of the lender.
     */
    function destroyLendPosition(address _pool, address _lender) external {
        if (!factory.isPool(_pool)) revert NotPool();

        PositionNode storage targetPos = lendPositions[_pool];

        lendPositions[targetPos.prev].next = targetPos.next;
        lendPositions[targetPos.next].prev = targetPos.prev;
        lendPosCount[_lender]--;
        delete lendPositions[targetPos.pool];
    }

    /**
     * @notice        - Creates a new borrow position node and adds it to the DLL.
     * @param _pool   - Address of the pool from which this Tx is initiated.
     * @param _borrower - Address of the borrower.
     */
    function createBorrowPosition(address _pool, address _borrower) external {
        if (!factory.isPool(_pool)) revert NotPool();

        PositionNode memory newBorrowPos = _createPositionNode(_pool);

        address startPosId = firstLendPosStartId[_borrower];

        if (startPosId == address(0)) {
            borrowPositions[newBorrowPos.pool] = newBorrowPos;
            firstBorrowPosId[_borrower] = newBorrowPos.pool;
            borrowPosCount[_borrower]++;
        } else {
            borrowPositions[startPosId].prev = newBorrowPos.pool;
            borrowPositions[newBorrowPos.pool] = newBorrowPos;
            borrowPositions[newBorrowPos.pool].next = startPosId;
            firstBorrowPosId[_borrower] = newBorrowPos.pool;
            borrowPosCount[_borrower]++;
        }
    }

    /**
     * @notice        - Destroys a borrow position node and removes it from the DLL.
     * @param _pool   - Address of the pool from which this Tx is initiated.
     * @param _borrower - Address of the borrower.
     */
    function destroyBorrowPosition(address _pool, address _borrower) external {
        if (!factory.isPool(_pool)) revert NotPool();

        PositionNode storage targetPos = borrowPositions[_pool];

        borrowPositions[targetPos.prev].next = targetPos.next;
        borrowPositions[targetPos.next].prev = targetPos.prev;
        borrowPosCount[_borrower]--;
        delete borrowPositions[targetPos.pool];
    }

    /**
     * @notice        - Creates a new position node.
     * @param _pool   - Address of the pool to which this position will be set.
     */
    function _createPositionNode(
        address _pool
    ) private pure returns (PositionNode memory) {
        return (
            PositionNode({
                pool: address(_pool),
                next: address(0),
                prev: address(0)
            })
        );
    }

    function setFactory(address _factory) external {
        if (msg.sender != owner) revert OnlyOwner();
        factory = IAnnuityFactory(_factory);
    }
}
