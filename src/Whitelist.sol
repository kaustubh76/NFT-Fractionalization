// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";

/// @title Whitelist
/// @notice This contract manages whitelisting and batching of fractionalized NFTs
contract Whitelist is IWhitelist, Ownable {
    /// @notice Struct to represent a batch of NFTs
    struct Batch {
        uint256 endTime;
        uint256 numOfPlat;
        uint256 numOfGold;
        uint256 numOfSilver;
        uint256 totalWeight;
        mapping(address user => mapping(address nft => uint256 amount)) userFractionsInBatch;
    }

    // Mapping of node IDs to batches
    mapping(uint256 nodeId => Batch) internal _batches;
    // Mapping to track authorized NFT contracts
    mapping(address nft => bool isAuthotized) internal _authorizedNfts;
    // Mapping to track mintable amounts for users and NFTs
    mapping(address user => mapping(address nft => uint256 amount)) internal _userMintableAmounts;

    // Address of the factory contract
    address private immutable factory;

    /// @notice Constructor to initialize the Whitelist contract
    /// @param _factory Address of the factory contract
    constructor(address _factory) Ownable(msg.sender) {
        factory = _factory;
    }

    /// @notice Whitelist a user for a specific NFT
    /// @param _nftAddress Address of the NFT contract
    /// @param _user Address of the user to whitelist
    /// @param _amount Amount of NFTs the user is allowed to mint
    function whitelistUser(address _nftAddress, address _user, uint256 _amount) external onlyOwner {
        _userMintableAmounts[_user][_nftAddress] = _amount;
    }

    /// @notice Get the mintable amount for a user and NFT
    /// @param _nft Address of the NFT contract
    /// @param _user Address of the user
    /// @return Amount of NFTs the user can mint
    function getAmountMintable(address _nft, address _user) external view override returns (uint256) {
        return _userMintableAmounts[_user][_nft];
    }

    /// @notice Authorize an NFT contract to add to batches
    /// @param _nft Address of the NFT contract to authorize
    function authorizeToAddToBatch(address _nft) external {
        if (msg.sender != factory) {
            revert();
        }
        _authorizedNfts[_nft] = true;
    }

    /// @notice Remove authorization from an NFT contract
    /// @param _nft Address of the NFT contract to deauthorize
    function removeAuthorization(address _nft) external onlyOwner {
        _authorizedNfts[_nft] = false;
    }

    /// @notice Check if an NFT contract is authorized
    /// @param _nft Address of the NFT contract to check
    /// @return Boolean indicating if the NFT is authorized
    function isNFTAuthorized(address _nft) external view returns (bool) {
        return _authorizedNfts[_nft];
    }

    /// @notice Add NFTs to a batch
    /// @param _nodeId ID of the node (batch)
    /// @param _amount Amount of NFTs to add
    /// @param _user Address of the user adding NFTs
    function addToBatch(uint256 _nodeId, uint256 _amount, address _user) external {
        if (!_authorizedNfts[msg.sender]) {
            revert();
        }
        _batches[_nodeId].totalWeight += _amount * IFractionlizedNFT(msg.sender).getWeight();
        _batches[_nodeId].userFractionsInBatch[_user][msg.sender] += _amount;
        IFractionlizedNFT.Type nftType = IFractionlizedNFT(msg.sender).getType();
        if (nftType == IFractionlizedNFT.Type.Plat) {
            _batches[_nodeId].numOfPlat += _amount;
        } else if (nftType == IFractionlizedNFT.Type.Gold) {
            _batches[_nodeId].numOfGold += _amount;
        } else {
            _batches[_nodeId].numOfSilver += _amount;
        }
    }

    /// @notice Remove NFTs from a batch
    /// @param nodeNum ID of the node (batch)
    /// @param amount Amount of NFTs to remove
    /// @param user Address of the user removing NFTs
    function removeFromBatch(uint256 nodeNum, uint256 amount, address user) external {
        if (!_authorizedNfts[msg.sender]) {
            revert();
        }
        _batches[nodeNum].totalWeight -= amount * IFractionlizedNFT(msg.sender).getWeight();
        _batches[nodeNum].userFractionsInBatch[user][msg.sender] -= amount;
        IFractionlizedNFT.Type nftType = IFractionlizedNFT(msg.sender).getType();
        if (nftType == IFractionlizedNFT.Type.Plat) {
            _batches[nodeNum].numOfPlat -= amount;
        } else if (nftType == IFractionlizedNFT.Type.Gold) {
            _batches[nodeNum].numOfGold -= amount;
        } else {
            _batches[nodeNum].numOfSilver -= amount;
        }
    }

    /// @notice Get the total weight of a batch
    /// @param _nodeId ID of the node (batch)
    /// @return Total weight of the batch
    function getTotalWeightOfBatch(uint256 _nodeId) external view returns (uint256) {
        return _batches[_nodeId].totalWeight;
    }

    /// @notice Get the amount of NFTs a user has in a specific batch
    /// @param nodeId ID of the node (batch)
    /// @param user Address of the user
    /// @param nft Address of the NFT contract
    /// @return Amount of NFTs the user has in the batch
    function getUserNFTAmounts(uint256 nodeId, address user, address nft) external view returns (uint256) {
        return _batches[nodeId].userFractionsInBatch[user][nft];
    }
}a