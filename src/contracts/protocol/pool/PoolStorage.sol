// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Datatypes} from "../configuration/Datatypes.sol";

/**
 * @title PoolStorage
 * @author Sam
 * @notice Initializes and stores reserve data and user reserve configurations
 */
contract PoolStorage {
    mapping(address => Datatypes.ReserveData) internal reserves;
    mapping(address => mapping(address => Datatypes.UserReserveConfig)) internal userReserves;
    mapping(address => address[]) internal userReservesList;
}
