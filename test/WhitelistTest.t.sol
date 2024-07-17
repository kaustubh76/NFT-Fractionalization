// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {FractionlizedNftFactory} from "../src/FractionlizedNftFactory.sol";
import {FractionlizedNFT} from "../src/FractionlizedNFT.sol";
import {IFractionlizedNFT} from "../src/interfaces/IFractionlizedNFT.sol";

/// @title WhitelistTest
/// @notice Test suite for the Whitelist contract
contract WhitelistTest is Test {
    Whitelist public whitelist;
    address public owner;
    address public user1;
    address public user2;
    FractionlizedNFT public mockNFT;
    FractionlizedNftFactory public factory;

    /// @notice Set up the test environment before each test
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        factory = new FractionlizedNftFactory();
        whitelist = new Whitelist(address(factory));
        factory.setWhitelist(address(whitelist));
        // Deploy a mock NFT for testing purposes
        mockNFT = new FractionlizedNFT("", "", 1000, 0, 100, IFractionlizedNFT.Type.Plat, address(whitelist), 0, 500e8);
    }

    /// @notice Test whitelisting a user
    function testWhitelistUser() public {
        vm.prank(owner);
        whitelist.whitelistUser(address(mockNFT), user1, 5);
        assertEq(whitelist.getAmountMintable(address(mockNFT), user1), 5);
    }

    /// @notice Test authorizing an NFT to add to batch
    function testAuthorizeToAddToBatch() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));
        assertTrue(whitelist.isNFTAuthorized(address(mockNFT)));
    }

    /// @notice Test removing authorization from an NFT
    function testRemoveAuthorization() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));

        vm.prank(owner);
        whitelist.removeAuthorization(address(mockNFT));
        assertFalse(whitelist.isNFTAuthorized(address(mockNFT)));
    }

    /// @notice Test adding NFTs to a batch
    function testAddToBatch() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));

        vm.prank(address(mockNFT));
        whitelist.addToBatch(0, 100, user1);

        assertEq(whitelist.getUserNFTAmounts(0, user1, address(mockNFT)), 100);
    }

    /// @notice Test getting the total weight of a batch
    function testGetTotalWeightOfBatch() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));

        vm.prank(address(mockNFT));
        whitelist.addToBatch(0, 100, user1);

        assertEq(whitelist.getTotalWeightOfBatch(0), 100 * mockNFT.getWeight());
    }

    /// @notice Test that unauthorized NFTs cannot add to batch (should fail)
    function testFailAddToBatchUnauthorized() public {
        vm.prank(address(mockNFT));
        whitelist.addToBatch(0, 100, user1);
    }

    /// @notice Test that non-owners cannot remove authorization (should fail)
    function testFailRemoveAuthorizationNonOwner() public {
        vm.prank(user1);
        whitelist.removeAuthorization(address(mockNFT));
    }

    /// @notice Test that non-owners cannot whitelist users (should fail)
    function testFailWhitelistUserNonOwner() public {
        vm.prank(user1);
        whitelist.whitelistUser(address(mockNFT), user2, 5);
    }

    /// @notice Test that non-factory addresses cannot authorize NFTs (should fail)
    function testFailAuthorizeToAddToBatchNonFactory() public {
        vm.prank(user1);
        whitelist.authorizeToAddToBatch(address(mockNFT));
    }
}
