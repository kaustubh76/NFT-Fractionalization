// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FractionlizedNFT is
    IFractionlizedNFT,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    uint256 private immutable weight;
    uint256 private immutable startTime;
    uint256 private immutable endTime;
    uint256 private immutable nodeNum;
    Type private immutable nftType;
    AggregatorV3Interface private priceFeed;

    IWhitelist private immutable whitelist;

    uint256 private constant FEE = 20e6; // $0.20
    uint256 private constant MAX_WEIGHT = 10000;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant NODE_PRICE = 500e8;

    error NotInSalePeriod();
    error InsufficientMintableAmount();

    mapping(address user => uint256[] tokenIds) private _userTokens;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _weight,
        uint256 _startTime,
        uint256 _endTime,
        Type _nftType,
        address _whitelist,
        uint256 _nodeNum
    ) ERC721Enumerable() ERC721(name, symbol) Ownable(msg.sender) {
        weight = _weight;
        startTime = _startTime;
        endTime = _endTime;
        nftType = _nftType;
        whitelist = IWhitelist(_whitelist);
        nodeNum = _nodeNum;
    }

    function setPriceFeeds(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function mint(uint256 _amount) external payable nonReentrant {
        if (block.timestamp < startTime || block.timestamp >= endTime) {
            revert NotInSalePeriod();
        }
        if (whitelist.getAmountMintable(address(this), msg.sender) < _amount) {
            revert InsufficientMintableAmount();
        }
        (, int256 ethPrice, , , ) = priceFeed.latestRoundData();
        uint256 feeInEth = (_amount * FEE * PRECISION) / uint256(ethPrice);
        if (msg.value < feeInEth) {
            revert();
        }
        for (uint256 i; i < _amount; ++i) {
            _userTokens[msg.sender].push(totalSupply());
            _safeMint(msg.sender, totalSupply());
        }
        if (
            whitelist.getTotalWeightOfBatch(nodeNum) + _amount * weight >
            MAX_WEIGHT
        ) {
            revert();
        }
        whitelist.addToBatch(nodeNum, _amount, msg.sender);
    }

    function getType() external view returns (Type) {
        return nftType;
    }

    function burn(uint256 _tokenId) external onlyOwner {
        if (block.timestamp < endTime) {
            revert();
        }
        _burn(_tokenId);
    }

    function refundUnsold() external nonReentrant {
        if (block.timestamp < endTime) {
            revert();
        }
        if (whitelist.getTotalWeightOfBatch(nodeNum) == MAX_WEIGHT) {
            revert();
        }
        (, int256 ethPrice, , , ) = priceFeed.latestRoundData();
        uint256 amountOfNfts = whitelist.getUserNFTAmounts(
            nodeNum,
            msg.sender,
            address(this)
        );
        uint256 amountToRefund = (amountOfNfts *
            weight *
            NODE_PRICE *
            PRECISION) /
            (MAX_WEIGHT * uint256(ethPrice)) +
            ((amountOfNfts * FEE * PRECISION) / uint256(ethPrice));

        uint256[] memory userTokens = _userTokens[msg.sender];
        uint256 length = userTokens.length;
        for (uint i; i < length; ++i) {
            _burn(userTokens[i]);
        }
        delete _userTokens[msg.sender];
        whitelist.removeFromBatch(nodeNum, amountOfNfts, msg.sender);

        (bool ok, ) = payable(msg.sender).call{value: amountToRefund}("");
        if (!ok) {
            revert();
        }
    }

    function getWeight() external view returns (uint256) {
        return weight;
    }

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    function withdraw() external onlyOwner {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        if (!ok) {
            revert();
        }
    }

    receive() external payable {}
}
