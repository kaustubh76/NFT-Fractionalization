// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {FractionlizedNftFactory} from "../src/FractionlizedNftFactory.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {FractionlizedNFT} from "../src/FractionlizedNFT.sol";

contract FractionalizedNFTFactoryTest is Test {
    FractionlizedNftFactory public factory;
    Whitelist public whitelist;

    address public owner;

    function setUp() public {
        owner = address(this);
        
        factory = new FractionlizedNftFactory();
        whitelist = new Whitelist(address(factory));
        factory.setWhitelist(address(whitelist));
    }

    function testDeployNewFractionalizedNFT() public {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 1 days;
        FractionlizedNftFactory.DeployNFTParams memory params = FractionlizedNftFactory.DeployNFTParams({
            name: "TestNFT",
            symbol: "TNFT",
            weight: 100,
            startTime: startTime,
            endTime: endTime,
            nftType: IFractionlizedNFT.Type.Plat
        });
        
        IFractionlizedNFT nft = factory.deployNewFractionalizedNFT(params);

        assertEq(uint(nft.getType()), uint(IFractionlizedNFT.Type.Plat));
        assertEq(nft.getWeight(), 100);
        assertEq(nft.getStartTime(), startTime);
        assertEq(nft.getEndTime(), endTime);
        assertTrue(whitelist.isNFTAuthorized(address(nft)));
    }

    function testSetWhitelist() public {
        address newWhitelist = address(0x123);
        factory.setWhitelist(newWhitelist);
        assertEq(factory.getWhitelist(), newWhitelist);
    }

    function testFailDeployNewFractionalizedNFTNonOwner() public {
        vm.prank(address(0x456));
        FractionlizedNftFactory.DeployNFTParams memory params = FractionlizedNftFactory.DeployNFTParams({
            name: "TestNFT",
            symbol: "TNFT",
            weight: 100,
            startTime: block.timestamp,
            endTime: block.timestamp + 1 days,
            nftType: IFractionlizedNFT.Type.Plat
        });

        factory.deployNewFractionalizedNFT(params);
    }

    function testFailSetWhitelistNonOwner() public {
        vm.prank(address(0x456));
        factory.setWhitelist(address(0x789));
    }

    function testDeployMultipleFractionalizedNFTs() public {
        for (uint i = 0; i < 3; i++) {
            FractionlizedNftFactory.DeployNFTParams memory params = FractionlizedNftFactory.DeployNFTParams({
                name: string(abi.encodePacked("TestNFT", i)),
                symbol: string(abi.encodePacked("TNFT", i)),
                weight: 100 * (i + 1),
                startTime: block.timestamp,
                endTime: block.timestamp + 1 days,
                nftType: IFractionlizedNFT.Type(i % 3)
            });
            IFractionlizedNFT nft = factory.deployNewFractionalizedNFT(params);
            
            assertEq(nft.getWeight(), 100 * (i + 1));
            assertEq(uint(nft.getType()), i % 3);
            assertTrue(whitelist.isNFTAuthorized(address(nft)));
        }
    }
}