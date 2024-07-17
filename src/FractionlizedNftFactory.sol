// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FractionlizedNFT} from "./FractionlizedNFT.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";

/// @title Fractionalized NFT Factory
/// @notice This contract is responsible for deploying new FractionlizedNFT contracts
contract FractionlizedNftFactory is Ownable {
    constructor() Ownable(msg.sender) {}

    // Address of the whitelist contract
    address private whitelist;

    // Node numbers for each NFT type
    uint256 private nodeNumPlat;
    uint256 private nodeNumGold;
    uint256 private nodeNumSilver;

    /// @notice Struct to hold parameters for deploying a new NFT
    struct DeployNFTParams {
        string name;
        string symbol;
        uint256 weight;
        uint256 startTime;
        uint256 endTime;
        IFractionlizedNFT.Type nftType;
        uint256 nodePrice;
    }

    /// @notice Deploys a new FractionlizedNFT contract
    /// @param params The parameters for the new NFT
    /// @return _nft The address of the newly deployed NFT contract
    function deployNewFractionalizedNFT(DeployNFTParams calldata params)
        external
        onlyOwner
        returns (FractionlizedNFT _nft)
    {
        uint256 nodeNum;
        // Determine the node number based on the NFT type
        if (params.nftType == IFractionlizedNFT.Type.Plat) {
            nodeNum = nodeNumPlat++;
        } else if (params.nftType == IFractionlizedNFT.Type.Gold) {
            nodeNum = nodeNumGold++;
        } else {
            nodeNum = nodeNumSilver++;
        }

        // Deploy the new FractionlizedNFT contract
        FractionlizedNFT nft = new FractionlizedNFT(
            params.name,
            params.symbol,
            params.weight,
            params.startTime,
            params.endTime,
            params.nftType,
            whitelist,
            nodeNum,
            params.nodePrice
        );

        // Authorize the new NFT contract to add to batch in the whitelist
        IWhitelist(whitelist).authorizeToAddToBatch(address(nft));
        return nft;
    }

    /// @notice Sets the address of the whitelist contract
    /// @param _whitelist The address of the whitelist contract
    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    /// @notice Gets the address of the whitelist contract
    /// @return The address of the whitelist contract
    function getWhitelist() external view returns (address) {
        return whitelist;
    }
}
