// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Whitelist} from "../src/Whitelist.sol";
import {FractionlizedNFT} from "../src/FractionlizedNFT.sol";
import {MockV3Aggregator} from "@chainlink/contracts/tests/MockV3Aggregator.sol";
import {FractionlizedNftFactory} from "../src/FractionlizedNftFactory.sol";
import {IFractionlizedNFT} from "../src/interfaces/IFractionlizedNFT.sol";
import {console} from "forge-std/console.sol";

/// @title Deploy Fractionalized NFT Script
/// @notice This script deploys the Fractionalized NFT ecosystem contracts
contract DeployFractionalizedNFT is Script {
    function run() external {
        // Retrieve the deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(deployerPrivateKey);
        console.log("address of deployer: ", account);

        // Start the broadcast to record and broadcast transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockV3Aggregator as a price feed with 8 decimals and initial price of $4000
        MockV3Aggregator priceFeed = new MockV3Aggregator(8, 4000e8);

        // Deploy the FractionlizedNftFactory
        FractionlizedNftFactory factory = new FractionlizedNftFactory();

        // Deploy the Whitelist contract and link it to the factory
        Whitelist whitelist = new Whitelist(address(factory));
        factory.setWhitelist(address(whitelist));

        console.log("address of factory: ", address(factory));
        console.log("address of whitelist: ", address(whitelist));

        // Set up deployment parameters for Platinum NFT
        FractionlizedNftFactory.DeployNFTParams memory paramsPlat = FractionlizedNftFactory.DeployNFTParams({
            name: "Platinum",
            symbol: "PLT",
            weight: 1000,
            startTime: block.timestamp,
            endTime: block.timestamp + 500,
            nftType: IFractionlizedNFT.Type.Plat,
            nodePrice: 500e8
        });

        // Set up deployment parameters for Gold NFT
        FractionlizedNftFactory.DeployNFTParams memory paramsGold = FractionlizedNftFactory.DeployNFTParams({
            name: "Gold",
            symbol: "GLD",
            weight: 500,
            startTime: block.timestamp,
            endTime: block.timestamp + 10000,
            nftType: IFractionlizedNFT.Type.Gold,
            nodePrice: 500e8
        });

        // Set up deployment parameters for Silver NFT
        FractionlizedNftFactory.DeployNFTParams memory paramsSilver = FractionlizedNftFactory.DeployNFTParams({
            name: "Silver",
            symbol: "SLV",
            weight: 333,
            startTime: block.timestamp,
            endTime: block.timestamp + 10000,
            nftType: IFractionlizedNFT.Type.Silver,
            nodePrice: 500e8
        });

        // Deploy Platinum, Gold, and Silver NFTs using the factory
        FractionlizedNFT plat = factory.deployNewFractionalizedNFT(paramsPlat);
        FractionlizedNFT gold = factory.deployNewFractionalizedNFT(paramsGold);
        FractionlizedNFT silver = factory.deployNewFractionalizedNFT(paramsSilver);

        // Set the price feed for each NFT
        plat.setPriceFeeds(address(priceFeed));
        gold.setPriceFeeds(address(priceFeed));
        silver.setPriceFeeds(address(priceFeed));

        // Log the addresses of the deployed NFTs
        console.log("address of plat: ", address(plat));
        console.log("address of gold: ", address(gold));
        console.log("address of silver: ", address(silver));

        // End the broadcast
        vm.stopBroadcast();
    }
}
