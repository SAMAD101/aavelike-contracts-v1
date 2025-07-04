// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {PoolAddressesProvider} from "./PoolAddressesProvider.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {Pool} from "./Pool.sol";
import {Datatypes} from "../configuration/Datatypes.sol";
import {IToken} from "../tokenization/IToken.sol";
import {VariableDebtToken} from "../tokenization/VariableDebtToken.sol";

/**
 * @title PoolCollateralManager
 * @author Sam
 * @notice Controller for managing collateral in the lending pool
 */
contract PoolCollateralManager is Initializable {
    PoolAddressesProvider public addressesProvider;

    event Liquidation(
        address indexed liquidator,
        address indexed borrower,
        address indexed asset,
        uint256 debtToCover,
        uint256 liquidatedCollateralFor,
        bool receiveIToken
    );
    event ReserveUsedAsCollateralEnabled(address indexed asset, address indexed user);
    event ReserveUsedAsCollateralDisabled(address indexed asset, address indexed user);

    modifier onlyPool() {
        require(msg.sender == addressesProvider.getPool(), "Only pool can call this");
        _;
    }

    function initialize(PoolAddressesProvider _addressesProvider) public initializer {
        addressesProvider = _addressesProvider;
    }

    function liquidate(
        address liquidator,
        address borrower,
        address asset,
        uint256 debtToCover,
        uint256 liquidatedCollateralFor,
        bool receiveIToken
    ) external onlyPool {
        Pool pool = Pool(payable(addressesProvider.getPool()));

        ERC20Upgradeable(asset).transferFrom(liquidator, address(this), debtToCover);

        pool.transferITokens(asset, borrower, liquidator, liquidatedCollateralFor);

        pool.burnDebtTokens(borrower, asset, debtToCover);

        emit Liquidation(liquidator, borrower, asset, debtToCover, liquidatedCollateralFor, receiveIToken);
    }

    function setCollateralUsage(address asset, bool useAsCollateral) external {
        if (useAsCollateral) {
            emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
        } else {
            emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        }
    }
}
