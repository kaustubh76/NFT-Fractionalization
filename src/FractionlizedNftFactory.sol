// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Import necessary contracts and interfaces
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FractionlizedNFT} from "./FractionlizedNFT.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";

/// @title FractionlizedNftFactory
/// @notice This contract is responsible for deploying new FractionlizedNFT contracts
contract FractionlizedNftFactory is Ownable {
    // Initialize the contract with the deployer as the owner
    constructor() Ownable(msg.sender) {}

    // Address of the whitelist contract
    address private whitelist;
    // Counter for node numbers
    uint256 private nodeNum;

    /// @notice Struct to hold parameters for deploying a new FractionlizedNFT
    struct DeployNFTParams {
        string name;
        string symbol;
        uint256 weight;
        uint256 startTime;
        uint256 endTime;
        IFractionlizedNFT.Type nftType;
        uint256 nodePrice;
    }

    /// @notice Deploy a new FractionlizedNFT contract
    /// @param params Struct containing all necessary parameters for the new NFT
    /// @return _nft The address of the newly deployed FractionlizedNFT contract
    function deployNewFractionalizedNFT(DeployNFTParams calldata params)
        external
        onlyOwner
        returns (IFractionlizedNFT _nft)
    {
        // Deploy a new FractionlizedNFT contract with the provided parameters
        FractionlizedNFT nft = new FractionlizedNFT(
            params.name,
            params.symbol,
            params.weight,
            params.startTime,
            params.endTime,
            params.nftType,
            whitelist,
            nodeNum++,
            params.nodePrice
        );
        // Authorize the new NFT contract to add to batch in the whitelist
        IWhitelist(whitelist).authorizeToAddToBatch(address(nft));
        return nft;
    }

    /// @notice Set the address of the whitelist contract
    /// @param _whitelist The address of the new whitelist contract
    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    /// @notice Get the address of the current whitelist contract
    /// @return The address of the whitelist contract
    function getWhitelist() external view returns (address) {
        return whitelist;
    }
}