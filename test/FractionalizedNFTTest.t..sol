// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/FractionlizedNFT.sol";
import "../src/Whitelist.sol";
import "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "@chainlink/contracts/tests/MockV3Aggregator.sol";

/// @title FractionalizedNFTTest
/// @notice Test suite for the FractionlizedNFT contract
contract FractionalizedNFTTest is Test {
    FractionlizedNFT public fractionlizedNFT;
    Whitelist public whitelist;
    MockV3Aggregator public mockAggregator;

    address public owner;
    address public user1;
    address public user2;

    // Constants for test setup
    uint256 constant WEIGHT = 100;
    uint256 constant NODE_NUM = 0;
    uint256 constant FEE = 20e6; // $0.20
    uint256 constant ETH_PRICE = 2000e8; // $2000 per ETH
    uint256 constant NODE_PRICE = 500e8;

    /// @notice Set up the test environment before each test
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy mock contracts and set up the FractionlizedNFT
        mockAggregator = new MockV3Aggregator(8, int256(ETH_PRICE));
        whitelist = new Whitelist(address(this));

        fractionlizedNFT = new FractionlizedNFT(
            "TestNFT",
            "TNFT",
            WEIGHT,
            block.timestamp,
            block.timestamp + 1 days,
            IFractionlizedNFT.Type.Plat,
            address(whitelist),
            NODE_NUM,
            NODE_PRICE
        );

        fractionlizedNFT.setPriceFeeds(address(mockAggregator));
        whitelist.authorizeToAddToBatch(address(fractionlizedNFT));
    }

    /// @notice Test minting NFTs
    function testMint() public {
        uint256 mintAmount = 2;
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (mintAmount * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(mintAmount);
        assertEq(fractionlizedNFT.balanceOf(user1), mintAmount);
        assertEq(whitelist.getUserNFTAmounts(NODE_NUM, user1, address(fractionlizedNFT)), mintAmount);
    }

    /// @notice Test minting over whitelist limit (should fail)
    function testFailMintOverWhitelistLimit() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 1);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);
    }

    /// @notice Test minting outside sale period (should fail)
    function testFailMintOutsideSalePeriod() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.warp(block.timestamp + 2 days);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);
    }

    /// @notice Test burning NFTs
    function testBurn() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);

        vm.warp(block.timestamp + 2 days);
        fractionlizedNFT.burn(0);
        assertEq(fractionlizedNFT.balanceOf(user1), 1);
    }

    /// @notice Test refunding unsold NFTs
    function testRefundUnsold() public {
        uint256 mintAmount = 2;
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (mintAmount * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(mintAmount);
        vm.deal(address(fractionlizedNFT), 1 ether);

        vm.warp(block.timestamp + 2 days);
        uint256 balanceBefore = user1.balance;
        fractionlizedNFT.refundUnsold();
        uint256 balanceAfter = user1.balance;
        vm.stopPrank();

        assertGt(balanceAfter, balanceBefore);
        assertEq(fractionlizedNFT.balanceOf(user1), 0);
        assertEq(whitelist.getUserNFTAmounts(NODE_NUM, user1, address(fractionlizedNFT)), 0);
    }

    /// @notice Test getting NFT weight
    function testGetWeight() public {
        assertEq(fractionlizedNFT.getWeight(), WEIGHT);
    }

    /// @notice Test getting NFT type
    function testGetType() public {
        assertEq(uint256(fractionlizedNFT.getType()), uint256(IFractionlizedNFT.Type.Plat));
    }

    /// @notice Test burning before end time (should fail)
    function testFailBurnBeforeEndTime() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);

        fractionlizedNFT.burn(0);
    }

    /// @notice Test refunding before end time (should fail)
    function testFailRefundBeforeEndTime() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);

        vm.prank(user1);
        fractionlizedNFT.refundUnsold();
    }
}