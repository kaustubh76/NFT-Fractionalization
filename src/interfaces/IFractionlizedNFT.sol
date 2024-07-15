// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFractionlizedNFT is IERC721 {
    enum Type {
        Plat,
        Gold,
        Silver
    }
    function getWeight() external view returns (uint256);
    function getType() external view returns (Type);
    function setPriceFeeds(address _priceFeed) external;
    function mint(uint256 _amount) external payable;
    function burn(uint256 _tokenId) external;
    function refundUnsold() external;
    function getStartTime() external view returns (uint256);
    function getEndTime() external view returns (uint256);
    function withdraw() external;
}
