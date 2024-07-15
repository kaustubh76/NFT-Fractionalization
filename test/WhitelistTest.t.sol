// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {FractionlizedNftFactory} from "../src/FractionlizedNftFactory.sol";
import {FractionlizedNFT} from "../src/FractionlizedNFT.sol";
import {IFractionlizedNFT} from "../src/interfaces/IFractionlizedNFT.sol";

contract WhitelistTest is Test {
    Whitelist public whitelist;
    address public owner;
    address public user1;
    address public user2;
    FractionlizedNFT public mockNFT;
    FractionlizedNftFactory public factory;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        factory = new FractionlizedNftFactory();
        whitelist = new Whitelist(address(factory));
        factory.setWhitelist(address(whitelist));
        mockNFT = new FractionlizedNFT(
            "",
            "",
            1000,
            0,
            100,
            IFractionlizedNFT.Type.Plat,
            address(whitelist),
            0,
            500e8
        );
    }

    function testWhitelistUser() public {
        vm.prank(owner);
        whitelist.whitelistUser(address(mockNFT), user1, 5);
        assertEq(whitelist.getAmountMintable(address(mockNFT), user1), 5);
    }

    function testAuthorizeToAddToBatch() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));
        assertTrue(whitelist.isNFTAuthorized(address(mockNFT)));
    }

    function testRemoveAuthorization() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));

        vm.prank(owner);
        whitelist.removeAuthorization(address(mockNFT));
        assertFalse(whitelist.isNFTAuthorized(address(mockNFT)));
    }

    function testAddToBatch() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));

        vm.prank(address(mockNFT));
        whitelist.addToBatch(0, 100, user1);

        assertEq(whitelist.getUserNFTAmounts(0, user1, address(mockNFT)), 100);
    }

    function testGetTotalWeightOfBatch() public {
        vm.prank(address(factory));
        whitelist.authorizeToAddToBatch(address(mockNFT));

        vm.prank(address(mockNFT));
        whitelist.addToBatch(0, 100, user1);

        assertEq(whitelist.getTotalWeightOfBatch(0), 100 * mockNFT.getWeight());
    }

    function testFailAddToBatchUnauthorized() public {
        vm.prank(address(mockNFT));
        whitelist.addToBatch(0, 100, user1);
    }

    function testFailRemoveAuthorizationNonOwner() public {
        vm.prank(user1);
        whitelist.removeAuthorization(address(mockNFT));
    }

    function testFailWhitelistUserNonOwner() public {
        vm.prank(user1);
        whitelist.whitelistUser(address(mockNFT), user2, 5);
    }

    function testFailAuthorizeToAddToBatchNonFactory() public {
        vm.prank(user1);
        whitelist.authorizeToAddToBatch(address(mockNFT));
    }
}
