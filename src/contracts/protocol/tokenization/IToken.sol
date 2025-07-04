// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title IToken
 * @author Sam
 * @notice Interest bearing token used in the protocol
 */
contract IToken is ERC20Upgradeable {
    address public pool;
    address public underlyingAsset;

    modifier onlyPool() {
        require(msg.sender == pool, "Only pool can call this");
        _;
    }

    function initialize(address _pool, address _underlyingAsset, string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        pool = _pool;
        underlyingAsset = _underlyingAsset;
    }

    function mint(address user, uint256 amount) external onlyPool {
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) external onlyPool {
        _burn(user, amount);
        ERC20Upgradeable(underlyingAsset).transfer(user, amount);
    }

    function transferUnderlyingTo(address to, uint256 amount) external onlyPool {
        ERC20Upgradeable(underlyingAsset).transfer(to, amount);
    }
}
