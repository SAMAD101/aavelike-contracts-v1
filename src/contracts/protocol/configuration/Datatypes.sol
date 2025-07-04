// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

library Datatypes {
    struct ReserveData {
        uint256 liquidityIndex;
        uint256 variableBorrowIndex;
        uint256 currentLiquidityRate;
        uint256 currentVariableBorrowRate;
        uint256 lastUpdateTimestamp;
        address iTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint256 totalSupply;
        uint256 totalBorrows;
        bool isActive;
        bool isFrozen;
        bool borrowingEnabled;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
    }

    struct UserReserveConfig {
        uint256 userCollateral;
        uint256 userDebt;
        bool usedAsCollateral;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct UserConfiguration {
        uint256 data;
    }

    struct ReserveInitParams {
        address iToken;
        address variableDebtToken;
        address interestRateStrategy;
        address asset;
    }
}
