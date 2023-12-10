// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../src/AnnuityFactory.sol";
import {Annuity} from "../src/Annuity/Annuity.sol";
import {AnnuityPosTracker} from "../src/AnnuityPosTracker.sol";
import {Swapper} from "../src/External/Swapper.sol";
import {Oracle} from "../src/Oracle.sol";
import "../src/External/CCIP/CCIP_LiquidityReceiver.sol";
import "../test/utils/GlobalTestVariables.t.sol";

contract DeployProtocol is Script, GlobalTestVariables {
    ISwapRouter swapRouter = ISwapRouter(UNISWAP_ROUTER_SEPOLIA);

    Annuity annuityImpl;
    AnnuityPosTracker annuityTracker;
    Oracle oracle;
    Swapper swapper;
    AnnuityFactory annuityFactory;
    CCIP_LiquidityReceiver liquidityReceiver;

    function run() external {
        address DEV_ADDRESS = 0x42A7b811d096Cba5b3bbf346361106bDe275C8d7;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        vm.startBroadcast(deployerPrivateKey);

        liquidityReceiver = new CCIP_LiquidityReceiver(CCIP_ROUTER_SEPOLIA);
        liquidityReceiver.setChainAllowlist(AVAX_FUJI_CHAIN_SELECTOR, true);

        // The CCIP_LiquiditySender must be deployed first so that it's address can be whitelisted
        liquidityReceiver.setSenderAllowlist(CCIP_LIQUIDITY_SENDER, true);

        annuityTracker = new AnnuityPosTracker(DEV_ADDRESS);
        (
            address[] memory tokens,
            address[] memory feeds
        ) = _getOracleConstructorParams();
        oracle = new Oracle(tokens, feeds, DEV_ADDRESS);
        
        oracle.addFeed(USDC_SEPOLIA, USDC_USD_PRICE_FEED_SEPOLIA);
        oracle.addFeed(WETH_SEPOLIA, ETH_USD_PRICE_FEED_SEPOLIA);
        oracle.addFeed(CCIP_BnM, CCIP_BnM_PRICE_FEED_SEPOLIA);
        oracle.addFeed(CCIP_LnM, CCIP_LnM_PRICE_FEED_SEPOLIA);

        swapper = new Swapper(
            ISwapRouter(UNISWAP_ROUTER_SEPOLIA),
            "Uniswap_V3 Swapper"
        );

        annuityImpl = new Annuity();

        annuityFactory = new AnnuityFactory(
            DEV_ADDRESS,
            address(annuityImpl),
            address(oracle),
            address(swapper),
            address(annuityTracker)
        );

        annuityTracker.setFactory(address(annuityFactory));

        annuityFactory.whitelistToken(USDC_SEPOLIA, true);
        annuityFactory.whitelistToken(WETH_SEPOLIA, true);
        annuityFactory.whitelistToken(CCIP_BnM, true);
        annuityFactory.whitelistToken(CCIP_LnM, true);

        vm.stopBroadcast();
    }

    function _getOracleConstructorParams()
        private
        pure
        returns (address[] memory, address[] memory)
    {
        address[] memory tokens = new address[](4);
        tokens[0] = USDC_SEPOLIA;
        tokens[1] = WETH_SEPOLIA;
        tokens[2] = CCIP_BnM;
        tokens[3] = CCIP_LnM;

        address[] memory feeds = new address[](4);
        tokens[0] = USDC_USD_PRICE_FEED_SEPOLIA;
        tokens[1] = ETH_USD_PRICE_FEED_SEPOLIA;
        tokens[2] = CCIP_BnM_PRICE_FEED_SEPOLIA;
        tokens[3] = CCIP_LnM_PRICE_FEED_SEPOLIA;

        return (tokens, feeds);
    }
}
