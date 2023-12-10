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
import "../mocks/MockCCIP_LiquidityReceiver.sol";

abstract contract FullProtocolSetupLocal is GlobalTestVariables {
    // Deploy Tokens
    MockToken weth = new MockToken("Weth", "weth", 18, DEPLOYER, WETH_DECIMALS);
    MockToken usdc = new MockToken("USDC", "USDC", 6, DEPLOYER, USDC_DECIMALS);
    MockToken ccipBnm =
        new MockToken("CCIP-BnM", "CCIP-BnM", 18, DEPLOYER, CCIP_BnM_DECIMALS);
    MockToken ccipLnm =
        new MockToken("CCIP-LnM", "CCIP-LnM", 18, DEPLOYER, CCIP_LnM_DECIMALS);

    MockCCIP_LiquidityReceiver ccipReceiver = new MockCCIP_LiquidityReceiver();

    // Deploy Mock Swap Router
    MockSwapRouter swapRouter = new MockSwapRouter();

    // Deploy Annuity Protocol
    Annuity annuityImpl = new Annuity();
    AnnuityPosTracker annuityTracker = new AnnuityPosTracker(DEPLOYER);
    MockOracle oracle = new MockOracle();
    Swapper swapper =
        new Swapper(ISwapRouter(address(swapRouter)), "Uniswap as Swapper");
    AnnuityFactory annuityFactory =
        new AnnuityFactory(
            DEPLOYER,
            address(annuityImpl),
            address(oracle),
            address(swapper),
            address(annuityTracker)
        );
}
