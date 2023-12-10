// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "../test/utils/GlobalTestVariables.t.sol";
import "../src/Oracle.sol";

contract DeployCCIPSenderOnSource is Script, GlobalTestVariables {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");
        Oracle oracle;
        
        vm.startBroadcast(deployerPrivateKey);

        oracle = Oracle(ORACLE);

        oracle.addFeed(USDC_SEPOLIA, USDC_USD_PRICE_FEED_SEPOLIA);
        oracle.addFeed(WETH_SEPOLIA, ETH_USD_PRICE_FEED_SEPOLIA);
        oracle.addFeed(CCIP_BnM, CCIP_BnM_PRICE_FEED_SEPOLIA);
        oracle.addFeed(CCIP_LnM, CCIP_LnM_PRICE_FEED_SEPOLIA);

        vm.stopBroadcast();
    }
}
