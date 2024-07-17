// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {IFractionlizedNFT} from "./interfaces/IFractionlizedNFT.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Fractionalized NFT Contract
/// @notice Implements a fractionalized NFT system with minting, burning, and refund capabilities
contract FractionlizedNFT is IFractionlizedNFT, ERC721Enumerable, Ownable, ReentrancyGuard {
    // Immutable state variables
    uint256 private immutable weight;
    uint256 private immutable startTime;
    uint256 private immutable endTime;
    uint256 private immutable nodeNum;
    Type private immutable nftType;
    IWhitelist private immutable whitelist;
    uint256 private immutable NODE_PRICE;

    // Price feed for ETH/USD conversion
    AggregatorV3Interface private priceFeed;

    // Constants
    uint256 private constant FEE = 20e6; // $0.20
    uint256 private constant MAX_WEIGHT = 10000;
    uint256 private constant PRECISION = 1e18;

    // Custom errors
    error NotInSalePeriod();
    error InsufficientMintableAmount();

    // Mapping to store user's token IDs
    mapping(address user => uint256[] tokenIds) private _userTokens;

    /// @notice Constructor to initialize the FractionlizedNFT contract
    /// @param name The name of the NFT
    /// @param symbol The symbol of the NFT
    /// @param _weight The weight of each NFT
    /// @param _startTime The start time of the sale period
    /// @param _endTime The end time of the sale period
    /// @param _nftType The type of the NFT
    /// @param _whitelist The address of the whitelist contract
    /// @param _nodeNum The node number
    /// @param _nodePrice The price of each node
    constructor(
        string memory name,
        string memory symbol,
        uint256 _weight,
        uint256 _startTime,
        uint256 _endTime,
        Type _nftType,
        address _whitelist,
        uint256 _nodeNum,
        uint256 _nodePrice
    ) ERC721Enumerable() ERC721(name, symbol) Ownable(tx.origin) {
        weight = _weight;
        startTime = _startTime;
        endTime = _endTime;
        nftType = _nftType;
        whitelist = IWhitelist(_whitelist);
        nodeNum = _nodeNum;
        NODE_PRICE = _nodePrice;
    }

    /// @notice Sets the price feed contract address
    /// @param _priceFeed The address of the price feed contract
    function setPriceFeeds(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice Mints new NFTs
    /// @param _amount The number of NFTs to mint
    function mint(uint256 _amount) external payable nonReentrant {
        if (block.timestamp < startTime || block.timestamp >= endTime) {
            revert NotInSalePeriod();
        }
        if (whitelist.getAmountMintable(address(this), msg.sender) < _amount) {
            revert InsufficientMintableAmount();
        }
        (, int256 ethPrice,,,) = priceFeed.latestRoundData();
        uint256 feeInEth = (_amount * FEE * PRECISION) / uint256(ethPrice);
        if (msg.value < feeInEth) {
            revert();
        }
        for (uint256 i; i < _amount; ++i) {
            _userTokens[msg.sender].push(totalSupply());
            _safeMint(msg.sender, totalSupply());
        }
        if (whitelist.getTotalWeightOfBatch(nodeNum) + _amount * weight > MAX_WEIGHT) {
            revert();
        }
        whitelist.addToBatch(nodeNum, _amount, msg.sender);
    }

    /// @notice Returns the current timestamp
    /// @return The current block timestamp
    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the type of the NFT
    /// @return The NFT type
    function getType() external view returns (Type) {
        return nftType;
    }

    /// @notice Burns a specific token
    /// @param _tokenId The ID of the token to burn
    function burn(uint256 _tokenId) external onlyOwner {
        if (block.timestamp < endTime) {
            revert();
        }
        _burn(_tokenId);
    }

    /// @notice Refunds unsold NFTs
    function refundUnsold() external nonReentrant {
        if (block.timestamp < endTime) {
            revert();
        }
        if (whitelist.getTotalWeightOfBatch(nodeNum) == MAX_WEIGHT) {
            revert();
        }
        (, int256 ethPrice,,,) = priceFeed.latestRoundData();
        uint256 amountOfNfts = whitelist.getUserNFTAmounts(nodeNum, msg.sender, address(this));
        uint256 amountToRefund = (amountOfNfts * weight * NODE_PRICE * PRECISION) / (MAX_WEIGHT * uint256(ethPrice))
            + ((amountOfNfts * FEE * PRECISION) / uint256(ethPrice));

        uint256[] memory userTokens = _userTokens[msg.sender];
        uint256 length = userTokens.length;
        for (uint256 i; i < length; ++i) {
            _burn(userTokens[i]);
        }
        delete _userTokens[msg.sender];
        whitelist.removeFromBatch(nodeNum, amountOfNfts, msg.sender);

        (bool ok,) = payable(msg.sender).call{value: amountToRefund}("");
        if (!ok) {
            revert();
        }
    }

    /// @notice Returns the weight of each NFT
    /// @return The weight value
    function getWeight() external view returns (uint256) {
        return weight;
    }

    /// @notice Returns the start time of the sale period
    /// @return The start time
    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    /// @notice Returns the end time of the sale period
    /// @return The end time
    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    /// @notice Withdraws the contract's balance to the owner
    function withdraw() external onlyOwner {
        (bool ok,) = payable(owner()).call{value: address(this).balance}("");
        if (!ok) {
            revert();
        }
    }

    /// @notice Allows the contract to receive Ether
    receive() external payable {}
}
