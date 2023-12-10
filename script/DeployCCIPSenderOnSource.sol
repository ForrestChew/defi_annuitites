// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "../src/External/CCIP/CCIP_LiquiditySender.sol";
import "../test/utils/GlobalTestVariables.t.sol";

contract DeployCCIPSenderOnSource is Script, GlobalTestVariables {
    CCIP_LiquiditySender liquiditySender;

    function run() external {
        address DEV_ADDRESS = 0x42A7b811d096Cba5b3bbf346361106bDe275C8d7;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");

        vm.startBroadcast(deployerPrivateKey);

        liquiditySender = new CCIP_LiquiditySender(
            CCIP_ROUTER_AVAX_FUJI,
            LINK_AVAX_FUJI,
            DEV_ADDRESS
        );

        liquiditySender.setChainAllowlist(SEPOLIA_CHAIN_SELECTOR, true);

        IERC20(LINK_AVAX_FUJI).transfer(
            address(liquiditySender),
            2 * 10 ** LINK_DECIMALS
        );

        vm.stopBroadcast();
    }
}
