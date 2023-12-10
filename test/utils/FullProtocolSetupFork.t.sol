//SPDX-License-Identifier: -
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./GlobalTestVariables.t.sol";
import "../../src/AnnuityFactory.sol";
import {Annuity} from "../../src/Annuity/Annuity.sol";
import {AnnuityPosTracker} from "../../src/AnnuityPosTracker.sol";
import {Swapper} from "../../src/External/Swapper.sol";
import "./GlobalTestVariables.t.sol";
import "../mocks/MockSwapRouter.sol";
import "../mocks/MockToken.sol";
import "../mocks/MockOracle.sol";

contract FullProtocolSetupFork is Test, GlobalTestVariables {
    MockToken weth = MockToken(WETH_SEPOLIA);
    MockToken usdc = MockToken(USDC_SEPOLIA);

    ISwapRouter swapRouter = ISwapRouter(UNISWAP_ROUTER_SEPOLIA);

    Annuity annuityImpl;
    AnnuityPosTracker annuityTracker;
    MockOracle oracle;
    Swapper swapper;
    AnnuityFactory annuityFactory;

    function deployProtocol() internal {
        annuityImpl = new Annuity();
        annuityTracker = new AnnuityPosTracker(DEPLOYER);

        // As the price feeds are largely just returning a number, getting
        // historical round data was not necessary for these purposes.
        oracle = new MockOracle();
        oracle.setTokenPrice(address(weth), WETH_PRICE_RAW_2050);
        oracle.setTokenPrice(address(usdc), USDC_PRICE_RAW_1);

        swapper = new Swapper(
            ISwapRouter(address(swapRouter)),
            "Uniswap_V3 Swapper"
        );

        annuityFactory = new AnnuityFactory(
            DEPLOYER,
            address(annuityImpl),
            address(oracle),
            address(swapper),
            address(annuityTracker)
        );
    }
}
