// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/FractionlizedNftFactory.sol";
import "../src/Whitelist.sol";
import "../src/FractionlizedNFT.sol";

/// @title FractionalizedNFTFactoryTest
/// @notice Test suite for the FractionlizedNftFactory contract
contract FractionalizedNFTFactoryTest is Test {
    FractionlizedNftFactory public factory;
    Whitelist public whitelist;

    address public owner;

    /// @notice Set up the test environment before each test
    function setUp() public {
        owner = address(this);

        // Deploy the factory and whitelist contracts
        factory = new FractionlizedNftFactory();
        whitelist = new Whitelist(address(factory));
        factory.setWhitelist(address(whitelist));
    }

    /// @notice Test deploying a new FractionlizedNFT
    function testDeployNewFractionalizedNFT() public {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 1 days;
        // Create deployment parameters
        FractionlizedNftFactory.DeployNFTParams memory params = FractionlizedNftFactory.DeployNFTParams({
            name: "TestNFT",
            symbol: "TNFT",
            weight: 100,
            startTime: startTime,
            endTime: endTime,
            nftType: IFractionlizedNFT.Type.Plat,
            nodePrice: 500e8
        });

        // Deploy the NFT
        IFractionlizedNFT nft = factory.deployNewFractionalizedNFT(params);

        // Assert the NFT properties are set correctly
        assertEq(uint256(nft.getType()), uint256(IFractionlizedNFT.Type.Plat));
        assertEq(nft.getWeight(), 100);
        assertEq(nft.getStartTime(), startTime);
        assertEq(nft.getEndTime(), endTime);
        assertTrue(whitelist.isNFTAuthorized(address(nft)));
    }

    /// @notice Test setting a new whitelist address
    function testSetWhitelist() public {
        address newWhitelist = address(0x123);
        factory.setWhitelist(newWhitelist);
        assertEq(factory.getWhitelist(), newWhitelist);
    }

    /// @notice Test that non-owners cannot deploy new NFTs
    function testFailDeployNewFractionalizedNFTNonOwner() public {
        vm.prank(address(0x456)); // Set msg.sender to a non-owner address
        FractionlizedNftFactory.DeployNFTParams memory params = FractionlizedNftFactory.DeployNFTParams({
            name: "TestNFT",
            symbol: "TNFT",
            weight: 100,
            startTime: block.timestamp,
            endTime: block.timestamp + 1 days,
            nftType: IFractionlizedNFT.Type.Plat,
            nodePrice: 500e8
        });

        // This should fail as the caller is not the owner
        factory.deployNewFractionalizedNFT(params);
    }

    /// @notice Test that non-owners cannot set the whitelist
    function testFailSetWhitelistNonOwner() public {
        vm.prank(address(0x456)); // Set msg.sender to a non-owner address
        // This should fail as the caller is not the owner
        factory.setWhitelist(address(0x789));
    }

    /// @notice Test deploying multiple FractionlizedNFTs
    function testDeployMultipleFractionalizedNFTs() public {
        for (uint256 i = 0; i < 3; i++) {
            // Create unique parameters for each NFT
            FractionlizedNftFactory.DeployNFTParams memory params = FractionlizedNftFactory.DeployNFTParams({
                name: string(abi.encodePacked("TestNFT", i)),
                symbol: string(abi.encodePacked("TNFT", i)),
                weight: 100 * (i + 1),
                startTime: block.timestamp,
                endTime: block.timestamp + 1 days,
                nftType: IFractionlizedNFT.Type(i % 3),
                nodePrice: 500e8
            });
            IFractionlizedNFT nft = factory.deployNewFractionalizedNFT(params);

            // Assert the NFT properties are set correctly
            assertEq(nft.getWeight(), 100 * (i + 1));
            assertEq(uint256(nft.getType()), i % 3);
            assertTrue(whitelist.isNFTAuthorized(address(nft)));
        }
    }
}
