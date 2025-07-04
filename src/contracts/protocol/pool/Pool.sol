// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {PoolAddressesProvider} from "./PoolAddressesProvider.sol";
import {PoolLogic} from "./PoolLogic.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {Datatypes} from "../configuration/Datatypes.sol";
import {VariableDebtToken} from "../tokenization/VariableDebtToken.sol";
import {IToken} from "../tokenization/IToken.sol";

/**
 * @title Pool contract
 * @author Sam
 * @notice Main point of interaction with the protocol
 * - Users can:
 *   # supply
 *   # borrow
 *   # repay
 *   # withdraw
 */
contract Pool is Initializable, OwnableUpgradeable, PoolLogic {
    PoolAddressesProvider public addressesProvider;

    function initialize(
        PoolAddressesProvider _addressesProvider
    ) public initializer {
        __Ownable_init(msg.sender);
        addressesProvider = _addressesProvider;
    }

    function supply(address asset, uint256 amount) external {
        _supply(reserves, userReserves, userReservesList, asset, amount);
    }

    function borrow(address asset, uint256 amount) external {
        _borrow(reserves, userReserves, asset, amount);
    }

    function repay(address asset, uint256 amount) external {
        _repay(reserves, userReserves, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external {
        _withdraw(reserves, userReserves, asset, amount);
    }

    function initReserve(
        address asset,
        address iToken,
        address variableDebtToken,
        address interestRateStrategy
    ) external {
        require(
            msg.sender == owner() ||
                msg.sender ==
                addressesProvider.getAddress(keccak256("POOL_CONFIGURATOR")),
            "Only owner or pool configurator can initialize reserves"
        );
        PoolLogic.initReserve(
            reserves,
            asset,
            iToken,
            variableDebtToken,
            interestRateStrategy
        );
    }

    function getReserveData(
        address asset
    ) external view returns (Datatypes.ReserveData memory) {
        return _getReserveData(reserves, asset);
    }

    function burnDebtTokens(
        address borrower,
        address asset,
        uint256 amount
    ) external {
        require(
            msg.sender ==
                addressesProvider.getAddress(keccak256("COLLATERAL_MANAGER")),
            "Only collateral manager can call this"
        );

        Datatypes.ReserveData storage reserve = reserves[asset];
        VariableDebtToken(reserve.variableDebtTokenAddress).burn(
            borrower,
            amount
        );
    }

    function transferITokens(
        address asset,
        address from,
        address to,
        uint256 amount
    ) external {
        require(
            msg.sender ==
                addressesProvider.getAddress(keccak256("COLLATERAL_MANAGER")),
            "Only collateral manager can call this"
        );

        Datatypes.ReserveData storage reserve = reserves[asset];
        IToken(reserve.iTokenAddress).transferFrom(from, to, amount);
    }

    function calculateHealthFactor(address user) public view returns (uint256) {
        return
            _calculateHealthFactor(
                reserves,
                userReserves,
                userReservesList,
                user
            );
    }

    function _supply(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        mapping(address => address[]) storage userReservesList,
        address asset,
        uint256 amount
    ) internal {
        PoolLogic.supply(
            reserves,
            userReserves,
            userReservesList,
            asset,
            amount
        );
    }

    function _borrow(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address asset,
        uint256 amount
    ) internal {
        PoolLogic.borrow(reserves, userReserves, asset, amount);
    }

    function _repay(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address asset,
        uint256 amount
    ) internal {
        PoolLogic.repay(reserves, userReserves, asset, amount);
    }

    function _withdraw(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        address asset,
        uint256 amount
    ) internal {
        PoolLogic.withdraw(reserves, userReserves, asset, amount);
    }

    function _getReserveData(
        mapping(address => Datatypes.ReserveData) storage reserves,
        address asset
    ) internal view returns (Datatypes.ReserveData memory) {
        return PoolLogic.getReserveData(reserves, asset);
    }

    function _calculateHealthFactor(
        mapping(address => Datatypes.ReserveData) storage reserves,
        mapping(address => mapping(address => Datatypes.UserReserveConfig))
            storage userReserves,
        mapping(address => address[]) storage userReservesList,
        address user
    ) internal view returns (uint256) {
        return
            PoolLogic.calculateHealthFactor(
                reserves,
                userReserves,
                userReservesList,
                addressesProvider,
                user
            );
    }
}
