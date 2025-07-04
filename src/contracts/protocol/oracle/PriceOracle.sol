// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title PriceOracle
 * @author Sam
 * @notice Orcale for price feeds in the protocol
 */
contract PriceOracle is Initializable, OwnableUpgradeable {
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    mapping(address => uint256) public assetPrices;

    event AssetPriceUpdated(address indexed asset, uint256 price);

    function setAssetPrice(address asset, uint256 price) external onlyOwner {
        assetPrices[asset] = price;
        emit AssetPriceUpdated(asset, price);
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return assetPrices[asset];
    }
}
