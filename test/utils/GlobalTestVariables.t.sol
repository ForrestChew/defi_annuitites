//SPDX-License-Identifier: -
pragma solidity 0.8.22;

abstract contract GlobalTestVariables {
    address constant DEPLOYER = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address constant USER_A = address(1234);
    address constant USER_B = address(2);
    address constant USER_C = address(3);
    address constant USER_D = address(4);

    uint48 constant ONE_YEAR_IN_SECONDS = 31_536_000;

    uint48 constant HUNDRED_PERCENT = 100_0000;
    uint48 constant BPS8000 = 800_000;
    uint48 constant BPS500 = 500_00;
    uint48 constant BPS100 = 100_00;

    uint256 constant TOKEN_RATIO_1000 = 1000e18;

    uint8 constant ZERO = 0;
    uint256 constant USDC_3280 = 3280e6;
    uint256 constant USDC_1640 = 1640e6;
    uint256 constant USDC_1600 = 1600e6;
    uint256 constant USDC_1000 = 1000e6;
    uint256 constant USDC_800 = 800e6;
    uint256 constant USDC_200 = 200e6;
    uint256 constant USDC_80 = 80e6;

    uint256 constant WETH_5 = 5e18;
    uint256 constant WETH_2 = 2e18;
    uint256 constant WETH_1 = 1e18;

    uint256 constant CCIP_BnM_1000 = 1000e18;
    uint256 constant CCIP_BnM_800 = 800e18;
    uint256 constant CCIP_BnM_80 = 80e18;

    uint256 constant CCIP_LnM_1 = 1e18;

    uint8 constant LINK_DECIMALS = 18;
    uint8 constant CCIP_BnM_DECIMALS = 18;
    uint8 constant CCIP_LnM_DECIMALS = 18;
    uint8 constant WETH_DECIMALS = 18;
    uint8 constant USDC_DECIMALS = 6;

    uint256 constant NOV_13_2023 = 4688024;
    uint256 constant NOV_11_2023 = 4677304;

    // Return from Mock Oracle
    int256 constant WETH_PRICE_RAW_2050 = 2050_00000000;
    int256 constant WETH_PRICE_RAW_1000 = 1000_00000000;
    int256 constant USDC_PRICE_RAW_1 = 1_00000000;
    int256 constant CCIP_BnM_PRICE_RAW_1 = 1_00000000;
    int256 constant CCIP_LnM_PRICE_RAW_100 = 100_00000000;

    address constant UNISWAP_ROUTER_SEPOLIA =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    address constant CCIP_ROUTER_SEPOLIA =
        0xD0daae2231E9CB96b94C8512223533293C3693Bf;

    address constant CCIP_ROUTER_AVAX_FUJI =
        0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;

    // ERC20s Sepolia
    address constant USDC_SEPOLIA = 0x674f92e56A25E5A259A6B28678116b8821BAEe73;
    address constant WETH_SEPOLIA = 0xad6a57C7150D78Cb92b0a17Ed2fbC2D35Bf5E8f3;
    address constant CCIP_BnM = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant CCIP_LnM = 0x466D489b6d36E7E3b824ef491C225F5830E81cC1;

    // ERC20s Avax Fuji
    address constant LINK_AVAX_FUJI =
        0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;

    // Price Feeds
    address constant USDC_USD_PRICE_FEED_SEPOLIA =
        0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    address constant ETH_USD_PRICE_FEED_SEPOLIA =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    // As CCIP testnet tokens do not have price feeds, we are using other ERC20 price
    // feeds as a mock price for DAI -> CCIP-BnM & FORTH -> CCIP-LnM respectivly.
    // This approach should only be used on testnets.
    address constant CCIP_BnM_PRICE_FEED_SEPOLIA =
        0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
    address constant CCIP_LnM_PRICE_FEED_SEPOLIA =
        0x070bF128E88A4520b3EfA65AB1e4Eb6F0F9E6632;

    uint64 constant AVAX_FUJI_CHAIN_SELECTOR = 14767482510784806043;
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    address constant ORACLE = 0x7EfBea75A5d6B6e01660938a37a4e06b35A94d07;

    // Proto related contracts
    address constant CCIP_LIQUIDITY_SENDER =
        0x8c198F11fFe1B42B11A189b8657B5F2f591D95B5;
}
