// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ReserveInterestRateStrategy
 * @author Sam
 * @notice Defines the interest rate strategy for a reserve in the protocol
 */
contract ReserveInterestRateStrategy {
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;
    uint256 public immutable BASE_VARIABLE_BORROW_RATE;
    uint256 public immutable VARIABLE_RATE_SLOPE1;
    uint256 public immutable VARIABLE_RATE_SLOPE2;

    constructor(
        uint256 _optimalUtilizationRate,
        uint256 _baseVariableBorrowRate,
        uint256 _variableRateSlope1,
        uint256 _variableRateSlope2
    ) {
        OPTIMAL_UTILIZATION_RATE = _optimalUtilizationRate;
        BASE_VARIABLE_BORROW_RATE = _baseVariableBorrowRate;
        VARIABLE_RATE_SLOPE1 = _variableRateSlope1;
        VARIABLE_RATE_SLOPE2 = _variableRateSlope2;
    }

    function calculateInterestRates(uint256 totalBorrows, uint256 totalLiquidity)
        external
        view
        returns (uint256 liquidityRate, uint256 borrowRate)
    {
        uint256 utilizationRate = totalLiquidity == 0 ? 0 : (totalBorrows * 1e18) / totalLiquidity;

        if (utilizationRate <= OPTIMAL_UTILIZATION_RATE) {
            borrowRate = BASE_VARIABLE_BORROW_RATE + (utilizationRate * VARIABLE_RATE_SLOPE1) / 1e18;
        } else {
            borrowRate = BASE_VARIABLE_BORROW_RATE + VARIABLE_RATE_SLOPE1
                + ((utilizationRate - OPTIMAL_UTILIZATION_RATE) * VARIABLE_RATE_SLOPE2) / 1e18;
        }

        liquidityRate = (borrowRate * utilizationRate) / 1e18;
    }
}
