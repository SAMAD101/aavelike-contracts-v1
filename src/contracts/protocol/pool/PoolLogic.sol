// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Datatypes} from "../configuration/Datatypes.sol";
import {IToken} from "../tokenization/IToken.sol";
import {VariableDebtToken} from "../tokenization/VariableDebtToken.sol";
import {ReserveInterestRateStrategy} from "../misc/ReserveInterestRateStrategy.sol";
import {PoolCollateralManager} from "./PoolCollateralManager.sol";
import {PoolAddressesProvider} from "./PoolAddressesProvider.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {PriceOracle} from "../oracle/PriceOracle.sol";

abstract contract PoolLogic is PoolStorage {
    event ReserveInitialized(
        address indexed asset,
        address indexed iToken,
        address indexed variableDebtToken,
        address interestRateStrategy
    );
    event Supplied(address indexed asset, address indexed user, uint256 amount);
    event Borrowed(address indexed asset, address indexed user, uint256 amount);
    event Repaid(address indexed asset, address indexed user, uint256 amount);
    event Withdrawn(
        address indexed asset,
        address indexed user,
        uint256 amount
    );

    function initReserve(
        mapping(address => Datatypes.ReserveData) storage reserves,
        address asset,
        address iToken,
        address variableDebtToken,
        address interestRateStrategy
    ) internal {
        reserves[asset].iTokenAddress = iToken;
        reserves[asset].variableDebtTokenAddress = variableDebtToken;
        reserves[asset].interestRateStrategyAddress = interestRateStrategy;
        reserves[asset].isActive = true;
        reserves[asset].isFrozen = false;
        reserves[asset].borrowingEnabled = true;
        emit ReserveInitialized(
            asset,
            iToken,
            variableDebtToken,
            interestRateStrategy
        );
    }

    function supply(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        mapping(address => address[]) storage userReservesList,
        address asset,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount must be greater than zero");
        Datatypes.ReserveData storage reserve = reserves[asset];
        require(reserve.isActive, "Reserve is not active");

        if (
            userReserves[msg.sender][asset].userCollateral == 0 &&
            userReserves[msg.sender][asset].userDebt == 0
        ) {
            userReservesList[msg.sender].push(asset);
        }

        userReserves[msg.sender][asset].userCollateral += amount;

        ERC20Upgradeable(asset).transferFrom(
            msg.sender,
            reserve.iTokenAddress,
            amount
        );
        IToken(reserve.iTokenAddress).mint(msg.sender, amount);

        emit Supplied(asset, msg.sender, amount);
    }

    function borrow(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address asset,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount must be greater than zero");
        Datatypes.ReserveData storage reserve = reserves[asset];
        require(reserve.isActive, "Reserve is not active");
        require(reserve.borrowingEnabled, "Borrowing is not enabled");

        userReserves[msg.sender][asset].userDebt += amount;

        VariableDebtToken(reserve.variableDebtTokenAddress).mint(
            msg.sender,
            amount
        );
        IToken(reserve.iTokenAddress).transferUnderlyingTo(msg.sender, amount);

        emit Borrowed(asset, msg.sender, amount);
    }

    function repay(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address asset,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount must be greater than zero");
        Datatypes.ReserveData storage reserve = reserves[asset];
        require(reserve.isActive, "Reserve is not active");

        userReserves[msg.sender][asset].userDebt -= amount;

        ERC20Upgradeable(asset).transferFrom(
            msg.sender,
            reserve.iTokenAddress,
            amount
        );
        VariableDebtToken(reserve.variableDebtTokenAddress).burn(
            msg.sender,
            amount
        );

        emit Repaid(asset, msg.sender, amount);
    }

    function withdraw(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address asset,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount must be greater than zero");
        Datatypes.ReserveData storage reserve = reserves[asset];
        require(reserve.isActive, "Reserve is not active");

        userReserves[msg.sender][asset].userCollateral -= amount;

        IToken(reserve.iTokenAddress).burn(msg.sender, amount);

        emit Withdrawn(asset, msg.sender, amount);
    }

    function liquidate(
        address addressesProvider,
        address liquidator,
        address borrower,
        address asset,
        uint256 debtToCover,
        uint256 liquidatedCollateralFor,
        bool receiveIToken
    ) external virtual {
        address collateralManagerAddress = PoolAddressesProvider(
            addressesProvider
        ).getAddress(keccak256("COLLATERAL_MANAGER"));
        PoolCollateralManager(collateralManagerAddress).liquidate(
            liquidator,
            borrower,
            asset,
            debtToCover,
            liquidatedCollateralFor,
            receiveIToken
        );
    }

    function getReserveData(
        mapping(address => Datatypes.ReserveData) storage reserves,
        address asset
    ) internal view returns (Datatypes.ReserveData memory) {
        return reserves[asset];
    }

    function getUserReserveData(
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address user,
        address asset
    ) internal view returns (Datatypes.UserReserveConfig memory) {
        return userReserves[user][asset];
    }

    function calculateHealthFactor(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        mapping(address => address[]) storage userReservesList,
        PoolAddressesProvider addressesProvider,
        address user
    ) internal view returns (uint256) {
        uint256 totalCollateral = 0;
        uint256 totalDebt = 0;
        PriceOracle priceOracle = PriceOracle(
            addressesProvider.getPriceOracle()
        );

        uint256 liquidationThreshold = 0;

        for (uint256 i = 0; i < userReservesList[user].length; i++) {
            address asset = userReservesList[user][i];
            Datatypes.UserReserveConfig memory userReserve = userReserves[user][
                asset
            ];
            Datatypes.ReserveData memory reserve = reserves[asset];

            if (userReserve.usedAsCollateral) {
                totalCollateral +=
                    (userReserve.userCollateral *
                        priceOracle.getAssetPrice(asset)) /
                    1e18;
                liquidationThreshold = reserve.liquidationThreshold;
            }

            totalDebt +=
                (userReserve.userDebt * priceOracle.getAssetPrice(asset)) /
                1e18;
        }

        if (totalDebt == 0) {
            return type(uint256).max;
        }

        return (totalCollateral * liquidationThreshold) / totalDebt;
    }
}
