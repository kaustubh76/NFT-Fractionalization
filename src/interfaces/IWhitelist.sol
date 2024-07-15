// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWhitelist {
    enum NftType {
        Plat,
        Gold,
        Silver
    }

    function getAmountMintable(address _nft, address _user) external view returns (uint256);

    function authorizeToAddToBatch(address _nft) external;

    function addToBatch(uint256 _nodeId, uint256 _amount, address _user) external;

    function getTotalWeightOfBatch(uint256 _nodeId) external view returns (uint256);

    function getUserNFTAmounts(uint256 nodeId, address user, address nft) external view returns (uint256);

    function removeFromBatch(uint256 nodeNum, uint256 amount, address user) external;
}
