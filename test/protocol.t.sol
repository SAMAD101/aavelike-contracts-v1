// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/contracts/protocol/pool/Pool.sol";
import "../src/contracts/protocol/pool/PoolConfigurator.sol";
import "../src/contracts/protocol/pool/PoolAddressesProvider.sol";
import "../src/contracts/protocol/pool/PoolCollateralManager.sol";
import "../src/contracts/protocol/oracle/PriceOracle.sol";
import "../src/contracts/protocol/tokenization/VariableDebtToken.sol";
import "../src/contracts/protocol/tokenization/IToken.sol";
import "../src/contracts/protocol/misc/ReserveInterestRateStrategy.sol";
import "./mocks/ERC20Mock.sol";

contract ProtocolTest is Test {
    PoolAddressesProvider addressesProvider;
    Pool pool;
    PoolConfigurator poolConfigurator;
    PriceOracle oracle;
    PoolCollateralManager collateralManager;
    ReserveInterestRateStrategy interestRateStrategy;
    IToken iToken;
    VariableDebtToken debtToken;
    ERC20Mock underlyingAsset;

    function setUp() public {
        addressesProvider = new PoolAddressesProvider();
        addressesProvider.initialize(address(this));

        console.log("Addresses Provider initialized at:", address(addressesProvider));

        pool = new Pool();
        poolConfigurator = new PoolConfigurator();
        oracle = new PriceOracle();
        collateralManager = new PoolCollateralManager();

        interestRateStrategy = new ReserveInterestRateStrategy(
            8e25, // 80%
            0,
            4e25, // 4%
            3e26 // 300%
        );

        underlyingAsset = new ERC20Mock();
        underlyingAsset.__ERC20Mock_init("Gpu", "GPU");

        iToken = new IToken();
        debtToken = new VariableDebtToken();

        addressesProvider.setPool(address(pool));
        addressesProvider.setPriceOracle(address(oracle));
        addressesProvider.setAddress(keccak256("POOL_CONFIGURATOR"), address(poolConfigurator));
        addressesProvider.setAddress(keccak256("COLLATERAL_MANAGER"), address(collateralManager));

        pool.initialize(addressesProvider);
        console.log("Pool initialized at:", address(pool));
        poolConfigurator.initialize(addressesProvider);
        console.log("PoolConfigurator initialized at:", address(poolConfigurator));
        oracle.initialize(address(this));
        console.log("Oracle initialized at:", address(oracle));
        collateralManager.initialize(addressesProvider);
        console.log("CollateralManager initialized at:", address(collateralManager));

        poolConfigurator.initReserve(
            address(underlyingAsset), address(iToken), address(debtToken), address(interestRateStrategy)
        );

        console.log("Reserve initialized for underlying asset at:", address(underlyingAsset));
        console.log("iToken initialized at:", address(iToken));
        console.log("DebtToken initialized at:", address(debtToken));
        console.log("InterestRateStrategy initialized at:", address(interestRateStrategy));
    }

    function testDeployment() public view {
        assertTrue(address(addressesProvider) != address(0));
        assertTrue(address(pool) != address(0));
        assertTrue(address(poolConfigurator) != address(0));
        assertTrue(address(oracle) != address(0));
        assertTrue(address(collateralManager) != address(0));
        assertTrue(address(interestRateStrategy) != address(0));
        assertTrue(address(iToken) != address(0));
        assertTrue(address(debtToken) != address(0));
        assertTrue(address(underlyingAsset) != address(0));
    }

    function testSupply() public {
        // Mint some underlying asset to the user
        underlyingAsset.mint(address(this), 100e18);

        // Approve the pool to spend the underlying asset
        underlyingAsset.approve(address(pool), 100e18);

        // Supply the underlying asset to the pool
        pool.supply(address(underlyingAsset), 100e18);

        // Check that the user has the correct amount of iTokens
        assertEq(iToken.balanceOf(address(this)), 100e18);
    }

    function testBorrow() public {
        // Supply some collateral
        underlyingAsset.mint(address(this), 200e18);
        underlyingAsset.approve(address(pool), 200e18);
        pool.supply(address(underlyingAsset), 200e18);

        // Borrow some of the underlying asset
        pool.borrow(address(underlyingAsset), 100e18);

        // Check that the user has the correct amount of debt tokens
        assertEq(debtToken.balanceOf(address(this)), 100e18);
    }

    function testRepay() public {
        // Supply some collateral
        underlyingAsset.mint(address(this), 200e18);
        underlyingAsset.approve(address(pool), 200e18);
        pool.supply(address(underlyingAsset), 200e18);

        // Borrow some of the underlying asset
        pool.borrow(address(underlyingAsset), 100e18);

        // Repay the loan
        underlyingAsset.approve(address(pool), 100e18);
        pool.repay(address(underlyingAsset), 100e18);

        // Check that the user has no debt tokens
        assertEq(debtToken.balanceOf(address(this)), 0);
    }

    function testWithdraw() public {
        // Supply some collateral
        underlyingAsset.mint(address(this), 200e18);
        underlyingAsset.approve(address(pool), 200e18);
        pool.supply(address(underlyingAsset), 200e18);

        // Withdraw the collateral
        pool.withdraw(address(underlyingAsset), 200e18);

        // Check that the user has no iTokens
        assertEq(iToken.balanceOf(address(this)), 0);
    }

    function testLiquidation() public {
        // Supply some collateral
        underlyingAsset.mint(address(this), 200e18);
        underlyingAsset.approve(address(pool), 200e18);
        pool.supply(address(underlyingAsset), 200e18);

        iToken.approve(address(pool), 200e18);
        // Borrow some of the underlying asset
        pool.borrow(address(underlyingAsset), 100e18);

        // Set the price of the collateral to half its original value
        oracle.setAssetPrice(address(underlyingAsset), 5e17);

        // Liquidate the user
        address liquidator = makeAddr("liquidator");
        underlyingAsset.mint(liquidator, 100e18);

        vm.startPrank(liquidator);
        underlyingAsset.approve(address(pool), 100e18);
        underlyingAsset.approve(address(collateralManager), 100e18);

        pool.liquidate(
            address(addressesProvider), liquidator, address(this), address(underlyingAsset), 100e18, 200e18, false
        );

        vm.stopPrank();

        // Check that the user has no debt tokens
        assertEq(debtToken.balanceOf(address(this)), 0);
    }

    function test_RevertWhen_BorrowTooMuch() public {
        // Supply some collateral
        underlyingAsset.mint(address(this), 100e18);
        underlyingAsset.approve(address(pool), 100e18);
        pool.supply(address(underlyingAsset), 100e18);

        // Expect the next call to revert
        vm.expectRevert();

        // Try to borrow more than the collateral is worth
        pool.borrow(address(underlyingAsset), 200e18);
    }
}
