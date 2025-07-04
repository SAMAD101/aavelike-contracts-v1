// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/contracts/protocol/pool/Pool.sol";
import "../src/contracts/protocol/pool/PoolConfigurator.sol";
import "../src/contracts/protocol/pool/PoolAddressesProvider.sol";
import "../src/contracts/protocol/pool/PoolCollateralManager.sol";
import "../src/contracts/protocol/oracle/PriceOracle.sol";
import "../src/contracts/protocol/tokenization/VariableDebtToken.sol";
import "../src/contracts/protocol/tokenization/IToken.sol";
import "../src/contracts/protocol/misc/ReserveInterestRateStrategy.sol";
import "../test/mocks/ERC20Mock.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Addresses Provider
        PoolAddressesProvider addressesProvider = new PoolAddressesProvider();
        addressesProvider.initialize(msg.sender);

        // Deploy Pool
        Pool pool = new Pool();
        pool.initialize(addressesProvider);
        addressesProvider.setPool(address(pool));

        // Deploy PoolConfigurator
        PoolConfigurator poolConfigurator = new PoolConfigurator();
        poolConfigurator.initialize(addressesProvider);
        addressesProvider.setAddress(keccak256("POOL_CONFIGURATOR"), address(poolConfigurator));

        // Deploy Oracle
        PriceOracle oracle = new PriceOracle();
        oracle.initialize(msg.sender);
        addressesProvider.setPriceOracle(address(oracle));

        // Deploy Collateral Manager
        PoolCollateralManager collateralManager = new PoolCollateralManager();
        collateralManager.initialize(addressesProvider);
        addressesProvider.setAddress(keccak256("COLLATERAL_MANAGER"), address(collateralManager));

        // Deploy Interest Rate Strategy
        ReserveInterestRateStrategy interestRateStrategy = new ReserveInterestRateStrategy(
            8e25, // 80%
            0,
            4e25, // 4%
            3e26 // 300%
        );

        // Deploy Underlying Asset
        ERC20Mock underlyingAsset = new ERC20Mock();
        underlyingAsset.__ERC20Mock_init("Gpu", "GPU");

        // Deploy Tokens
        IToken iToken = new IToken();
        iToken.initialize(address(pool), address(underlyingAsset), "iGpu", "iGPU");
        VariableDebtToken debtToken = new VariableDebtToken();
        debtToken.initialize(address(pool), address(underlyingAsset), "GPU Protocol Debt token", "variableDebtGPU");

        // Configure the reserve
        poolConfigurator.initReserve(
            address(underlyingAsset), address(iToken), address(debtToken), address(interestRateStrategy)
        );

        vm.stopBroadcast();
    }
}
