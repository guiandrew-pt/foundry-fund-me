// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Address ETH/USD -> 0x694AA1769357215DE4FAC081bf1f309aDC325306 // this is specific to sepolia network
        // Address ETH/USD -> 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF // zkSync Sepolia testnet
        // ABI

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // Price of the ETH in terms of USD
        // 200000000000
        return uint256(answer * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // 1 ETH
        // 2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        // (2000_000000000000000000 * 1_000000000000000000) / 1e18;
        // $2000 = 1 ETH
        // In solidity we want to multiply before divide
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd;
    }

    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return priceFeed.version();
        // AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version(); // sepolia network
        // return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version(); // zkSync Sepolia testnet
    }
}
