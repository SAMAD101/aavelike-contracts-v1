// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title PoolAddressesProvider
 * @author Sam
 * @notice Provides addresses for various components in the lending pool
 * - Used to retrieve addresses of contracts like PriceOracle, Pool, etc.
 */
contract PoolAddressesProvider is Initializable, OwnableUpgradeable {
    event AddressSet(bytes32 indexed id, address indexed newAddress);
    event PoolUpdated(address indexed newAddress);

    mapping(bytes32 => address) private _addresses;

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function getAddress(bytes32 id) public view returns (address) {
        return _addresses[id];
    }

    function setAddress(bytes32 id, address newAddress) public onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress);
    }

    function setPool(address newPool) public onlyOwner {
        setAddress("POOL", newPool);
        emit PoolUpdated(newPool);
    }

    function getPool() public view returns (address) {
        return getAddress("POOL");
    }

    function getPriceOracle() public view returns (address) {
        return getAddress("PRICE_ORACLE");
    }

    function setPriceOracle(address newPriceOracle) public onlyOwner {
        setAddress("PRICE_ORACLE", newPriceOracle);
    }
}
