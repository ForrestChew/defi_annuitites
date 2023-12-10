//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.22;

interface IAnnuityFactory {
    function isPool(address) external view returns (bool);
}
