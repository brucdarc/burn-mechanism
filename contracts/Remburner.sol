// SPDX-License-Identifier:GPLV3
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RemBurner {

    uint256 public lastValue;
    uint256 public lastResetTimestamp;
    uint256 public minValue;
    uint256 public maxValue;
    IERC20 public stableCoin;

    uint256 constant THREE_HOURS = 3 hours;
    uint256 constant PRECISION_FACTOR = 1e18;


    //Scale linearly from min to max over 3 hours
    //exchange rate is a decimal percentage scaled to PRECISION_FACTOR
    function getCurrentExchangeRate() public view returns (uint256){
        uint256 timeElapsed = block.timestamp - lastResetTimestamp;
        uint256 valueIncrease = (maxValue - minValue) * timeElapsed / THREE_HOURS;
        uint256 totalPrice = valueIncrease + lastValue;
        if(totalPrice > maxValue) return maxValue;
        return totalPrice;
    }

    //Give exchange rate between a particular depegged asset and the stablecoin.
    //These values should ideally be snapshotted from the instant of the hack to avoid dynamic pricing
    //Is a decimal percentage scaled to PRECISION_FACTOR
    function getAssetRate(IERC20 _asset) public view returns (uint256){
        return 0;
    }

    //_minExchangeRate parameter to prevent frontrunner sabotage, works similar to slippage param
    function exchange(IERC20 _asset, uint256 _amount, uint256 _minExchangeRate){
        uint256 currentExchangeRate = getCurrentExchangeRate();
        require(currentExchangeRate > _minExchangeRate, "RATE BELOW REQUESTED FLOOR");

        _asset.transferFrom(msg.sender, address(this), _amount);

        uint256 assetValue = getAssetRate(_asset);

        uint256 assetTotalValue = _amount * assetValue / PRECISION_FACTOR;

        uint256 assetExchangeValue = assetTotalValue * currentPrice / PRECISION_FACTOR;

        stableCoin.transfer(msg.sender, assetExchangeValue);
    }

}
