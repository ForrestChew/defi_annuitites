## Summary
Defi Annuities allows for lending and borrowing on any non-rebasing ERC-20 token (including taxable tokens) whereby lenders can dictate fixed-term/fixed-rate loan terms, and  borrowers can pay for loans out of their deposited collateral. Borrower's loan tenor is potentially infinite, with interest payments being deducted from their deposited collateral, exchanged for the lend asset on Uniswap and sent to the lender. The amount of interest due is calculated as a linear function of time which accumulates under the hood until a collect interest invocation is triggered. Borrowers can additionally initiate a borrow Tx from Avax-Fuji -> Ethereum Sepolia where the protocol is deployed. Furthermore, the protocol features a 1:many lender to borrower relationship whereby lenders can set the following immutable loan terms, and any amount of borrowers can borrow until all seeded lend assets have been depleted from the pool.

1) **Lend Token** - The token the lender wishes to lend out. 

2) **Collateral Token** - The token the lender wishes to accept as collateral from borrowers. 

3) **APR** - Amount of interest owed to lender by borrowers. 

4) **LTV** - Max borrow power on deposited collateral.

Once the terms have been set and the pool has been deployed, the lender has four different actions they can perform on the deployed pool: 

1) **Deposit** - Lenders can deposit the specified lend asset at any point in time for borrowers to borrow.

2) **Withdraw** - Lenders can withdraw unborrowed lend assets from their pool.

3) **Pause Borrowing** - Lenders can pause borrowing in the pool (does not effect repayments in anyway).

4) **Collect Interest** - As interest payments are generated based on the total amount of collateral in the pool and accrue linearly over time, lenders have the flexibility to invoke a `collectInterest` function at any point. This function calculates the amount of interest (in the lend asset) owed to the lender at the specific moment the `collectInterest` function is called. Since the interest payment is deducted from the deposited collateral but calculated in the lend asset, the precise amount of collateral required to cover the calculated interest owed to the lender is externally swapped on Uniswap for the lend asset. Subsequently, the amount received from the swap is sent back to the lender, ensuring that the lender receives interest payments in the lend asset.

Once a pool is deployed, borrower's have three actions they can take:

1) **Borrow** - Borrowers can deposit collateral to receive a loan.

2) **Repay** - Borrowers can repay entire loan principal to unlock their share of collateral (`initialCollateral - interestPayments`).

3) **Self Liquidate** - Allows the borrower to forfeit 90% of their remaining collateral to the lender at the time the `liquidateSelf` function is called. 100% of that collateral is swapped on Uniswap for the lend asset and 10% is sent back to the borrower with the remaining 90% being sent to the lender. This functionality was added as an incentivization for the borrower to manually close their position in cases where loans are underwater so the lender doesn't have to wait a potentially long time to recover all collateral. There are two instances where correct usage of this functionality should be employed.

- Given the fact that interest payments are subtracted from borrowers deposited collateral in a linear manner, there comes a time where borrowers are financially incentivized to **not** repay their loan, as the amount of collateral they could unlock is worth less than the actual value of their principal.
- Over time, the dollar value of their deposited collateral becomes worth less than the value of their principal loan.

## How It's Built
Solidity in a Foundry environment where annuity pools are deployed as minimal proxies leveraging Openzepplin's implementation of ERC-1167. Moreover, the collateral for lend asset interest swapping mechanism is deployed as an independent smart contract and is designed to set a standard interface by which any DEX can be used for swapping. This is due to security concerns whereby the external DEX being used has an issue out of Defi Annuities control.

Additionally, since there can be `k` number of borrowers per pool, I was initially concerned that collecting interest could only be accomplished in `O(n)` time complexity, but later came to the conclusion that, since the pool's APR will always be constant per pool, and is accumulated for the lender in a linear manner, the interest payment amount can be taken from the entire amount of deposited collateral, and not on an individual borrower basis. Then, when a borrower repays their debt, they will be able to claim their portion of the entire remaining collateral. 
