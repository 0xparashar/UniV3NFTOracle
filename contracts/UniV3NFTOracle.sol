// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import { IPriceFeed } from "./PriceFeed.sol";
import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { LiquidityAmounts } from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";


interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

contract UniV3NFTOracle {
    using SafeMath for uint256;
    INonfungiblePositionManager public positionManager;

    IPriceFeed public priceFeed;

    constructor(address _positionManager, address _priceFeed) {
        positionManager = INonfungiblePositionManager(_positionManager);
        priceFeed = IPriceFeed(_priceFeed);
    }

    function getPrice(uint tokenId) public view returns (uint){

        (,,
        address token0, 
        address token1,,
        int24 tickLower, 
        int24 tickUpper, 
        uint128 liquidity,,,
        ,
        ) = positionManager.positions(tokenId);


        (uint price0, uint price1) = getPrices(token0, token1);

        uint160 sqrtPriceX96 = uint160(getSqrtPriceX96(price0, price1));

        int24 tick = getTick(sqrtPriceX96);

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            TickMath.getSqrtRatioAtTick(tick),
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );

        return calculatePrice(amount0, amount1, token0, token1);
    }


    function getPrices(address tokenA, address tokenB) public view returns (uint priceA, uint priceB) {
        uint _priceA = priceFeed.price(tokenA);
        uint _priceB = priceFeed.price(tokenB);
        
        priceA = 10**IERC20Detailed(tokenA).decimals();
        priceB = _priceB.mul(IERC20Detailed(tokenB).decimals()).div(_priceA);
    }


    function _sqrt(uint _x) internal pure returns(uint y) {
        uint z = (_x + 1) / 2;
        y = _x;
        while (z < y) {
            y = z;
            z = (_x / z + z) / 2;
        }
    }

    function getSqrtPriceX96(uint priceA, uint priceB) public pure returns (uint) {
        uint ratioX192 = (priceA << 192).div(priceB);
        return _sqrt(ratioX192);
    }

    function getTick(uint160 sqrtPriceX96) public pure returns (int24 tick) {
        tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    function calculatePrice(uint amountA, uint amountB, address tokenA, address tokenB) public view returns (uint price) {
        price = (amountA.mul(priceFeed.price(tokenA))).add(amountB.mul(priceFeed.price(tokenB)));
    }

}