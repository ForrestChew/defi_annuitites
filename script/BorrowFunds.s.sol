// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Annuity} from "../src/Annuity/Annuity.sol";
import "../test/utils/GlobalTestVariables.t.sol";

contract BorrowFunds is Script, GlobalTestVariables {

    Annuity annuity;

    function run() external {
        address ANNUITY = 0x69e868CC70CF0b9499BF090E372891A2A78E05f4;
        address DEV_ADDRESS = 0x42A7b811d096Cba5b3bbf346361106bDe275C8d7;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");

        vm.startBroadcast(deployerPrivateKey);

        annuity = Annuity(ANNUITY);

        IERC20(WETH_SEPOLIA).approve(
            address(annuity),
            WETH_1
        );

        annuity.borrow(WETH_1, DEV_ADDRESS);

        vm.stopBroadcast();
    }
}
