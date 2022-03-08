// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IPriceFeed {
    function price(address token) external view returns (uint256);
}

interface IAggregator {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

interface IAlternateFeed {
    function price(address token) external view returns (uint256);
}

contract PriceFeed is IPriceFeed {
    using SafeMath for uint256;
    // token aggregator mapping for token prices in USD
    mapping(address => address) chainkLinkFeeds;
    mapping(address => address) alternateFeeds;

    uint256 public DECIMALS = 18;

    function setChainlinkSource(address token, address aggregator) external  {
        chainkLinkFeeds[token] = aggregator;
    }

    function setAlternateSource(address token, address source) external {
        alternateFeeds[token] = source;
    }

    // get all prices in USD
    function price(address token) external override view returns(uint256 _price) {

        if(chainkLinkFeeds[token] != address(0)){

            _price = uint256(IAggregator(chainkLinkFeeds[token]).latestAnswer()).mul(10 ** (DECIMALS.sub(uint256(IAggregator(chainkLinkFeeds[token]).decimals()))));

        }else if(alternateFeeds[token] != address(0)){
            
            _price = IAlternateFeed(alternateFeeds[token]).price(token);

        }else {

            require(false, "Token source not present");

        }

    }

}
