// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {PoolAddressesProvider} from "./PoolAddressesProvider.sol";
import {Pool} from "./Pool.sol";
import {IToken} from "../tokenization/IToken.sol";
import {VariableDebtToken} from "../tokenization/VariableDebtToken.sol";

contract PoolConfigurator is Initializable {
    PoolAddressesProvider public addressesProvider;

    function initialize(
        PoolAddressesProvider _addressesProvider
    ) public initializer {
        addressesProvider = _addressesProvider;
    }

    function initReserve(
        address asset,
        address iToken,
        address variableDebtToken,
        address interestRateStrategy
    ) external {
        Pool pool = Pool(payable(addressesProvider.getPool()));
        pool.initReserve(
            asset,
            iToken,
            variableDebtToken,
            interestRateStrategy
        );
        IToken(iToken).initialize(
            addressesProvider.getPool(),
            asset,
            "iToken",
            "IT"
        );
        VariableDebtToken(variableDebtToken).initialize(
            addressesProvider.getPool(),
            asset,
            "Variable Debt Token",
            "VDT"
        );
    }
}
