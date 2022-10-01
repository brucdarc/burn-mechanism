// SPDX-License-Identifier:GPLV3
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RemBurner {

    uint256 public lastRate;
    uint256 public lastResetTimestamp;
    uint256 public minRate;
    uint256 public maxRate;
    IERC20 public stableCoin;
    uint256 resetThreshold = 250e18; //Stablecoin value to complete reset from max to min, anything less causes only partial reset (linear decrease)

    uint256 constant THREE_HOURS = 3 hours;
    uint256 constant PRECISION_FACTOR = 1e18;


    //Scale linearly from min to max over 3 hours
    //exchange rate is a decimal percentage scaled to PRECISION_FACTOR
    function getCurrentExchangeRate() public view returns (uint256){
        uint256 timeElapsed = block.timestamp - lastResetTimestamp;
        uint256 rateIncrease = (maxRate - minRate) * timeElapsed / THREE_HOURS;
        uint256 totalRate = rateIncrease + lastRate;
        if(totalRate > maxRate) return maxRate;
        return totalRate;
    }

    //Give exchange rate between a particular depegged asset and the stablecoin.
    //These values should ideally be snapshotted from the instant of the hack to avoid dynamic pricing
    //Is a decimal percentage scaled to PRECISION_FACTOR
    function getAssetRate(IERC20 _asset) public view returns (uint256){
        return 0;
    }

    function calculateRateUpdate(uint256 _totalExchanged)
        public
        view
        returns(uint256)
    {
        if(_totalExchanged > resetThreshold){
            return minRate;
        }
        uint256 rateDecreasePercentage = _totalExchanged * PRECISION_FACTOR / resetThreshold;
        uint256 resultRate = lastRate - (maxRate - minRate) * rateDecreasePercentage / PRECISION_FACTOR;
        return resultRate;
    }

    function updateRate(uint256 _totalExchanged) internal {
        lastRate = calculateRateUpdate(_totalExchanged);
        lastResetTimestamp = block.timestamp;
    }

    //_minExchangeRate parameter to prevent frontrunner sabotage, works similar to slippage param
    function exchange(
        IERC20 _asset,
        uint256 _amount,
        uint256 _minExchangeRate
    )
        external
    {
        uint256 currentExchangeRate = getCurrentExchangeRate();
        require(currentExchangeRate > _minExchangeRate, "RATE BELOW REQUESTED FLOOR");

        _asset.transferFrom(msg.sender, address(this), _amount);

        uint256 assetValue = getAssetRate(_asset);

        uint256 assetTotalValue = _amount * assetValue / PRECISION_FACTOR;

        uint256 assetExchangeValue = assetTotalValue * currentExchangeRate / PRECISION_FACTOR;

        updateRate(assetExchangeValue);

        stableCoin.transfer(msg.sender, assetExchangeValue);
    }

}
