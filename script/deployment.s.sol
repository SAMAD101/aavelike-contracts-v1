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

contract DeployScript is Script {
    // GPU token address
    address constant GPU_ADDRESS = 0xA96db422D0bf71fBC7581332C7b990E61963844f;
    
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

        // Deploy Interest Rate Strategy for GPU
        ReserveInterestRateStrategy gpuStrategy = new ReserveInterestRateStrategy(
            8e25, // 80% optimal utilization
            0,    // 0% base rate
            5e25, // 5% slope1
            1e26  // 100% slope2
        );

        // Deploy Token implementations (without initializing)
        IToken gpuIToken = new IToken();
        VariableDebtToken gpuDebtToken = new VariableDebtToken();

        // Configure GPU Reserve
        poolConfigurator.initReserve(
            GPU_ADDRESS,
            address(gpuIToken),
            address(gpuDebtToken),
            address(gpuStrategy)
        );

        // Set asset price in oracle
        // oracle.setAssetPrice(GPU_ADDRESS, 1000e8); // $1000 GPU

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("\n=== GPUnet Deployment Complete ===");
        console.log("Network: GPUnet (Chain ID: 4048)");
        console.log("PoolAddressesProvider:", address(addressesProvider));
        console.log("Pool:", address(pool));
        console.log("PoolCollateralManager:", address(collateralManager));
        console.log("PoolConfigurator:", address(poolConfigurator));
        console.log("Oracle:", address(oracle));
        console.log("");
        console.log("=== GPU Reserve ===");
        console.log("GPU Token:", GPU_ADDRESS);
        console.log("GPU IToken:", address(gpuIToken));
        console.log("GPU DebtToken:", address(gpuDebtToken));
        console.log("GPU Strategy:", address(gpuStrategy));
        console.log("===================================");
    }
}
