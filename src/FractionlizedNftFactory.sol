// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FractionlizedNFT} from "./FractionlizedNFT.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";

contract FractionlizedNftFactory is Ownable {
    constructor() Ownable(msg.sender) {}

    address private whitelist;
    uint256 private nodeNum;

    struct DeployNFTParams {
        string name;
        string symbol;
        uint256 weight;
        uint256 startTime;
        uint256 endTime;
        IFractionlizedNFT.Type nftType;
        uint256 nodePrice;
    }

    function deployNewFractionalizedNFT(
        DeployNFTParams calldata params
    ) external onlyOwner returns (IFractionlizedNFT _nft) {
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
        IWhitelist(whitelist).authorizeToAddToBatch(address(nft));
        return nft;
    }

    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    function getWhitelist() external view returns (address) {
        return whitelist;
    }
}
