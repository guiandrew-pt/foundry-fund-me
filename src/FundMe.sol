// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner(); // Will cost less gas fees

contract FundMe {
    using PriceConverter for uint256;

    // State variables:
    // Putting variables constant lower the gas fees
    uint256 public constant MINIMUM_USD = 5e14; // To lower the minimum to 500000000000000 Wei, easy to test.
    // uint256 public MINIMUM_USD = 5e18; // To lower the minimum to 5000000000000000000 Wei, not easy to test, gas fees.

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    // Putting variables immutable lower the gas fees
    // Use immutable when assign at the beginning
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder];
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the array
        s_funders = new address[](0);
        // actually withdraw the funds

        // 1. transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        /* payable(msg.sender).transfer(address(this).balance); // Reverts automatic */

        // 2. send
        /* bool sendSuccess = payable(msg.sender).send(address(this).balance); // Only reverts, if we have the require
        require(sendSuccess, "Send failed!"); */

        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Must be owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // the order matters.
    }

    // What happens if someone sends this contract ETH without calling the fund function?
    // Receive
    receive() external payable {
        fund();
    }

    // fallback()
    fallback() external payable {
        fund();
    }

    function getVersion() public view returns (uint256) {
        return AggregatorV3Interface(s_priceFeed).version(); // sepolia network
        // return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version(); // zkSync Sepolia testnet
    }

    /**
     * View / Pure functions (Getters)
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
