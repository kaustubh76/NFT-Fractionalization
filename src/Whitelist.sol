// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";

contract Whitelist is IWhitelist, Ownable {
    struct Batch {
        uint256 endTime;
        uint256 numOfPlat;
        uint256 numOfGold;
        uint256 numOfSilver;
        uint256 totalWeight;
        mapping(address user => mapping(address nft => uint256 amount)) userFractionsInBatch;
    }

    mapping(uint256 nodeId => Batch) internal _batches;
    mapping(address nft => bool isAuthotized) internal _authorizedNfts;

    mapping(address user => mapping(address nft => uint256 amount))
        internal _userMintableAmounts;

    address private immutable factory;

    constructor(address _factory) Ownable(msg.sender) {
        factory = _factory;
    }

    function whitelistUser(
        address _nftAddress,
        address _user,
        uint256 _amount
    ) external onlyOwner {
        _userMintableAmounts[_user][_nftAddress] = _amount;
    }

    function getAmountMintable(
        address _nft,
        address _user
    ) external view override returns (uint256) {
        return _userMintableAmounts[_user][_nft];
    }

    function authorizeToAddToBatch(address _nft) external {
        if (msg.sender != factory) {
            revert();
        }
        _authorizedNfts[_nft] = true;
    }

    function removeAuthorization(address _nft) external onlyOwner {
        _authorizedNfts[_nft] = false;
    }

    function isNFTAuthorized(address _nft) external view returns (bool) {
        return _authorizedNfts[_nft];
    }

    function addToBatch(
        uint256 _nodeId,
        uint256 _amount,
        address _user
    ) external {
        if (!_authorizedNfts[msg.sender]) {
            revert();
        }
        _batches[_nodeId].totalWeight +=
            _amount *
            IFractionlizedNFT(msg.sender).getWeight();
        _batches[_nodeId].userFractionsInBatch[_user][msg.sender] += _amount;
        IFractionlizedNFT.Type nftType = IFractionlizedNFT(msg.sender)
            .getType();
        if (nftType == IFractionlizedNFT.Type.Plat) {
            _batches[_nodeId].numOfPlat += _amount;
        } else if (nftType == IFractionlizedNFT.Type.Gold) {
            _batches[_nodeId].numOfGold += _amount;
        } else {
            _batches[_nodeId].numOfSilver += _amount;
        }
    }

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

    function getTotalWeightOfBatch(
        uint256 _nodeId
    ) external view returns (uint256) {
        return _batches[_nodeId].totalWeight;
    }

    function getUserNFTAmounts(
        uint256 nodeId,
        address user,
        address nft
    ) external view returns (uint256) {
        return _batches[nodeId].userFractionsInBatch[user][nft];
    }
}
