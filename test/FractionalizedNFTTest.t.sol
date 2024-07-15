// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {FractionlizedNftFactory} from "../src/FractionlizedNftFactory.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {FractionlizedNFT} from "../src/FractionlizedNFT.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "@chainlink/contracts/tests/MockV3Aggregator.sol";

contract FractionalizedNFTTest is Test {
    FractionlizedNFT public fractionlizedNFT;
    Whitelist public whitelist;
    MockV3Aggregator public mockAggregator;

    address public owner;
    address public user1;
    address public user2;

    uint256 constant WEIGHT = 100;
    uint256 constant NODE_NUM = 0;
    uint256 constant FEE = 20e6; // $0.20
    uint256 constant ETH_PRICE = 2000e8; // $2000 per ETH

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

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
            NODE_NUM
        );

        fractionlizedNFT.setPriceFeeds(address(mockAggregator));
        whitelist.authorizeToAddToBatch(address(fractionlizedNFT));
    }

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

    function testFailMintOverWhitelistLimit() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 1);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);
    }

    function testFailMintOutsideSalePeriod() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.warp(block.timestamp + 2 days);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);
    }

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

    function testGetWeight() public {
        assertEq(fractionlizedNFT.getWeight(), WEIGHT);
    }

    function testGetType() public {
        assertEq(uint(fractionlizedNFT.getType()), uint(IFractionlizedNFT.Type.Plat));
    }

    function testFailBurnBeforeEndTime() public {
        whitelist.whitelistUser(address(fractionlizedNFT), user1, 5);
        vm.prank(user1);
        vm.deal(user1, 1 ether);
        uint256 feeInEth = (2 * FEE * 1e18) / ETH_PRICE;
        fractionlizedNFT.mint{value: feeInEth}(2);
        
        fractionlizedNFT.burn(0);
    }

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