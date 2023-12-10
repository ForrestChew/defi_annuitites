// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import "../test/utils/GlobalTestVariables.t.sol";
import "../src/Oracle.sol";

interface ILnM {
    function drip(address to) external;
}

contract DripCCIP_LnM is Script, GlobalTestVariables {
    address DEV_ADDRESS = 0x42A7b811d096Cba5b3bbf346361106bDe275C8d7;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV_TWO");

        ILnM lnM = ILnM(CCIP_LnM);
        
        vm.startBroadcast(deployerPrivateKey);

        for (uint256 i = 0; i < 100; i++) {
            lnM.drip(DEV_ADDRESS);
        }

        vm.stopBroadcast();
    }
}
